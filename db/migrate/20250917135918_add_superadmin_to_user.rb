class AddSuperadminToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :superadmin, :boolean, default: false, null: false
    add_column :contacts, :lat, :decimal, precision: 10, scale: 6
    add_column :contacts, :lng, :decimal, precision: 10, scale: 6
    add_column :contacts, :address, :string
    add_reference :contacts, :user, null: true, foreign_key: true, index: true
    add_index :users, :superadmin
    add_reference :contacts, :responsable_contact, null: true, foreign_key: { to_table: :contacts }
  end
end
