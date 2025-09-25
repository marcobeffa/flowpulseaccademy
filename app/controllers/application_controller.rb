class ApplicationController < ActionController::Base
  helper_method :canonical_url
  helper_method :current_domain_config
  include Authentication
  before_action :set_current_domain

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern


  def canonical_url
    svc_key = params[:controller].split("/").first # es. "onlinecourses"
    svc = DomainRegistry.service(svc_key)
    return request.url unless svc

    brand = DomainRegistry.find_brand_for_host(request.host)
    return request.url unless brand

    host = "#{svc['subdomain']}.#{brand['seo']&.dig('canonical_host') || brand['host']}"
    uri  = URI.parse(request.url)
    uri.host = host
    uri.to_s
  end



  def current_domain_config
    @current_domain_config ||= DomainRegistry.find_domain_by_host(request.host)
  end
  # app/controllers/application_controller.rb

  private
  def set_current_domain
    Current.domain =
      if defined?(DomainRegistry)
        if DomainRegistry.respond_to?(:resolve)
          DomainRegistry.resolve(request.host)
        elsif DomainRegistry.respond_to?(:for_host)
          DomainRegistry.for_host(request.host)
        elsif DomainRegistry.respond_to?(:lookup)
          DomainRegistry.lookup(request.host)
        end
      end
  end
end
