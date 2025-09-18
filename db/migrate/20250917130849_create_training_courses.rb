class CreateTrainingCourses < ActiveRecord::Migration[8.0]
  def change
    create_table :training_courses do |t|
      t.string :course_slug
      t.references :contact, null: false, foreign_key: true
      t.string :version
      t.datetime :registrations_open_at
      t.datetime :registrations_close_at
      t.string :package_slug
      t.integer :tutor_role_id
      t.integer :teacher_role_id
      t.integer :trainee_role_id
      t.integer :venue_manager_role_id
      t.text :location_name
      t.text :location_address
      t.string :location_gmaps
      t.decimal :lat, precision: 10, scale: 6
      t.decimal :lng, precision: 10, scale: 6
      t.string :location_phone
      t.integer :participants_count

      t.timestamps
    end
    add_index :training_courses, :course_slug
    add_index :training_courses, :package_slug
  end
end
