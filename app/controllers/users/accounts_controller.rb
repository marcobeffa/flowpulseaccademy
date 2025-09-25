module Users
  class AccountsController < ApplicationController
    before_action :require_authentication  # fornito dal generator
    layout "dashboard"
    def edit
      @user = Current.user                # fornito dal generator
      @user.build_lead unless @user.lead
    end

    def update
      @user = Current.user
      @user.build_lead unless @user.lead

      if @user.update(user_params)
        redirect_to edit_account_path, notice: "Profilo aggiornato"
      else
        flash.now[:alert] = "Controlla i campi"
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def user_params
      params.require(:user).permit(
        :email_address,                # <-- email_address!
        lead_attributes: [
          :id, :nome, :cognome, :email, :telefono_facoltativo,
          :diventa_insegnante, :tipo_utente, :lat, :lng

        ]
      )
    end
  end
end
