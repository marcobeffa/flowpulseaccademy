class CreateCatalogItems < ActiveRecord::Migration[7.2]
  def change
    create_table :catalog_items do |t|
      t.string  :host,        null: false
      t.string  :service_key, null: false
      t.string  :slug,        null: false
      t.string  :title,       null: false
      t.string  :source_type, null: false    # "yml" | "db"
      t.string  :source_table
      t.bigint  :source_id
      t.string  :yml_path
      t.string  :version
      t.datetime :published_at
      t.string  :status                        # "draft" | "published" | ...
      t.jsonb   :data, default: {}
      t.timestamps
    end

    add_index :catalog_items, [ :host, :service_key, :slug ],
              unique: true, name: "idx_catalog_unique"
    add_index :catalog_items, [ :source_table, :source_id ]
    add_index :catalog_items, :host
    add_index :catalog_items, :service_key
    add_index :catalog_items, :slug
    add_index :catalog_items, :published_at
    add_index :catalog_items, :status
    add_index :catalog_items, :data, using: :gin
  end
end
