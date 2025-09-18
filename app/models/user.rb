class User < ApplicationRecord
  has_secure_password

  # === associazione contact obbligatoria lato app ===
  has_one :contact, dependent: :nullify, inverse_of: :user

  has_many :sessions, dependent: :destroy

  accepts_nested_attributes_for :contact, update_only: true
  validates :contact, presence: true

  # crea un contact se manca (compatibile con email_address del generator)
  before_validation :ensure_contact!, on: :create

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  def superadmin?
    superadmin
  end
  private

  def ensure_contact!
    return if contact.present?


    build_contact(
      nome:  nome.presence  || "Nome",
      cognome: cognome.presence || "Cognome",
      email: email_address.presence || "#{SecureRandom.hex(4)}@example.invalid",
      tipo_utente: 0
    )
  end
end
