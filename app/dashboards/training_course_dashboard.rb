require "administrate/base_dashboard"

class TrainingCourseDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    contact_id: Field::Number,
    course_slug: Field::String,
    lat: Field::String.with_options(searchable: false),
    lng: Field::String.with_options(searchable: false),
    location_address: Field::Text,
    location_gmaps: Field::String,
    location_name: Field::Text,
    location_phone: Field::String,
    package_slug: Field::String,
    participants_count: Field::Number,
    registrations_close_at: Field::DateTime,
    registrations_open_at: Field::DateTime,
    teacher_role_id: Field::Number,
    trainee_role_id: Field::Number,
    tutor_role_id: Field::Number,
    venue_manager_role_id: Field::Number,
    version: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    contact_id
    course_slug
    lat
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    contact_id
    course_slug
    lat
    lng
    location_address
    location_gmaps
    location_name
    location_phone
    package_slug
    participants_count
    registrations_close_at
    registrations_open_at
    teacher_role_id
    trainee_role_id
    tutor_role_id
    venue_manager_role_id
    version
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    contact_id
    course_slug
    lat
    lng
    location_address
    location_gmaps
    location_name
    location_phone
    package_slug
    participants_count
    registrations_close_at
    registrations_open_at
    teacher_role_id
    trainee_role_id
    tutor_role_id
    venue_manager_role_id
    version
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how training courses are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(training_course)
  #   "TrainingCourse ##{training_course.id}"
  # end
end
