# app/controllers/domains/home_controller.rb
class Domains::HomeController < ApplicationController
  def show
    slug = Current.domain&.slug.presence || "default" # o da DomainRegistry
    tpl  = "domains/#{slug}"

    if lookup_context.exists?(tpl, [], true)
      render tpl
    else
      # redirect a una pagina “home” *diversa* da questo stesso action
      target = main_app.respond_to?(:pages_home_path) ? main_app.pages_home_path : main_app.root_path

      # prevenzione loop
      if request.fullpath == target || request.path == target
        render "domains/default", status: :ok # crea una view di default, semplice
      else
        redirect_to target
      end
    end
  end
end
