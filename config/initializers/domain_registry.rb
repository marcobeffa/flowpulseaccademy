# config/initializers/domain_registry.rb
# frozen_string_literal: true

# bin/rails domain:reload    # ricarica DomainRegistry
# bin/rails hub:bump

require "digest"

module DomainRegistry
  YAML_PATH ||= Rails.root.join("config/domains.yml")

  class << self
    def load!(force: false)
      return if !force && @loaded_sig.present? && @loaded_sig == yaml_signature

      raw = File.exist?(YAML_PATH) ? YAML.safe_load_file(YAML_PATH, aliases: false) : {}
      @services = index_by(raw.fetch("services", []), "key")
      @domains  = index_by(raw.fetch("domains",  []), "host")
      @alias_to_host = {}
      @domains.each_value do |d|
        (d["aliases"] || []).each { |a| @alias_to_host[a.downcase] = d["host"] }
      end
      validate!
      @loaded_sig = yaml_signature
      Rails.logger.info("[DomainRegistry] loaded sig=#{@loaded_sig}")
    rescue => e
      Rails.logger.error("[DomainRegistry] load error: #{e.class}: #{e.message}")
      raise e
    end

    # --- Accessors -----------------------------------------------------------
    def services; @services || {}; end
    def domains;  @domains  || {}; end

    def service(key)
      services[key.to_s]
    end

    def each_domain(&blk)
      domains.values.each(&blk)
    end

    def all_hosts_for_domain(dom)
      [ dom["host"], *Array(dom["aliases"]) ].compact
    end

    def find_domain_by_host(host)
      h = host.to_s.downcase
      base = domains[h] && h
      base ||= @alias_to_host[h]
      base ? domains[base] : nil
    end

    def match_base_domain_config(host)
      # restituisce il dominio base anche se arrivi da sottodominio
      sub, base = split_host(host)
      domains[base] || find_domain_by_host(host)
    end

    def split_host(host)
      parts = host.to_s.downcase.split(".")
      return [ nil, nil ] if parts.size < 2
      if parts.size >= 3
        sub = parts.first
        base = parts[1..].join(".")
        [ sub, base ]
      else
        [ nil, parts.join(".") ]
      end
    end

    # è consentito montare il servizio "key" su questo host?
    def allow_service_host?(key, host)
      dom = match_base_domain_config(host)
      return false unless dom
      sub, base = split_host(host)
      return false unless sub && base == dom["host"]
      Array(dom["active_services"]).map(&:to_s).any? do |k|
        svc = service(k); svc && svc["subdomain"] == sub
      end
    end

    def all_service_hosts(key)
      k = key.to_s
      domains.values.filter_map do |dom|
        next unless Array(dom["active_services"]).map(&:to_s).include?(k)
        svc = service(k); next unless svc
        "#{svc['subdomain']}.#{dom['host']}"
      end
    end

    def seo_for(host)
      dom = match_base_domain_config(host)
      dom && dom["seo"]
    end

    # --- Dev: ricarica quando cambia lo YAML --------------------------------
    # def setup_file_watcher!
    #   return if defined?(@watcher) && @watcher
    #   return unless Rails.env.development?
    #   @watcher = ActiveSupport::FileUpdateChecker.new([ YAML_PATH.to_s ], {}) do
    #     Rails.logger.info("[DomainRegistry] YAML changed, reloading")
    #     load!(force: true)
    #   end
    #   ActiveSupport::Reloader.to_prepare { @watcher.execute_if_updated }
    # end
    def setup_file_watcher!
      return if instance_variable_defined?(:@watcher_configured) && @watcher_configured
      return unless Rails.env.development?

      paths = [ YAML_PATH.to_s ]

      reloader = ActiveSupport::FileUpdateChecker.new(paths, {}) do
        Rails.logger.info("[DomainRegistry] YAML changed, reloading")
        load!(force: true)
      end

      # Esegui il check sia prima di ogni request (to_prepare) sia dopo il reload di codice (to_run)
      ActiveSupport::Reloader.to_prepare { reloader.execute_if_updated }
      ActiveSupport::Reloader.to_run      { reloader.execute_if_updated }

      # Flag per non registrare i callback più volte
      @watcher_configured = true
    end

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
      # spazio per validazioni (opzionali)
    end
  end
end

Rails.application.config.to_prepare do
  DomainRegistry.load!
  DomainRegistry.setup_file_watcher!
end

module DomainRoutes
  module_function
  # constraints per host multipli
  def domain_constraint_for_hosts(hosts)
    re = /\A(?:#{hosts.map { |h| Regexp.escape(h) }.join("|")})\z/
    ->(req) { req.host.match?(re) }
  end

  # constraints per servizio (monta solo sui host validi)
  def service_constraint(key)
    ->(req) { DomainRegistry.allow_service_host?(key, req.host) }
  end
end
