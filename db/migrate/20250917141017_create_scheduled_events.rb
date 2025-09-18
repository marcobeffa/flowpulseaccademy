class CreateScheduledEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :scheduled_events do |t|
      t.references :contact, null: false, foreign_key: true
      t.references :training_course, null: true, foreign_key: true
      t.string :lesson_slug
      t.datetime :start_at
      t.datetime :end_at
      t.text :note

      t.timestamps
    end
    add_index :scheduled_events, :lesson_slug
  end
end
