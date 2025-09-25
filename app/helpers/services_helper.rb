# app/helpers/services_helper.rb
module ServicesHelper
  # Config del dominio base per l'host dato (o corrente)
  def base_domain_for(host = nil)
    DomainRegistry.match_base_domain_config(host || request&.host)
  end

  # Il servizio è abilitato nel dominio (da domains.yml)?
  def service_enabled_for_domain?(key, host: nil)
    dom = base_domain_for(host)
    dom && Array(dom["active_services"]).map(&:to_s).include?(key.to_s)
  end

  def service_enabled_for_current_domain?(key)
    dom = DomainRegistry.match_base_domain_config(request&.host)
    Array(dom && dom["active_services"]).map(&:to_s).include?(key.to_s)
  end


  # Il servizio è montato su questo host (subdominio corretto)?
  def service_mounted?(key, host: nil)
    DomainRegistry.allow_service_host?(key, host || request&.host)
  end

  # Host "sub.domain.tld" per un servizio su un dominio base.
  def service_host_for(key, host: nil)
    dom = base_domain_for(host) or return nil
    svc = DomainRegistry.service(key) or return nil
    "#{svc['subdomain']}.#{dom['host']}"
  end

  # URL assoluto della root del sottodominio del servizio (…/).
  def service_root_url(key, host: nil, protocol: nil, port: nil)
    h   = service_host_for(key, host: host) or return nil
    proto = protocol || request&.protocol || "https://"
    prt   = (port || request&.port)
    prt   = prt && ![ 80, 443 ].include?(prt) ? ":#{prt}" : ""
    "#{proto}#{h}#{prt}/"
  end

  # URL assoluto per un path qualunque sul sottodominio del servizio.
  # Esempi: service_absolute_url(:onlinecourses, host: "posturacorretta.org", path: "onlinecourses/igiene-posturale")
  def service_absolute_url(key, host: nil, path: nil, protocol: nil, port: nil)
    root = service_root_url(key, host: host, protocol: protocol, port: port) or return nil
    return root if path.blank?
    seg = path.to_s.start_with?("/") ? path.to_s : "/#{path}"
    "#{root.chomp('/')}#{seg}"
  end

  # URL canonico al path /<service_key>(/<rest>) sul sottodominio del servizio.
  # Esempio: service_url_for(:teaching, host: "posturacorretta.org", path: "training_courses")
  def service_url_for(key, host: nil, path: nil, protocol: nil, port: nil)
    p = path.present? ? File.join(key.to_s, path.to_s) : key.to_s
    service_absolute_url(key, host: host, path: "/#{p}", protocol: protocol, port: port)
  end

  # Solo il path relativo (sull’host corrente): "/<service_key>(/<rest>)"
  # Utile per redirect 301 dal dominio base al sottodominio.
  def service_relative_path(key, path: nil)
    seg = "/#{key}"
    seg += path.start_with?("/") ? path : "/#{path}" if path.present?
    seg
  end
end
