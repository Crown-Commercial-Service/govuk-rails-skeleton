require 'json'
require 'base64'
require 'net/http'
require 'uri'
class FMBuildingData
  def reset_buildings_tables
    query = 'truncate fm_uom_values;'
    ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(query) }
    query = 'truncate fm_lifts;'
    ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(query) }
    query = 'truncate facilities_management_buildings;'
    ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(query) }
  rescue StandardError => e
    Rails.logger.warn "Couldn't reset building tables: #{e}"
  end

  def save_building(email_address, building)
    Rails.logger.info '==> FMBuildingData.save_building()'

    CCS::FM::Building.create(id: building['id'],
                             user_id: Base64.encode64(email_address),
                             updated_by: Base64.encode64(email_address),
                             building_json: building)
  rescue StandardError => e
    Rails.logger.warn "Couldn't save building: #{e}"
  end

  def delete_uom_for_building(email_address, building_id)
    query = "delete from fm_uom_values where user_id = '" + Base64.encode64(email_address) + "' and building_id = '" + building_id + "';"
    ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(query) }
  rescue StandardError => e
    Rails.logger.warn "Couldn't delete uom's for building: #{e}"
  end

  def delete_lifts_for_building(email_address, building_id)
    query = "delete from fm_lifts where user_id = '" + Base64.encode64(email_address) + "' and building_id = '" + building_id + "';"
    ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(query) }
  rescue StandardError => e
    Rails.logger.warn "Couldn't delete lift info for building: #{e}"
  end

  def delete_building(email_address, building_id)
    Rails.logger.info '==> FMBuildingData.delete_building()'
    delete_uom_for_building(email_address, building_id)
    delete_lifts_for_building(email_address, building_id)
    query = "delete from facilities_management_buildings where user_id = '" + Base64.encode64(email_address) + "' and building_json ->> 'id' = '" + building_id + "';"
    ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(query) }
  rescue StandardError => e
    Rails.logger.warn "Couldn't delete building: #{e}"
  end

  def update_building(email_address, id, building)
    Rails.logger.info '==> FMBuildingData.update_building()'
    query = "update facilities_management_buildings set building_json = '" + building.gsub("'", "''") + "'" \
            " where user_id = '" + Base64.encode64(email_address) + "' and building_json ->> 'id' = '" + id + "'"
    ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(query) }
  rescue StandardError => e
    Rails.logger.warn "Couldn't update building: #{e}"
  end

  def get_building_data(email_address)
    Rails.logger.info '==> FMBuildingData.get_building_data()'
    ActiveRecord::Base.include_root_in_json = true
    query = "select updated_at, status, building_json as building from facilities_management_buildings where user_id = '" + Base64.encode64(email_address) + "'"
    result = ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(query) }
    Rails.logger.info '<== FMBuildingData.get_building_data()'
    JSON.parse(result.to_json)
  rescue StandardError => e
    Rails.logger.warn "Couldn't get building data: #{e}"
  end

  def get_building_data_by_id(email_address, id)
    Rails.logger.info '==> FMBuildingData.get_building_data_by_id()'
    ActiveRecord::Base.include_root_in_json = false
    query = "select updated_at, status, building_json as building from facilities_management_buildings where user_id = '" + Base64.encode64(email_address) + "' and building::jsonb --> 'id'= '" + id + "'"
    result = ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(query) }
    Rails.logger.info(result.to_json.to_s)
    JSON.parse(result.to_json)
  rescue StandardError => e
    Rails.logger.warn "Couldn't get building data: #{e}"
  end

  def get_count_of_buildings(email_address)
    Rails.logger.info '==> FMBuildingData.get_count_of_buildings()'
    query = "select count(*) as record_count from facilities_management_buildings where user_id = '" + Base64.encode64(email_address) + "'"
    result = ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(query) }
    result[0]['record_count']
  rescue StandardError => e
    Rails.logger.warn "Couldn't get count of buildings: #{e}"
    0
  end

  def region_info_for_post_town(post_code)
    Rails.logger.info '==> FMBuildingData.region_info_for_post_town()'
    # Needs to be converted to get the data from the database
    uri = URI('https://api.postcodes.io/postcodes/' + ERB::Util.url_encode(post_code))

    Net::HTTP.start(uri.host, uri.port,
                    use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new uri

      response = http.request request # Net::HTTPResponse object
      Rails.logger.info response.body
      response.body
    end
  rescue StandardError => e
    Rails.logger.warn "Couldn' t get region information for post town : #{e}"
  end

  def building_type_list
    ['General office - Customer Facing', 'General office - Non Customer Facing', 'Call Centre Operations',
     'Warehouses', 'Restaurant and Catering Facilities', 'Pre-School', 'Primary School', 'Secondary School', 'Special Schools',
     'Universities and Colleges', 'Doctors, Dentists and Health Clinics', 'Nursery and Care Homes', 'Data Centre Operations',
     'External parks, grounds and car parks', 'Laboratory', 'Heritage Buildings', 'Nuclear Facilities', 'Animal Facilities',
     'Custodial Facilities', 'Fire and Police Stations', 'Production Facilities', 'Workshops', 'Garages',
     'Shopping Centres', 'Museums /Galleries', 'Fitness / Training Establishments', 'Residential Buildings',
     'Port and Airport buildings', 'List X Property', 'Hospitals', 'Mothballed / Vacant / Disposal']
  end

  def building_type_list_descriptions
    { 'General office - Customer Facing' => 'General office areas and customer facing areas.',
      'General office - Non Customer Facing' => 'General office areas and non-customer facing areas.',
      'Call Centre Operations' => 'Call centre operations.',
      'Warehouses' => 'Large storage facility with limited office space and low density occupation by supplier personnel.',
      'Restaurant and Catering Facilities' => 'Areas including restaurants, deli-bars and coffee lounges areas used exclusively for consuming food and beverages.',
      'Pre-School' => 'Pre-school, including crèche, nursery and after-school facilities.',
      'Primary School' => 'Primary school facilities.',
      'Secondary School' => 'Secondary school facilities.',
      'Special Schools' => 'Special school facilities.',
      'Universities and Colleges' => '	University and college, including on and off site campus facilities but excluding student residential accommodation facilities.',
      'Doctors, Dentists and Health Clinics' => '	Community led facilities including doctors, dentists and health clinics.',
      'Nursery and Care Homes' => '	Nursery and care home facilities.',
      'Data Centre Operations' => 'Data centre operation.',
      'External parks, grounds and car parks' => '	External car parks and grounds including externally fixed assets - such as fences, gates, fountains etc.',
      'Laboratory' => 'Includes all Government facilities where the standard of cleanliness is high, access is restricted and is not public facing.',
      'Heritage Buildings' => 'Buildings of historical or cultural significance.',
      'Nuclear Facilities' => 'Areas associated with Nuclear activities.',
      'Animal Facilities' => 'Areas associated with the housing of animals such as dog kennels and stables.',
      'Custodial Facilities' => 'Facilities relating to the detention of personnel such as prisons and detention centres.',
      'Fire and Police Stations' => 'Areas associated with emergency services.',
      'Production Facilities' => 'An environment centred around a fabrication or production facility, typically with restricted access.',
      'Workshops' => 'Areas where works are undertaken such as joinery or metal working facilities',
      'Garages' => 'Areas where motor vehicles are cleaned, serviced, repaired and maintained.',
      'Shopping Centres' => 'Areas where retail services are delivered to the public.',
      'Museums /Galleries' => 'Areas are generally open to the public with some restrictions in place from time to time. Some facilities have no public access.',
      'Fitness / Training Establishments' => 'Areas associated with fitness and leisure such as swimming pools, gymnasia, fitness centres and internal / external sports facilities.',
      'Residential Buildings' => 'Residential accommodation / areas.',
      'Port and Airport buildings' => 'Areas associated with air and sea transportation and supporting facilities, such as airports, aerodromes and dock areas.',
      'List X Property' => 'A commercial site (i.e. non-Government) on UK soil that is approved to hold UK government protectively marked information marked as \'confidential\' and above. It is applied to a company\'s specific site and not a company as a whole.',
      'Hospitals' => 'Areas including mainstream medical, healthcare facilities such as hospitals and medical centres.',
      'Mothballed / Vacant / Disposal' => 'Areas which are vacant or awaiting disposal where no services are being undertaken.' }
  end
end
