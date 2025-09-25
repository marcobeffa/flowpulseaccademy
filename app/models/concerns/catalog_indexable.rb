module CatalogIndexable
  extend ActiveSupport::Concern

  included do
    after_commit :catalog_upsert!,  on: [ :create, :update ]
    after_commit :catalog_delete!,  on: :destroy
  end

  # Override se i nomi/colonne differiscono:
  def catalog_host         = self.respond_to?(:host) ? self.host : nil
  def catalog_service_key  = self.class.name.underscore # override nei modelli
  def catalog_slug         = self.slug
  def catalog_title        = self.respond_to?(:title) ? self.title : self.slug
  def catalog_status       = self.respond_to?(:published?) && published? ? "published" : "draft"
  def catalog_published_at = self.try(:published_at) || self.try(:created_at)

  private

  def catalog_upsert!
    return if catalog_host.blank?
    CatalogItem.upsert(
      {
        host:         catalog_host,
        service_key:  catalog_service_key, # es. override -> "blog"
        slug:         catalog_slug,
        title:        catalog_title,
        source_type:  "db",
        source_table: self.class.table_name,
        source_id:    self.id,
        status:       catalog_status,
        published_at: catalog_published_at,
        data:         {}
      },
      unique_by: :idx_catalog_unique
    )
  end

  def catalog_delete!
    return if catalog_host.blank?
    CatalogItem.where(
      host:        catalog_host,
      service_key: catalog_service_key,
      slug:        catalog_slug
    ).delete_all
  end
end
