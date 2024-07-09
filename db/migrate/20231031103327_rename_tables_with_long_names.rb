class RenameTablesWithLongNames < ActiveRecord::Migration[7.1]
  # We need to add this because we've had some issues on higher environments where it can't rename tables because of a primary key index name issue
  # def change
  #   rename_table :facilities_management_rm3830_procurement_building_service_lifts, :facilities_management_procurement_building_service_lifts
  #   rename_table :facilities_management_rm3830_procurement_call_off_extensions, :facilities_management_rm3830_procurement_extensions
  #   rename_table :facilities_management_rm6232_procurement_call_off_extensions, :facilities_management_rm6232_procurement_extensions
  # end

  def up
    ActiveRecord::Base.connection.exec_query('ALTER TABLE facilities_management_rm3830_procurement_building_service_lifts RENAME TO facilities_management_procurement_building_service_lifts;')
    ActiveRecord::Base.connection.exec_query('ALTER TABLE facilities_management_rm3830_procurement_call_off_extensions RENAME TO facilities_management_rm3830_procurement_extensions;')
    ActiveRecord::Base.connection.exec_query('ALTER TABLE facilities_management_rm6232_procurement_call_off_extensions RENAME TO facilities_management_rm6232_procurement_extensions;')
  end

  def down
    ActiveRecord::Base.connection.exec_query('ALTER TABLE facilities_management_procurement_building_service_lifts RENAME TO facilities_management_rm3830_procurement_building_service_lifts;')
    ActiveRecord::Base.connection.exec_query('ALTER TABLE facilities_management_rm3830_procurement_extensions RENAME TO facilities_management_rm3830_procurement_call_off_extensions;')
    ActiveRecord::Base.connection.exec_query('ALTER TABLE facilities_management_rm6232_procurement_extensions RENAME TO facilities_management_rm6232_procurement_call_off_extensions;')
  end
end
