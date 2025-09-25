0) Assunti rapidi

DomainRegistry già carica services e domains.

Servizi es.: onlinecourses (YML), questionnaire (DB), blog (DB).

C’è una colonna host nei record DB che vuoi indicizzare (es. posts.host, questionnaires.host). Se non c’è, dimmelo e ti faccio il mapping alternativo.

1) Migrazione + Model CatalogItem
bin/rails g migration CreateCatalogItems \
  host:string service_key:string slug:string title:string \
  source_type:string source_table:string source_id:bigint \
  yml_path:string version:string published_at:datetime status:string \
  data:jsonb


db/migrate/*_create_catalog_items.rb

class CreateCatalogItems < ActiveRecord::Migration[7.2]
  def change
    create_table :catalog_items do |t|
      t.string  :host,        null: false
      t.string  :service_key, null: false
      t.string  :slug,        null: false
      t.string  :title,       null: false
      t.string  :source_type, null: false    # "yml" | "db"
      t.string  :source_table
      t.bigint  :source_id
      t.string  :yml_path
      t.string  :version
      t.datetime :published_at
      t.string  :status                        # "draft" | "published" | ...
      t.jsonb   :data, default: {}
      t.timestamps
    end

    add_index :catalog_items, [:host, :service_key, :slug],
              unique: true, name: "idx_catalog_unique"
    add_index :catalog_items, [:source_table, :source_id]
    add_index :catalog_items, :host
    add_index :catalog_items, :service_key
    add_index :catalog_items, :slug
    add_index :catalog_items, :published_at
    add_index :catalog_items, :status
    add_index :catalog_items, :data, using: :gin
  end
end


app/models/catalog_item.rb

class CatalogItem < ApplicationRecord
  enum source_type: { yml: "yml", db: "db" }
  validates :host, :service_key, :slug, :title, :source_type, presence: true

  scope :for_brand,   ->(host) { where(host: host) }
  scope :for_service, ->(key)  { where(service_key: key.to_s) }
  scope :published,   ->       { where(status: "published") }
end

bin/rails db:migrate

2) Concern per i modelli DB → upsert automatico

app/models/concerns/catalog_indexable.rb

module CatalogIndexable
  extend ActiveSupport::Concern

  included do
    after_commit :catalog_upsert!,  on: [:create, :update]
    after_commit :catalog_delete!,  on: :destroy
  end

  # Override se i nomi/colonne differiscono:
  def catalog_host         = self.respond_to?(:host) ? self.host : nil
  def catalog_service_key  = self.class.name.underscore # override nei modelli
  def catalog_slug         = self.slug
  def catalog_title        = self.respond_to?(:title) ? self.title : self.slug
  def catalog_status       = self.respond_to?(:published?) && published? ? "published" : "draft"
  def catalog_published_at = self.try(:published_at) || self.try(:created_at)

  private

  def catalog_upsert!
    return if catalog_host.blank?
    CatalogItem.upsert(
      {
        host:         catalog_host,
        service_key:  catalog_service_key, # es. override -> "blog"
        slug:         catalog_slug,
        title:        catalog_title,
        source_type:  "db",
        source_table: self.class.table_name,
        source_id:    self.id,
        status:       catalog_status,
        published_at: catalog_published_at,
        data:         {}
      },
      unique_by: :idx_catalog_unique
    )
  end

  def catalog_delete!
    return if catalog_host.blank?
    CatalogItem.where(
      host:        catalog_host,
      service_key: catalog_service_key,
      slug:        catalog_slug
    ).delete_all
  end
end


Esempi:

# app/models/post.rb
class Post < ApplicationRecord
  include CatalogIndexable
  def catalog_service_key = "blog"           # mappa Posts → servizio blog
end

# app/models/questionnaire.rb
class Questionnaire < ApplicationRecord
  include CatalogIndexable
  def catalog_service_key = "questionnaire"  # mappa → servizio questionnaire
end


Appena salvi/aggiorni/cancelli un record, l’indice si allinea.

3) Indicizzatore YML → CatalogItem

app/services/catalog/indexer.rb

# frozen_string_literal: true
class Catalog::Indexer
  def self.run!(hosts: nil, service_keys: nil)
    hosts ||= DomainRegistry.domains.keys
    hosts.each do |host|
      dom = DomainRegistry.domains[host] or next
      keys = Array(dom["active_services"]).map(&:to_s)
      keys &= Array(service_keys).map(&:to_s) if service_keys.present?
      keys.each { |k| new(host:, service_key: k).index! }
    end
  end

  def initialize(host:, service_key:)
    @host = host
    @service_key = service_key.to_s
    @svc = DomainRegistry.service(@service_key)
  end

  def index!
    return unless @svc
    case @svc["data_source"]
    when "yml" then index_yml!
    when "db"  then index_db_full_sync! # opzionale: sync iniziale DB → CatalogItem
    end
  end

  private

  # -------- YML -------------------------------------------------------------
  def index_yml!
    root = @svc["yml_root"].presence || "config/courses"
    domain_key = @host.split(".").first # es "posturacorretta"
    base_dirs = find_base_dirs(root, domain_key)

    patterns = file_patterns(@service_key)
    upserts = []

    base_dirs.each do |base|
      Dir.glob(File.join(base, "**", "*.{yml,yaml}")).each do |path|
        fname = File.basename(path)
        slug, published_on = extract_slug_and_date(fname, patterns)
        next unless slug

        data  = YAML.safe_load_file(path, aliases: false) rescue {}
        title = extract_title_from_yaml(data, @service_key) || pretty_from_filename(fname)

        upserts << {
          host: @host, service_key: @service_key, slug: slug,
          title: title, source_type: "yml", yml_path: path.sub("#{Rails.root}/",""),
          version: data["spec_version"].to_s.presence, published_at: published_on,
          status: "published", data: data
        }
      end
    end

    upserts.each do |attrs|
      CatalogItem.upsert(attrs, unique_by: :idx_catalog_unique)
    end
  end

  def find_base_dirs(root, domain_key)
    abs_root = Rails.root.join(root).to_s
    return [] unless Dir.exist?(abs_root)
    dirs = []
    Dir.glob(File.join(abs_root, "**", "*")).each do |p|
      next unless File.directory?(p)
      name = File.basename(p)
      dirs << p if name.match?(/\A\d{2}[-_]#{Regexp.escape(domain_key)}\z/) || name == domain_key
    end
    dirs.uniq
  end

  def file_patterns(service_key)
    case service_key
    when "onlinecourses"
      [
        /\A(?<slug>[a-z0-9-]+)-online-(?<date>\d{4}-\d{2}-\d{2})\.ya?ml\z/,
        /\A(?<slug>[a-z0-9-]+)_onlinecourse_(?<date>\d{4}[_-]\d{2}[_-]\d{2})\.ya?ml\z/
      ]
    else
      [
        /\A(?<slug>[a-z0-9-]+)_#{Regexp.escape(service_key)}_(?<date>\d{4}[_-]\d{2}[_-]\d{2})\.ya?ml\z/
      ]
    end
  end

  def extract_slug_and_date(fname, regexes)
    regexes.each do |re|
      if (m = fname.match(re))
        date_s = m[:date].tr("_","-") rescue nil
        return [m[:slug], (Date.iso8601(date_s) rescue nil)]
      end
    end
    [nil, nil]
  end

  def extract_title_from_yaml(data, key)
    case key
    when "onlinecourses" then (data["course"] || {})["title"] rescue nil
    when "questionnaire" then (data["questionnaire"] || data["form"] || {})["title"] rescue nil
    else nil
    end
  end

  def pretty_from_filename(fname)
    fname.sub(/\.(ya?ml)\z/i, "")
         .sub(/-online-\d{4}-\d{2}-\d{2}\z/, "")
         .sub(/_[a-z]+_?\d{4}[_-]\d{2}[_-]\d{2}\z/i, "")
         .tr("_","-").tr("-", " ").strip.capitalize
  end

  # -------- DB (opzionale) --------------------------------------------------
  def index_db_full_sync!
    table = @svc["db_table"].to_s
    case [@service_key, table]
    when ["blog", "posts"]
      Post.where(host: @host).find_each do |p|
        CatalogItem.upsert({
          host: @host, service_key: "blog", slug: p.slug,
          title: p.title, source_type: "db", source_table: "posts", source_id: p.id,
          status: (p.respond_to?(:published?) && p.published? ? "published" : "draft"),
          published_at: (p.try(:published_at) || p.try(:created_at)),
          data: {}
        }, unique_by: :idx_catalog_unique)
      end
    when ["questionnaire", "questionnaires"]
      Questionnaire.where(host: @host).find_each do |q|
        CatalogItem.upsert({
          host: @host, service_key: "questionnaire", slug: q.slug,
          title: q.title, source_type: "db", source_table: "questionnaires", source_id: q.id,
          status: (q.respond_to?(:published?) && q.published? ? "published" : "draft"),
          published_at: (q.try(:published_at) || q.try(:created_at)),
          data: {}
        }, unique_by: :idx_catalog_unique)
      end
    else
      Rails.logger.info("[Catalog::Indexer] skip db full sync for #{@service_key}/#{table}")
    end
  end
end


Rake tasks (comode per sync manuale / CI):

# lib/tasks/catalog.rake
namespace :catalog do
  desc "Indicizza TUTTO (YML + DB full sync)"
  task sync: :environment do
    Catalog::Indexer.run!
    puts "Catalog indicizzato."
  end

  desc "Indicizza solo un brand"
  task :sync_brand, [:host] => :environment do |_, args|
    host = args[:host] or abort "usa: rake catalog:sync_brand[posturacorretta.org]"
    Catalog::Indexer.run!(hosts: [host])
    puts "Catalog indicizzato per #{host}."
  end
end

4) Job Solid Queue per sync

app/jobs/catalog_sync_job.rb

class CatalogSyncJob < ApplicationJob
  queue_as :default  # Solid Queue di solito usa :default

  def perform(hosts: nil, service_keys: nil)
    Catalog::Indexer.run!(hosts: hosts, service_keys: service_keys)
  end
end


Trigger (esempi):

# tutto
CatalogSyncJob.perform_later

# solo un brand
CatalogSyncJob.perform_later(hosts: ["posturacorretta.org"])

# solo un servizio
CatalogSyncJob.perform_later(service_keys: ["onlinecourses"])

5) Admin endpoint (facoltativo) per superadmin

Rotta

namespace :superadmin do
  post "catalog/sync",        to: "catalog#sync",       as: :catalog_sync
  post "catalog/:host/sync",  to: "catalog#sync_brand", as: :catalog_sync_brand
end

Controller


# app/controllers/superadmin/catalog_controller.rb
module Superadmin
  class CatalogController < BaseController
    before_action :authenticate_user!
    before_action :require_superadmin!

    def sync
      hosts        = params[:hosts].presence&.split(",")        # opzionale
      service_keys = params[:service_keys].presence&.split(",") # opzionale
      CatalogSyncJob.perform_later(hosts: hosts, service_keys: service_keys)
      redirect_back fallback_location: superadmin_root_path, notice: "Sync avviato."
    end

    def sync_brand
      host = params[:host].to_s.downcase
      return redirect_back(fallback_location: superadmin_root_path, alert: "Host sconosciuto") unless DomainRegistry.domains.key?(host)
      CatalogSyncJob.perform_later(hosts: [host])
      redirect_back fallback_location: superadmin_root_path, notice: "Sync avviato per #{host}."
    end
  end
end



Puoi mettere un bottone “Reindicizza” sulla pagina Flowpulse visibile solo ai superadmin:

<% if current_user&.superadmin? %>
  <%= button_to "Reindicizza tutto", admin_catalog_sync_path,
        method: :post, class: "px-3 py-2 text-sm rounded-lg border" %>
<% end %>

6) Helper URL per servizi (utile in dashboard)

app/helpers/services_helper.rb

module ServicesHelper
  def service_url_for(service_key, host:, path: nil, protocol: request&.protocol || "https://")
    svc = DomainRegistry.service(service_key) or return nil
    sub = svc["subdomain"] or return nil
    port = (request && request.port && ![80,443].include?(request.port)) ? ":#{request.port}" : ""
    base = "#{protocol}#{sub}.#{host}#{port}"
    path ? "#{base}/#{path.to_s.sub(%r{\A/+}, '')}" : base
  end
end


Esempio:

<%= link_to "Apri corso", service_url_for("onlinecourses", host: "posturacorretta.org", path: "onlinecourses/igiene-posturale") %>

7) Dashboard: usa l’indice

Se hai già la dashboard che ho proposto prima, sei a posto. Altrimenti, per “recenti”:

@recent_items = CatalogItem
                  .where(host: current_user.brand_subscriptions.select(:host))
                  .order(published_at: :desc, updated_at: :desc)
                  .limit(24)


Conteggi per brand/servizio:

@counts_by_host = CatalogItem.where(host: hosts).group(:host, :service_key).count

8) Operativo (flow)

Attiva brand (come abbiamo fatto → BrandSubscription).

Lato DB: aggiungi include CatalogIndexable ai modelli (es. Post/Questionnaire) e override catalog_service_key.

Lato YML: lancia rake catalog:sync (o il Job) per popolare i corsi ecc.

Dashboard legge da catalog_items e costruisce URL con service_url_for.