# lib/domain_routes.rb
module DomainRoutes
  module_function


  def brand_controller_for(dom, action: "home")
    if action == "home" && (ul = dom["url_landing"]).is_a?(String) && ul.include?("#")
      ul
    else
      brand = dom["host"].to_s.split(".").first
      "domains/#{brand}##{action}"
    end
  end

  def brand_pages(dom)
    defaults = %w[home about contact privacy terms]
    extras   = Array(dom["pages"]).map(&:to_s)
    (defaults + extras).uniq
  end



  class HostConstraint
    def initialize(hosts) ; @hosts = hosts ; end
    def matches?(req)    ; @hosts.include?(req.host) ; end
  end

  # constraints per host multipli
  def domain_constraint_for_hosts(hosts)
    HostConstraint.new(hosts.compact.uniq)
  end

  # constraints per servizio (monta solo sui host validi)
  def service_constraint(service_key)
    svc = DomainRegistry.service(service_key.to_s)
    raise "Unknown service: #{service_key}" unless svc

    allowed = DomainRegistry.domains.values.flat_map do |dom|
      # monta SOLO sui brand dove il servizio è attivo
      next [] unless Array(dom["active_services"]).map(&:to_s).include?(service_key.to_s)

      base    = "#{svc['subdomain']}.#{dom['host']}"
      aliases = Array(dom["aliases"]).map { |a| "#{svc['subdomain']}.#{a}" }
      [ base, *aliases ]
    end

    HostConstraint.new(allowed.compact.uniq)
  end
end
