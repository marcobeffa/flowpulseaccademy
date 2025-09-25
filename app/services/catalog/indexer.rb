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
          title: title, source_type: "yml", yml_path: path.sub("#{Rails.root}/", ""),
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
        date_s = m[:date].tr("_", "-") rescue nil
        return [ m[:slug], (Date.iso8601(date_s) rescue nil) ]
      end
    end
    [ nil, nil ]
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
         .tr("_", "-").tr("-", " ").strip.capitalize
  end

  # -------- DB (opzionale) --------------------------------------------------
  def index_db_full_sync!
    table = @svc["db_table"].to_s
    case [ @service_key, table ]
    when [ "blog", "posts" ]
      Post.where(host: @host).find_each do |p|
        CatalogItem.upsert({
          host: @host, service_key: "blog", slug: p.slug,
          title: p.title, source_type: "db", source_table: "posts", source_id: p.id,
          status: (p.respond_to?(:published?) && p.published? ? "published" : "draft"),
          published_at: (p.try(:published_at) || p.try(:created_at)),
          data: {}
        }, unique_by: :idx_catalog_unique)
      end
    when [ "questionnaire", "questionnaires" ]
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
