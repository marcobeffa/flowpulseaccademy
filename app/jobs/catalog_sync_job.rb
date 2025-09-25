class CatalogSyncJob < ApplicationJob
  queue_as :default  # Solid Queue di solito usa :default

  def perform(hosts: nil, service_keys: nil)
    Catalog::Indexer.run!(hosts: hosts, service_keys: service_keys)
  end
end
