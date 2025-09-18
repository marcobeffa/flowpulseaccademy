class Contact < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :user, optional: true
  has_many :scheduled_events

  # relazione self-referential: un contact può avere un "responsabile"
  belongs_to :responsable_contact,
             class_name: "Contact",
             optional: true

  # relazione inversa: un contact può essere responsabile di più sub-contacts
  has_many :sub_contacts,
           class_name: "Contact",
           foreign_key: "responsable_contact_id",
           dependent: :nullify  # se cancelli il responsabile, i figli non vengono cancellati

  enum :tipo_utente, {
    utente: 0,
    professionista_salute: 1,
    professionista_benessere: 2
  }
  before_validation :normalize_email

  validates :nome, :cognome, presence: true
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :tipo_utente, presence: true
  validates :diventa_insegnante, inclusion: { in: [ true, false ] }

  # Reverse geocoding
  reverse_geocoded_by :lat, :lng do |obj, results|
    if geo = results.first
      city     = geo.city
      province = geo.state_code
      region   = geo.state
      country  = geo.country

      obj.address = [ city, province, region, country ].compact.join(", ")
    end
  end

  after_validation :reverse_geocode, if: ->(obj) { obj.lat.present? && obj.lng.present? && obj.will_save_change_to_lat? }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
