class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.references :list, null: false, foreign_key: true
      t.string :title
      t.string :ancestry
      t.integer :position

      t.timestamps
    end
    add_index :items, [ :list_id, :ancestry ]
    add_index :items, [ :list_id, :ancestry, :position ]
  end
end
