module Superadmin
  class ContactsController < BaseController
    before_action :require_superadmin!  # se ce l'hai già

    def index
      @tab = params[:tab].presence_in(%w[new assigned_no_user assigned_with_user all]) || "new"

      base = Contact.includes(:user).order(created_at: :desc)

      @counts = {
        new:                base.where(user_id: nil, responsable_contact_id: nil).count,
        assigned_no_user:   base.where(responsable_contact_id: nil).where(user_id: nil).count,
        assigned_with_user: base.where(responsable_contact_id: nil).where.not(user_id: nil).count,
        all:                base.where.not(responsable_contact_id: nil).where.not(user_id: nil).count
      }

      @contacts =
        case @tab
        when "new"
          base.where(user_id: nil, responsable_contact_id: nil)
        when "assigned_no_user"
          base.where.not(responsable_contact_id: nil).where(user_id: nil)
        when "assigned_with_user"
          base.where(responsable_contact_id: nil).where.not(user_id: nil)
        when "all"
          base.where.not(responsable_contact_id: nil).where.not(user_id: nil)
        else
          base.none
        end

      # per la tendina "assegna a utente"
      @users = User.order(:email_address).limit(500)
    end

    def update
      contact = Contact.find(params[:id])
      if contact.update(contact_params)
        redirect_back fallback_location: superadmin_contacts_path, notice: "Contatto aggiornato"
      else
        redirect_back fallback_location: superadmin_contacts_path, alert: contact.errors.full_messages.to_sentence
      end
    end

    def assign_user
      contact = Contact.find(params[:id])

      user =
        if params[:user_id].present?
          User.find_by(id: params[:user_id])
        elsif params[:email_address].present?
          User.find_by(email_address: params[:email_address].to_s.strip.downcase)
        end

      if user
        contact.update(user_id: user.id)
        redirect_back fallback_location: superadmin_contacts_path(tab: params[:tab]), notice: "Assegnato a #{user.email_address}"
      else
        redirect_back fallback_location: superadmin_contacts_path(tab: params[:tab]), alert: "Utente non trovato"
      end
    end

    def create_user
      contact = Contact.find(params[:id])
      return redirect_back fallback_location: superadmin_contacts_path, alert: "Già collegato a un utente" if contact.user_id.present?

      temp_pwd = SecureRandom.base58(12)
      user = User.new(
        email_address: contact.email,
        password: temp_pwd,
        password_confirmation: temp_pwd
      )

      if user.save
        contact.update(user_id: user.id)
        # Se vuoi, invia subito mail reset:
        # PasswordsMailer.reset(user).deliver_later
        redirect_back fallback_location: superadmin_contacts_path(tab: params[:tab]), notice: "Utente creato e collegato"
      else
        redirect_back fallback_location: superadmin_contacts_path(tab: params[:tab]), alert: user.errors.full_messages.to_sentence
      end
    end

    private

    def contact_params
      params.require(:contact).permit(
        :nome, :cognome, :email, :telefono_facoltativo,
        :diventa_insegnante, :tipo_utente, :responsable_contact_id
      )
    end
  end
end
