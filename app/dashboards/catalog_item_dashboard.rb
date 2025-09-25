require "administrate/base_dashboard"

class CatalogItemDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    data: Field::String.with_options(searchable: false),
    host: Field::String,
    published_at: Field::DateTime,
    service_key: Field::String,
    slug: Field::String,
    source_id: Field::Number,
    source_table: Field::String,
    source_type: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    status: Field::String,
    title: Field::String,
    version: Field::String,
    yml_path: Field::String,
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
    data
    host
    published_at
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    data
    host
    published_at
    service_key
    slug
    source_id
    source_table
    source_type
    status
    title
    version
    yml_path
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    data
    host
    published_at
    service_key
    slug
    source_id
    source_table
    source_type
    status
    title
    version
    yml_path
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

  # Overwrite this method to customize how catalog items are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(catalog_item)
  #   "CatalogItem ##{catalog_item.id}"
  # end
end
