class CreateEmployees < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      t.string :name, null: false
      t.decimal :salary, null: false, precision: 12, scale: 2
      t.references :position, null: false, foreign_key: true

      t.timestamps
    end

    add_index :employees, :name
  end
end
