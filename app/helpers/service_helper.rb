# app/helpers/service_helper.rb
module ServiceHelper
  def service_mounted?(key)
    DomainRegistry.allow_service_host?(key, request.host)
  end

  def service_enabled_for_current_domain?(key)
    dom = DomainRegistry.match_base_domain_config(request.host)
    dom && Array(dom["active_services"]).map(&:to_s).include?(key.to_s)
  end

  def service_host_for(key)
    dom = DomainRegistry.match_base_domain_config(request.host) or return nil
    svc = DomainRegistry.service(key) or return nil
    "#{svc['subdomain']}.#{dom['host']}"
  end

  # URL assoluto verso /<service> (es. /onlinecourses)
  def service_url_for(key, path: nil)
    host = service_host_for(key) or return nil
    proto = request.protocol
    port  = request.port && ![ 80, 443 ].include?(request.port) ? ":#{request.port}" : ""
    base  = "#{proto}#{host}#{port}"
    seg   = "/#{key}"
    seg  += path.start_with?("/") ? path : "/#{path}" if path.present?
    "#{base}#{seg}"
  end

  # URL del root del sottodominio (es. https://flowpulse.posturacorretta.org/)
  def service_root_url(key)
    host = service_host_for(key) or return nil
    proto = request.protocol
    port  = request.port && ![ 80, 443 ].include?(request.port) ? ":#{request.port}" : ""
    "#{proto}#{host}#{port}/"
  end
end
