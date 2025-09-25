class User < ApplicationRecord
  has_secure_password

  # === associazione lead obbligatoria lato app ===
  has_one :lead, dependent: :nullify, inverse_of: :user

  has_many :sessions, dependent: :destroy

  has_many :domain_subscriptions, dependent: :destroy

  accepts_nested_attributes_for :lead, update_only: true
  validates :lead, presence: true

  # crea un lead manca (compatibile con email_address del generator)
  before_validation :ensure_lead, on: :create

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  def superadmin?
    superadmin
  end

  def subscribed_to?(host_or_req)
    host = if host_or_req.is_a?(String)
      host_or_req
    else
      DomainRegistry.match_base_domain_config(host_or_req.try(:host))&.dig("host")
    end
    return false if host.blank?
    domain_subscriptions.exists?(host: host)
  end

  # per comodo: lista dei domini (oggetti del registry) sottoscritti
  def subscribed_domains
    domain_subscriptions.map { |s| DomainRegistry.domains[s.host] }.compact
  end
  private

  def ensure_lead!
    return if lead.present?


    build_lead(
      nome:  nome.presence  || "Nome",
      cognome: cognome.presence || "Cognome",
      email: email_address.presence || "#{SecureRandom.hex(4)}@example.invalid",
      tipo_utente: 0
    )
  end
end
