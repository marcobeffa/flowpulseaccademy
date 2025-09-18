module Users
  class ChangePasswordsController < ApplicationController
    before_action :require_authentication
    layout "dashboard"
    def edit
    end

    def update
      unless Current.user.authenticate(params.dig(:user, :current_password).to_s)
        flash.now[:alert] = "Password attuale errata"
        return render :edit, status: :unprocessable_entity
      end

      if Current.user.update(password_params)
        redirect_to account_path, notice: "Password aggiornata con successo"
      else
        flash.now[:alert] = "Errore durante l’aggiornamento della password"
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def password_params
      params.require(:user).permit(:password, :password_confirmation)
    end
  end
end
