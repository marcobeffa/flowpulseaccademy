module Teaching
  class BaseController < ApplicationController
    before_action :ensure_teaching_host

    private

    def ensure_teaching_host
      # Montato sul sottodominio giusto? (flowpulse.<dominio>)
      return if DomainRegistry.allow_service_host?(:teaching, request.host)

      # In caso contrario, reindirizza all'host corretto se possibile
      if (url = view_context.service_url_for(:teaching))
        redirect_to url, allow_other_host: true
      else
        head :not_found
      end
    end
  end
end
