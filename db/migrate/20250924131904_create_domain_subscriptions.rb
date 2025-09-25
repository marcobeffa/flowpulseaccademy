class CreateDomainSubscriptions < ActiveRecord::Migration[8.0]
  def change
     create_table :domain_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :host, null: false
      t.string  :title
      t.string  :favicon_url
      t.datetime :subscribed_at, null: false
      t.timestamps
    end
    add_index :domain_subscriptions, [ :user_id, :host ], unique: true
  end
end
