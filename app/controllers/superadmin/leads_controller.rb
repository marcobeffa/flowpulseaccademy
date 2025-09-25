module Superadmin
  class LeadsController < BaseController
    before_action :require_superadmin!  # se ce l'hai già

    def index
      @tab = params[:tab].presence_in(%w[new assigned_no_user assigned_with_user all]) || "new"

      base = Lead.includes(:user).order(created_at: :desc)

      @counts = {
        new:                base.where(user_id: nil, responsable_lead_id: nil).count,
        assigned_no_user:   base.where(responsable_lead_id: nil).where(user_id: nil).count,
        assigned_with_user: base.where(responsable_lead_id: nil).where.not(user_id: nil).count,
        all:                base.where.not(responsable_lead_id: nil).where.not(user_id: nil).count
      }

      @leads =
        case @tab
        when "new"
          base.where(user_id: nil, responsable_lead_id: nil)
        when "assigned_no_user"
          base.where.not(responsable_lead_id: nil).where(user_id: nil)
        when "assigned_with_user"
          base.where(responsable_lead_id: nil).where.not(user_id: nil)
        when "all"
          base.where.not(responsable_lead_id: nil).where.not(user_id: nil)
        else
          base.none
        end

      # per la tendina "assegna a utente"
      @users = User.order(:email_address).limit(500)
    end

    def update
      lead = Lead.find(params[:id])
      if lead.update(lead_params)
        redirect_back fallback_location: superadmin_leads_path, notice: "Contatto aggiornato"
      else
        redirect_back fallback_location: superadmin_leads_path, alert: lead.errors.full_messages.to_sentence
      end
    end

    def assign_user
      lead = Lead.find(params[:id])

      user =
        if params[:user_id].present?
          User.find_by(id: params[:user_id])
        elsif params[:email_address].present?
          User.find_by(email_address: params[:email_address].to_s.strip.downcase)
        end

      if user
        lead.update(user_id: user.id)
        redirect_back fallback_location: superadmin_leads_path(tab: params[:tab]), notice: "Assegnato a #{user.email_address}"
      else
        redirect_back fallback_location: superadmin_leads_path(tab: params[:tab]), alert: "Utente non trovato"
      end
    end

    def create_user
      lead = Lead.find(params[:id])
      return redirect_back fallback_location: superadmin_leads_path, alert: "Già collegato a un utente" if lead.user_id.present?

      temp_pwd = SecureRandom.base58(12)
      user = User.new(
        email_address: lead.email,
        password: temp_pwd,
        password_confirmation: temp_pwd
      )

      if user.save
        lead.update(user_id: user.id)
        # Se vuoi, invia subito mail reset:
        # PasswordsMailer.reset(user).deliver_later
        redirect_back fallback_location: superadmin_leads_path(tab: params[:tab]), notice: "Utente creato e collegato"
      else
        redirect_back fallback_location: superadmin_leads_path(tab: params[:tab]), alert: user.errors.full_messages.to_sentence
      end
    end

    private

    def lead_params
      params.require(:lead).permit(
        :nome, :cognome, :email, :telefono_facoltativo,
        :diventa_insegnante, :tipo_utente, :responsable_lead_id
      )
    end
  end
end
