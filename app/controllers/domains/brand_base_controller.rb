# app/controllers/domains/brand_base_controller.rb
module Domains
  class BrandBaseController < ApplicationController
    class_attribute :default_brand_slug, default: "posturacorretta"
    allow_unauthenticated_access only: %i[home about contact privacy terms page]

    def home    = render_brand_page("home")
    def about   = render_brand_page("about")
    def contact = render_brand_page("contact")
    def privacy = render_brand_page("privacy")
    def terms   = render_brand_page("terms")

    # per /:page (solo se la pagina è consentita per questo brand)
    def page
      page = params[:page].to_s
      unless allowed_page?(page)
        raise ActionController::RoutingError, "Not Found"
      end
      render_brand_page(page)
    end

    private

    def resolve_brand_slug
      if defined?(DomainRegistry)
        dom  = DomainRegistry.match_base_domain_config(request.host) rescue nil
        slug = dom && dom["host"].to_s.split(".").first
        return slug if slug.present?
      end
      request.host.to_s.split(".").first.presence || self.class.default_brand_slug
    end

    def allowed_page?(page)
      dom = DomainRegistry.match_base_domain_config(request.host) rescue nil
      allowed = DomainRoutes.brand_pages(dom || {})
      allowed.include?(page)
    end

    def render_brand_page(page)
      slug = resolve_brand_slug
      tpl  = "domains/#{slug}/#{page}"
      if lookup_context.exists?(tpl, [], true)
        render tpl
      else
        render "domains/#{self.class.default_brand_slug}/#{page}"
      end
    end
  end
end
