# app/controllers/superadmin/catalog_controller.rb
module Superadmin
  class CatalogController < BaseController
    before_action :require_superadmin!

    def sync
      hosts        = params[:hosts].presence&.split(",")        # opzionale
      service_keys = params[:service_keys].presence&.split(",") # opzionale
      CatalogSyncJob.perform_later(hosts: hosts, service_keys: service_keys)
      redirect_back fallback_location: superadmin_root_path, notice: "Sync avviato."
    end

    def sync_brand
      host = params[:host].to_s.downcase
      return redirect_back(fallback_location: superadmin_root_path, alert: "Host sconosciuto") unless DomainRegistry.domains.key?(host)
      CatalogSyncJob.perform_later(hosts: [ host ])
      redirect_back fallback_location: superadmin_root_path, notice: "Sync avviato per #{host}."
    end
  end
end
