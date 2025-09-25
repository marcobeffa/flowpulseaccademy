# app/services/request_context.rb per la dashboard/user
# frozen_string_literal: true

module RequestContext
  module_function

  # Ritorna un Hash con:
  # :base_host, :domain (hash dal registry), :subdomain, :service_key, :slug, :segments
  def parse(host:, path:)
    dom = DomainRegistry.match_base_domain_config(host)
    return empty unless dom

    base_host = dom["host"]
    sub = subdomain_part(host, base_host) # "flowpulse" oppure "www"/nil

    # Se il sottodominio corrisponde a un subdomain di servizio, proviamo a leggere il service dal path
    service_key = nil
    segments = split_segments(path)
    if sub && DomainRegistry.service_subdomains.include?(sub)
      # Il path è in forma: /<service_key>(/<slug>...)
      key = segments[0].to_s
      active = Array(dom["active_services"]).map!(&:to_s)
      service_key = key if active.include?(key) && DomainRegistry.services.key?(key)
    end

    slug = segments[1]

    {
      base_host: base_host,
      domain: dom,
      subdomain: sub,
      service_key: service_key,
      slug: slug,
      segments: segments
    }
  end

  def empty = { base_host: nil, domain: nil, subdomain: nil, service_key: nil, slug: nil, segments: [] }

  # --- helpers ---
  def subdomain_part(host, base_host)
    return nil unless host&.end_with?(".#{base_host}")
    sub = host.delete_suffix(".#{base_host}")
    # scarta sottodomini multipli tipo "www" o "api.v1" (tieni solo la prima label)
    sub&.include?(".") ? sub.split(".").last : sub
  end

  def split_segments(path)
    path.to_s.split("/").reject(&:blank?)
  end
end
