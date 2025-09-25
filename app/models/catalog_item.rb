class CatalogItem < ApplicationRecord
  enum :source_type, { yml: "yml", db: "db" }
  validates :host, :service_key, :slug, :title, :source_type, presence: true

  scope :for_brand,   ->(host) { where(host: host) }
  scope :for_service, ->(key)  { where(service_key: key.to_s) }
  scope :published,   ->       { where(status: "published") }
end
