class FmUnitsOfMeasurement < ActiveRecord::Migration[5.2]
  def change
    create_table 'fm_units_of_measurement', id: false do |t|
      t.serial 'id', null: false
      t.text 'title_text', null: false
      t.text 'example_text'
      t.text 'unit_text'
      t.text 'data_type'
      t.text 'spreadsheet_label'
      t.text 'service_usage', array: true
      t.timestamps
    end
  end
end
