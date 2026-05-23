class AddNormalizedNameToPositions < ActiveRecord::Migration[8.0]
  def up
    add_column :positions, :normalized_name, :string

    execute <<~SQL
      UPDATE positions
      SET normalized_name = LOWER(BTRIM(name))
      WHERE normalized_name IS NULL
    SQL

    change_column_null :positions, :normalized_name, false

    remove_index :positions, :name if index_exists?(:positions, :name)
    add_index :positions, :normalized_name, unique: true
  end

  def down
    remove_index :positions, :normalized_name if index_exists?(:positions, :normalized_name)
    add_index :positions, :name, unique: true unless index_exists?(:positions, :name)

    remove_column :positions, :normalized_name
  end
end
