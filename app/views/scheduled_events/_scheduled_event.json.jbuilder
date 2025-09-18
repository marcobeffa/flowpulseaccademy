json.extract! scheduled_event, :id, :contact_id, :training_course_id, :lesson_slug, :start_at, :end_at, :note, :created_at, :updated_at
json.url scheduled_event_url(scheduled_event, format: :json)
