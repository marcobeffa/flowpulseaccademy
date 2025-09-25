# All Administrate controllers inherit from this
# `Administrate::ApplicationController`, making it the ideal place to put
# authentication logic or other before_actions.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
module Admin
  class ApplicationController < Administrate::ApplicationController
    include Authentication        # <-- creato dal generator di Rails 8
    before_action :authenticated?   # proteggi tutta l’area admin
    before_action :require_admin!

    helper_method :current_user, :authenticated?

    # Override this value to specify the number of elements to display at a time
    # on index pages. Defaults to 20.
    # def records_per_page
    #   params[:per_page] || 20
    # end
    # private

    #   # Limita le query ai brand che l'admin può vedere (superadmin vede tutto)
    # def scoped_resource(resource)
    #   return resource if current_user&.superadmin?
    #   hosts = current_user&.brand_subscriptions&.pluck(:host)
    #   hosts.present? ? resource.where(host: hosts) : resource.none
    # end

    def require_admin!
      allowed = Current.user&.respond_to?(:admin?) ? Current.user.admin? : false
      allowed ||= Current.user&.superadmin?
      head :forbidden unless allowed
    end
  end
end
