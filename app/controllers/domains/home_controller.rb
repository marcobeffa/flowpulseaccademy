# app/controllers/domains/home_controller.rb


class Domains::HomeController < ApplicationController
  # This action is mounted as the host-specific root.
  # It interprets the domain’s url_landing and either
  # - renders a template
  # - dispatches to controller#action
  # - redirects to an absolute URL
  def show
    dom = DomainRegistry.find_domain_by_host(request.host)
    head :not_found and return unless dom


    landing = dom["url_landing"].to_s


    if landing.start_with?("http://", "https://")
     redirect_to landing, allow_other_host: true and return
    end


    if landing.include?("#")
    controller, action = landing.split("#", 2)
    render template: controller, action: action, layout: "application"
    else
    # Treat as a template path like "domains/flowpulse"
    render template: landing, layout: "application"
    end
  end
end
