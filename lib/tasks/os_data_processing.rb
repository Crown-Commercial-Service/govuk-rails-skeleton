# rubocop:disable Metrics/ModuleLength, Rails/Output
module OrdnanceSurvey
  def self.upsert_csv_data(csv_stream)
    fully_processed = true
    csv_headers     = os_address_headers.downcase.split(',').map(&:to_sym)
    SmarterCSV.process(csv_stream, user_provided_headers: csv_headers, headers_in_file: true, chunk_size: 1000, remove_blank_values: false) do |chunk|
      ActiveRecord::Base.connection_pool.with_connection do |db|
        db.begin_db_transaction
        chunk.each do |row|
          upsert_row(db, row)
        end
        db.commit_db_transaction
      rescue StandardError => e
        db.rollback_db_transaction
        puts "\tError with upsert: #{e.message}"
        Rails.logger.error((["POSTCODE: #{e.message}"] + e.backtrace).join($INPUT_RECORD_SEPARATOR))
        fully_processed = false
        raise e
      end
    end
    fully_processed
  end

  INSERT_COLUMNS  = %i[uprn udprn class parent_uprn last_update_date rm_organisation_name sub_building_name building_name building_number
                       sao_start_number sao_start_suffix sao_end_number sao_end_suffix sao_text
                       pao_start_number pao_start_suffix pao_end_number pao_end_suffix pao_text street_description dependent_thoroughfare
                       thoroughfare dependent_locality locality town_name administrative_area post_town postcode postcode_locator po_box_number ward_code].freeze
  INTEGER_COLUMNS = %i[uprn udprn parent_uprn sao_start_number sao_end_number pao_start_number pao_end_number].freeze

  def self.upsert_row(db, row)
    new_date = DateTime.parse(row[:last_update_date]).utc
    result   = db.exec_query(os_address_select(row))
    db_date  = result.empty? ? new_date : DateTime.parse(result[0]['last_update_date']).utc
    db.execute(os_address_delete(row)) if db_date < new_date || result.length > 1
    db.execute(os_address_insert(row)) if result.empty? || new_date > db_date || result.length > 1
  end

  def self.os_address_select(row)
    "select last_update_date from os_address where postcode_locator = '#{row[:postcode_locator]}' and uprn = #{row[:uprn]} order by last_update_date desc"
  end

  def self.os_address_delete(row)
    "delete from os_address where postcode_locator = '#{row[:postcode_locator]}' and uprn = #{row[:uprn]}"
  end

  def self.os_address_insert(row)
    "insert into os_address (#{INSERT_COLUMNS.map(&:to_s).join(',')}) values (#{INSERT_COLUMNS.map { |c| db_value(row, c) }.join(',')})"
  end

  def self.db_value(row, col)
    return 'null' if row[col].nil?

    return "'#{row[col].to_s.gsub("'", "''")}'" unless INTEGER_COLUMNS.include?(col)

    row[col].to_s
  rescue StandardError => e
    puts ["dbValue Error processing column [:#{col}] in #{row}: #{e.message}"] + e.backtrace.join($INPUT_RECORD_SEPARATOR)
  end

  def self.inject_data(lines)
    unless lines.nil?
      ActiveRecord::Base.connection_pool.with_connection do |conn|
        rc = conn.raw_connection
        rc.exec('COPY os_address FROM STDIN WITH CSV')
        rc.put_copy_data lines
        rc.put_copy_end
      end
    end
  rescue StandardError => e
    Rails.logger.error e.message
  end

  def self.purge_excluded_areas
    query = %{DELETE
              FROM os_address oa
              WHERE postcode_locator IN
              (#{EXCLUDED_POSTCODE_AREAS.map { |e| "SELECT oa.postcode_locator FROM os_address oa WHERE postcode_locator LIKE '#{e}%'" }.join(' UNION ')});}
    ActiveRecord::Base.connection_pool.with_connection do |db|
      db.execute(query)
    end
    ActiveRecord::Base.connection_pool.with_connection do |db|
      db.execute('vacuum os_address;')
    end
  rescue StandardError => e
    puts "\tError with purge_excluded_areas: #{e.message}"
    Rails.logger.error((["POSTCODE purge_excluded_areas: #{e.message}"] + e.backtrace).join($INPUT_RECORD_SEPARATOR))
    raise e
  end

  def self.truncate_os_addresses
    ActiveRecord::Base.connection_pool.with_connection do |db|
      db.execute('truncate table os_address;')
      db.execute('truncate table os_address_admin_uploads;')
    end
    ActiveRecord::Base.connection_pool.with_connection do |db|
      db.execute('vacuum os_address;')
    end
  rescue StandardError => e
    puts "\tError with truncate: #{e.message}"
    Rails.logger.error((["POSTCODE truncate: #{e.message}"] + e.backtrace).join($INPUT_RECORD_SEPARATOR))
    raise e
  end

  CHUNK_SIZE = 100000
  # rubocop:disable Metrics/CyclomaticComplexity
  def self.chunk_file_data(io, meta_type, &block)
    counter = 0
    chunk   = ''
    md5     = Digest::MD5.new
    io.each do |line|
      (counter = 0) and (chunk = '') if counter == CHUNK_SIZE
      chunk << line
      counter += 1
      md5 << chunk if counter == CHUNK_SIZE
      block.call(meta_type, StringIO.new(chunk)) and next if counter == CHUNK_SIZE
    end
    block.call(meta_type, StringIO.new(chunk)) unless chunk.empty?
    md5.to_s
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def self.process_csv_data(type, csv_stream)
    return inject_data(csv_stream.read) if type == :dat

    upsert_csv_data(csv_stream) unless type == :dat
  end

  def self.handle_tar_contents(tar, summary, &block)
    tar.each do |entry|
      next unless entry.file?

      summary[:length] = entry.size
      file_stream      = StringIO.new(entry.read)
      header_line      = file_stream.readline
      (meta_type = (
      if header_line.downcase.include?('uprn')
        :csv
      else
        :dat
      end)) and file_stream.rewind
      summary[:md5] = chunk_file_data(file_stream, meta_type, &block)
    end
  end

  def self.handle_gzip_contents(gzip, summary, &)
    header_line = gzip.readline
    (meta_type = (
    if header_line.downcase.include?('uprn')
      :csv
    else
      :dat
    end)) and gzip.rewind
    summary[:md5]    = chunk_file_data(gzip, meta_type, &)
    summary[:length] = gzip.pos
  end

  def self.handle_zip_contents(io, summary, &)
    while (entry = io.get_next_entry)
      next if entry.name_is_directory?

      header_line = io.readline
      (meta_type = (
      if header_line.downcase.include?('uprn')
        :csv
      else
        :dat
      end)) and io.rewind
      summary[:length] = entry.size
      summary[:md5]    = chunk_file_data(io, meta_type, &)
    end
  end

  # rubocop:disable Lint/MixedRegexpCaptureTypes
  MATCH_1 = /dataPostcode_(?<meta>(?<date>\d*-\d*-\d*)_(?<seq>\d*)_(?<outcode>\w{1,2}))/
  MATCH_2 = /AddressBasePlus_.*?_(?<meta>(?<date>\d*-\d*-\d*)_(?<seq>\d*)((?>.csv-)(?<outcode>\w{1,2}))?)/
  # rubocop:enable Lint/MixedRegexpCaptureTypes

  def self.extract_metadata(filename, outcode = nil)
    [MATCH_1, MATCH_2].each do |m|
      match_data = filename.match(m)
      next if match_data.nil?

      result = "#{match_data[:date]}_#{match_data[:seq]}"
      result += "_#{match_data[:outcode].upcase}" unless match_data[:outcode].nil?
      outcode << match_data[:outcode] unless match_data[:outcode].nil? || outcode.nil?

      return result
    end

    filename
  end

  def self.postcode_file_already_loaded(filename)
    meta_data = extract_metadata(filename)
    query = "select count(*) from os_address_admin_uploads where fail_reason is null and (filename = '#{filename}' or filename = '#{meta_data}')"
    loaded = false

    ActiveRecord::Base.connection_pool.with_connection do |db|
      result = db.exec_query(query)
      count  = result[0]['count']
      puts "Skipping file #{filename}" if count.positive?
      loaded = true if count.positive?
    end

    loaded
  rescue PG::Error => e
    puts e.message
    false
  end

  def self.log_postcode_file_failed(filename, reason)
    metadata = extract_metadata(filename)
    reason   = reason.sub('`', '').sub('\'', '').sub('/', '/')
    query    = "INSERT INTO os_address_admin_uploads (filename, fail_reason, created_at, updated_at) VALUES('#{metadata}', '#{reason}', '#{DateTime.now.utc}', '#{DateTime.now.utc}')
    on conflict (filename)
    do update set fail_reason = EXCLUDED.fail_reason, updated_at = EXCLUDED.updated_at;"
    ActiveRecord::Base.connection_pool.with_connection do |db|
      db.exec_query(query)
    end
    true
  rescue PG::Error => e
    puts e.message
    Rails.logger.error(e.message)
    false
  end

  def self.log_postcode_file_loaded(filename, size, etag, created_at, updated_at)
    key   = extract_metadata(filename)
    query = "
    INSERT INTO os_address_admin_uploads (filename, size, etag, created_at, updated_at) VALUES('#{key}', #{size}, '#{etag}', '#{created_at}', '#{updated_at}')
    on conflict (filename)
    do update set fail_reason = null, size= EXCLUDED.size, etag = EXCLUDED.etag, created_at = EXCLUDED.created_at, updated_at = EXCLUDED.updated_at;"
    ActiveRecord::Base.connection_pool.with_connection do |db|
      db.exec_query(query)
    end
    true
  rescue PG::Error => e
    puts e.message
    Rails.logger.error(e.message)
    false
  end
end
# rubocop:enable Metrics/ModuleLength, Rails/Output
