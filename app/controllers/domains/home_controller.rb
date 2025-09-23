# app/controllers/domains/home_controller.rb
class Domains::HomeController < ApplicationController
   def show
    slug =
      if Current.domain&.respond_to?(:slug) then Current.domain.slug
      elsif Current.domain.is_a?(Hash)       then Current.domain[:slug]
      else
        request.host.split(".").first.presence || "default"
      end

    tpl = "domains/#{slug}"
    if lookup_context.exists?(tpl, [], true)
      render tpl
    else
      target = main_app.respond_to?(:pages_home_path) ? main_app.pages_home_path : main_app.root_path
      return render("domains/default") if request.path == target
      redirect_to target
    end
  end
end
