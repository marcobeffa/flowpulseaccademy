module Superadmin
  class BaseController < ApplicationController
    before_action :require_superadmin!
    layout "dashboard"
    private

    def require_superadmin!
      unless Current.user&.superadmin?
        redirect_to root_path, alert: "Non autorizzato"
      end
    end
  end
end
