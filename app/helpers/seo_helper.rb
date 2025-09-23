# app/helpers/seo_helper.rb
module SeoHelper
  # true se sto servendo il contenuto su un sottodominio di servizio
  # es: flowpulse.posturacorretta.org -> true (se 'flowpulse' è subdomain di un servizio attivo su posturacorretta.org)
  def service_host_request?
    host = request.host
    dom  = DomainRegistry.match_base_domain_config(host)
    return false unless dom

    sub, base = DomainRegistry.split_host(host)
    return false unless sub && base == dom["host"]

    Array(dom["active_services"]).any? do |k|
      svc = DomainRegistry.service(k)
      svc && svc["subdomain"] == sub
    end
  end

  def seo_tags_for_current_domain
    seo = DomainRegistry.seo_for(request.host)
    return unless seo.present?

    tags = []
    tags << tag.meta(name: "description", content: seo["description"]) if seo["description"]
    tags << tag.link(rel: "icon", href: (current_domain&.dig("favicon_url") || "/favicon.ico"))

    if (canon = seo["canonical_host"]).present?
      tags << tag.link(rel: "canonical", href: "https://#{canon}/")
    end

    if (og = seo["og"]).present?
      tags << tag.meta(property: "og:type",   content: og["type"])   if og["type"]
      tags << tag.meta(property: "og:locale", content: og["locale"]) if og["locale"]
    end
    tags << tag.meta(property: "og:title",       content: seo["title"])       if seo["title"]
    tags << tag.meta(property: "og:description", content: seo["description"]) if seo["description"]
    tags << tag.meta(property: "og:image",       content: seo["image_url"])   if seo["image_url"]
    tags << tag.meta(property: "og:url",         content: request.original_url)

    if (tw = seo["twitter"]).present?
      tags << tag.meta(name: "twitter:card",    content: tw["card"])    if tw["card"]
      tags << tag.meta(name: "twitter:site",    content: tw["site"])    if tw["site"]
      tags << tag.meta(name: "twitter:creator", content: tw["creator"]) if tw["creator"]
    end
    tags << tag.meta(name: "twitter:title",       content: seo["title"])       if seo["title"]
    tags << tag.meta(name: "twitter:description", content: seo["description"]) if seo["description"]
    tags << tag.meta(name: "twitter:image",       content: seo["image_url"])   if seo["image_url"]

    tags << tag.meta(name: "theme-color", content: seo["theme_color"]) if seo["theme_color"]

    if (apple = seo["apple"]).present?
      tags << tag.link(rel: "apple-touch-icon", href: apple["touch_icon_url"]) if apple["touch_icon_url"]
      tags << tag.link(rel: "mask-icon",        href: apple["mask_icon_url"], color: apple["tile_color"]) if apple["mask_icon_url"]
      tags << tag.meta(name: "msapplication-TileColor", content: apple["tile_color"]) if apple["tile_color"]
    end

    # Robots per host di servizio: non indicizzare
    if service_host_request?
      tags << tag.meta(name: "robots", content: "noindex,follow")
    end

    safe_join(tags, "\n")
  end

  def current_domain
    DomainRegistry.find_domain_by_host(request.host)
  end
end
