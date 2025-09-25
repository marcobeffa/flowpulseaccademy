# app/controllers/dashboard/user_controller.rb
module Dashboard
  class UserController < ApplicationController
     layout "dashboard"
    def show
      @ctx = RequestContext.parse(host: request.host, path: request.path)

      # Brand (host) sottoscritti dall’utente
      subs_hosts = Current.user.domain_subscriptions.pluck(:host)

      # Se sto visitando un host di servizio (flowpulse.<brand>), forza il brand corrente in testa
      current_host = @ctx[:base_host]
      hosts = (current_host.present? ? [ current_host ] : []) | subs_hosts

      # servizi attivi per ciascun brand
      @active_services = {}
      hosts.each do |h|
        dom = DomainRegistry.domains[h] or next
        @active_services[h] = Array(dom["active_services"]).map!(&:to_s)
      end

      # Query indice
      scope = CatalogItem.where(host: hosts)
      scope = scope.where(service_key: @ctx[:service_key]) if @ctx[:service_key].present?
      @items = scope.order(Arel.sql("COALESCE(published_at, created_at) DESC")).limit(48)

      # Per sidebar/menu
      @brands = hosts.map { |h| DomainRegistry.domains[h] }.compact.index_by { |d| d["host"] }
    end
  end
end
