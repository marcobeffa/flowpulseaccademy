json.extract! training_course, :id, :course_slug, :registrations_open_at, :registrations_close_at, :package_slug, :tutor_role_id, :teacher_role_id, :trainee_role_id, :venue_manager_role_id, :location_name, :location_address, :location_gmaps, :lat, :lng, :location_phone, :participants_count, :created_at, :updated_at
json.url training_course_url(training_course, format: :json)
