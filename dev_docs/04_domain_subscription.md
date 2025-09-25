
# 1) Modello & migrazione


bin/rails g model DomainSubscription user:references host:string title:string favicon_url:string subscribed_at:datetime

db/migrate/XXXXXXXXXXXX_create_domain_subscriptions.rb
ruby
Copia codice
class CreateDomainSubscriptions < ActiveRecord::Migration[7.2] # o tua versione
  def change
    create_table :domain_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :host, null: false
      t.string  :title
      t.string  :favicon_url
      t.datetime :subscribed_at, null: false
      t.timestamps
    end
    add_index :domain_subscriptions, [:user_id, :host], unique: true
  end
end






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
