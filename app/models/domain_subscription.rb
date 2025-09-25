class DomainSubscription < ApplicationRecord
  belongs_to :user
  validates :host, presence: true
  validate  :host_must_exist_in_registry

  before_validation :normalize
  before_validation :set_defaults, on: :create

  def domain
    DomainRegistry.domains[host]
  end

  private

  def normalize
    self.host = host.to_s.downcase.strip
  end

  def set_defaults
    self.subscribed_at ||= Time.current
    if (dom = domain)
      self.title       ||= dom.dig("seo", "title") || dom["host"]
      self.favicon_url ||= dom["favicon_url"]
    end
  end

  def host_must_exist_in_registry
    errors.add(:host, "non è un dominio valido") unless DomainRegistry.domains.key?(host.to_s)
  end
end
