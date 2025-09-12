class CreateContacts < ActiveRecord::Migration[8.0]
   def change
    create_table :contacts do |t|
      t.string  :nome,    null: false
      t.string  :cognome, null: false
      t.string  :email,   null: false
      t.string :telefono_facoltativo,   null: true
      t.boolean :diventa_insegnante, null: false, default: false
      t.integer :tipo_utente, null: false, default: 0 # 0=utente

      t.timestamps
    end

    add_index :contacts, :email, unique: true
    add_index :contacts, :tipo_utente
  end
end
