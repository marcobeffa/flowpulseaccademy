class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  helper_method :current_domain_config


  def current_domain_config
    @current_domain_config ||= DomainRegistry.find_domain_by_host(request.host)
  end
end
