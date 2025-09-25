


class CreateDomainSubscriptions < ActiveRecord::Migration[8.0]
  def change
     create_table :domain_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :host, null: false
      t.string  :title
      t.string  :favicon_url
      t.datetime :subscribed_at, null: false
      t.timestamps
    end
    add_index :domain_subscriptions, [ :user_id, :host ], unique: true
  end
end dovrei modificarlo e aggiungere anche lead  perchè l'idea per ora è la conferma manuale con email o messaggio inviato da un operatore... la persona si registra come lead e invia una subscription domain che poi viene vista dall'operatore e può darsi che l'utente non ci sia ancora! - perciò possibilità  persona si registra come contatto scegliendo dal dominio e operatore attiva e crea lead | operatore aggiunge a un lead un domains_subscription | il lead che poi è diventato user conferma l'iscrizione e viene assegnata anche all'user! ù
-------

1) Migrazione per rinominare tabella

Se hai già dati e vuoi mantenerli:

bin/rails g migration RenameContactsToLeads

class RenameContactsToLeads < ActiveRecord::Migration[8.0]
  def change
    rename_table :contacts, :leads
  end
end


Se invece puoi distruggere i dati, fai direttamente drop_table + nuova create_table :leads.

2) Model
# app/models/lead.rb
class Lead < ApplicationRecord
  enum tipo_utente: { utente: 0, professionista: 1, insegnante: 2 }

  validates :nome, :cognome, :email, presence: true
  validates :email, uniqueness: true
end

3) Controller

Se hai un ContactsController, lo rinomini in LeadsController:

git mv app/controllers/contacts_controller.rb app/controllers/leads_controller.rb


Poi dentro:

class LeadsController < ApplicationController
  def new
    @lead = Lead.new
  end

  def create
    @lead = Lead.new(lead_params)
    if @lead.save
      redirect_to root_path, notice: "Grazie, ti ricontatteremo!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def lead_params
    params.require(:lead).permit(:nome, :cognome, :email, :telefono_facoltativo, :diventa_insegnante, :tipo_utente)
  end
end

4) Rotte

Aggiorna config/routes.rb:

resources :leads, only: %i[new create]


(se vuoi mantenere compatibilità temporanea puoi fare anche un resources :contacts, controller: "leads" finché aggiorni i form).

5) View

Sposta le view:

git mv app/views/contacts app/views/leads


Dentro aggiorna i form builder:

<%= form_with model: @lead do |f| %>
  <%= f.text_field :nome %>
  <%= f.text_field :cognome %>
  <%= f.email_field :email %>
  <%= f.telephone_field :telefono_facoltativo %>
  <%= f.check_box :diventa_insegnante %>
  <%= f.select :tipo_utente, Lead.tipo_utenti.keys %>
  <%= f.submit "Invia" %>
<% end %>


👉 così “lead” diventa il tuo contenitore principale per richieste/iscrizioni.
Più avanti puoi aggiungere anche:

source (es. landing page, referral, social)

status (nuovo, contattato, convertito, ecc.)

notes interne

Vuoi che ti faccia una tabella Lead completa stile CRM (con status, source, ecc.) già pronta per usarla in admin/superadmin?

