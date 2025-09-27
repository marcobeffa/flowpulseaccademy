# config/initializers/domain_registry.rb
# frozen_string_literal: true

require "digest"

module DomainRegistry
  YAML_PATH ||= Rails.root.join("config/domains.yml")

  CATEGORIES       = %w[salute lavoro formazione].freeze
  DEFAULT_CATEGORY = "formazione"

  class << self
    # ----------------------------- Boot / Load -------------------------------

    def load!(force: false)
      return if !force && @loaded_sig.present? && @loaded_sig == yaml_signature

      raw = File.exist?(YAML_PATH) ? YAML.safe_load_file(YAML_PATH, aliases: false) : {}

      @services = index_by(raw.fetch("services", []), "key")
      @domains  = index_by(raw.fetch("domains",  []), "host")

      # alias → host base
      @alias_to_host = {}
      @domains.each_value do |d|
        Array(d["aliases"]).each { |a| @alias_to_host[a.downcase] = d["host"] }
      end

      # reset cache subdomini servizi
      @service_subdomains = nil

      validate!

      @loaded_sig = yaml_signature
      Rails.logger.info("[DomainRegistry] loaded sig=#{@loaded_sig}")
    rescue => e
      Rails.logger.error("[DomainRegistry] load error: #{e.class}: #{e.message}")
      raise e
    end

    # Dev: ricarica quando cambia lo YAML
    def setup_file_watcher!
      return if instance_variable_defined?(:@watcher_configured) && @watcher_configured
      return unless Rails.env.development?

      paths = [ YAML_PATH.to_s ]

      reloader = ActiveSupport::FileUpdateChecker.new(paths, {}) do
        Rails.logger.info("[DomainRegistry] YAML changed, reloading")
        load!(force: true)
      end

      ActiveSupport::Reloader.to_prepare { reloader.execute_if_updated }
      ActiveSupport::Reloader.to_run      { reloader.execute_if_updated }

      @watcher_configured = true
    end

    # ------------------------------ Accessors --------------------------------

    def services = @services || {}
    def domains  = @domains  || {}

    def service(key) = services[key.to_s]

    def each_domain(&blk) = domains.values.each(&blk)

    def all_hosts_for_domain(dom)
      [ dom["host"], *Array(dom["aliases"]) ].compact
    end

    def find_domain_by_host(host)
      h    = host.to_s.downcase
      base = domains[h] && h
      base ||= @alias_to_host[h]
      base ? domains[base] : nil
    end

    # Ritorna la config del dominio base anche se arrivi da un sottodominio.
    def match_base_domain_config(host)
      _sub, base = split_host(host)
      domains[base] || find_domain_by_host(host)
    end

    # "a.b.c" → ["a", "b.c"]; "b.c" → [nil, "b.c"]
    def split_host(host)
      parts = host.to_s.downcase.split(".")
      return [ nil, nil ] if parts.size < 2
      if parts.size >= 3
        [ parts.first, parts[1..].join(".") ]
      else
        [ nil, parts.join(".") ]
      end
    end

    # ------------------------------ Services ---------------------------------

    # insieme dei subdomain dei servizi (es. ["flowpulse"])
    def service_subdomains
      @service_subdomains ||= services.values.map { |s| s["subdomain"] }.compact.uniq
    end

    # true se key è una service key valida
    def service_key?(key) = services.key?(key.to_s)

    # è consentito montare il servizio "key" su questo host?
    def allow_service_host?(key, host)
      dom = match_base_domain_config(host)
      return false unless dom
      sub, base = split_host(host)
      return false unless sub && base == dom["host"]

      dom["active_services"].any? do |k|
        svc = service(k)
        svc && svc["subdomain"] == sub && k.to_s == key.to_s
      end
    end

    def all_service_hosts(key)
      k = key.to_s
      domains.values.filter_map do |dom|
        next unless dom["active_services"].include?(k)
        svc = service(k); next unless svc
        "#{svc['subdomain']}.#{dom['host']}"
      end
    end

    def active_service_keys_for(host)
      dom = domains[host.to_s] or return []
      dom["active_services"]
    end

    # ------------------------------- SEO -------------------------------------

    def seo_for(host)
      dom = match_base_domain_config(host)
      dom && dom["seo"]
    end

    # --------------------------- Flowpulse Home ------------------------------

    # Domini da mostrare nella home di Flowpulse
    def domains_for_flowpulse_home
      domains.values.select { |d| d["show_in_flowpulse_home"] }
    end

    # Domini raggruppati per categoria (ordine fisso: salute, lavoro, formazione)
    def grouped_domains_for_home
      list    = domains_for_flowpulse_home
      grouped = list.group_by { |d| d["category_flowpulse"] }
      CATEGORIES.index_with { |cat| grouped[cat] || [] }
    end

    # ----------------------------- Internals ---------------------------------

    private

    def yaml_signature
      return "absent" unless File.exist?(YAML_PATH)
      st = File.stat(YAML_PATH)
      Digest::SHA256.hexdigest("#{YAML_PATH}-#{st.size}-#{st.mtime.to_i}")
    end

    def index_by(list, key)
      list.to_h { |item| [ item.fetch(key).to_s, deep_stringify(item) ] }
    end

    def deep_stringify(obj)
      case obj
      when Hash  then obj.transform_keys(&:to_s).transform_values { |v| deep_stringify(v) }
      when Array then obj.map { |v| deep_stringify(v) }
      else obj
      end
    end

    def validate!
      # normalize domains
      @domains.each_value do |d|
        d["show_in_flowpulse_home"] = true if d["show_in_flowpulse_home"].nil?

        cat = d["category_flowpulse"].to_s.downcase
        d["category_flowpulse"] = CATEGORIES.include?(cat) ? cat : DEFAULT_CATEGORY

        d["active_services"] = Array(d["active_services"]).map(&:to_s)
      end

      # normalize services
      @services.each_value do |s|
        s["key"]         = s["key"].to_s
        s["subdomain"]   = s["subdomain"].to_s.presence
        s["data_source"] = s["data_source"].to_s.presence || "yml"
        s["yml_root"]    = nil unless s["data_source"] == "yml"
        s["db_table"]    = nil unless s["data_source"] == "db"
      end
    end
  end
end

Rails.application.config.to_prepare do
  DomainRegistry.load!
  DomainRegistry.setup_file_watcher!
end
