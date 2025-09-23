# app/services/services/hub_index.rb
# frozen_string_literal: true

require "digest"


  class HubIndex
    FOLDER_RE = /\A(?<nn>\d{2})[-_](?<slug>[a-z0-9][a-z0-9\-_]*)\z/

    def initialize(domain_key:, active_keys:, roots:)
      @domain_key  = domain_key
      @active_keys = active_keys.map!(&:to_s)
      @roots       = roots.uniq
    end

    def fetch
      Rails.cache.fetch(cache_key, **cache_opts) { build_payload }
    end

    private

    def cache_key
      # usa una versione globale (bumpabile) + dominio + servizi
      "hub:v2:#{HubCache.version}:#{@domain_key}:#{@active_keys.sort.join(',')}"
    end

    def cache_opts
      if Rails.env.development?
        { expires_in: 30.seconds, race_condition_ttl: 5 }
      else
        { expires_in: 10.minutes, race_condition_ttl: 5 }
      end
    end

    def build_payload
      folders = []
      cards   = []
      scanned = []

      base_dirs = find_domain_base_dirs
      base_dirs.each do |base_dir|
        scanned << base_dir

        # menu cartelle (figli NN_slug)
        Dir.children(base_dir)
          .select { |n| File.directory?(File.join(base_dir, n)) && !n.start_with?(".") }
          .each do |name|
            if (m = name.match(FOLDER_RE))
              folders << {
                nn:   m[:nn].to_i,
                slug: normalize(m[:slug]),
                name: humanize(m[:slug]),
                raw:  name,
                root: base_dir
              }
            end
          end

        # file .yml/.yaml ricorsivi
        matchers = file_matchers(@active_keys)
        Dir.glob(File.join(base_dir, "**", "*.{yml,yaml}")).each do |path|
          fname = File.basename(path)
          svc_key, date_s = service_and_date_from(fname, matchers)
          next unless svc_key && active_aliases.include?(svc_key)

          meta = extract_meta(path)
          if (card = build_card(path: path, fname: fname, svc_key: svc_key, date_s: date_s, meta: meta))
            cards << card
          end
        end
      end

      folders.uniq! { |f| [ f[:nn], f[:raw], f[:root] ] }
      folders.sort_by! { |h| [ h[:root], h[:nn] ] }
      cards.sort_by! { |c| [ c[:service], c[:date] || Date.new(1900, 1, 1) ] }.reverse!

      { folders: folders, cards: cards, scanned: scanned }
    end

    # --- helpers -------------------------------------------------------------

    def roots_existing
      @roots.select { |r| Dir.exist?(r) }
    end

    def domain_dir_name?(name)
      name.match?(/\A\d{2}[-_]#{Regexp.escape(@domain_key)}\z/)
    end

    def find_domain_base_dirs
      dirs = []
      roots_existing.each do |root|
        Dir.glob(File.join(root, "**", "*")).each do |path|
          next unless File.directory?(path)
          name = File.basename(path)
          dirs << path if domain_dir_name?(name)
        end
        # fallback root/<domain_key>
        candidate = File.join(root, @domain_key)
        dirs << candidate if Dir.exist?(candidate)
      end
      dirs.uniq
    end

    def active_aliases
      @active_aliases ||= @active_keys.map { |k| service_alias(k) }.uniq
    end

    def file_matchers(active_service_keys)
      services_alt = active_service_keys.flat_map { |k| [ k, service_alias(k) ] }.compact.uniq
      [
        [ /^-online-(\d{4}-\d{2}-\d{2})\.ya?ml$/i, :dash ], # slug-online-YYYY-MM-DD.yml -> onlinecourses
        [ /_((#{services_alt.join('|')}))_(\d{4}[_-]\d{2}[_-]\d{2})\.ya?ml$/i, :underscore ]
      ]
    end

    def service_alias(key)
      k = key.to_s
      return "onlinecourses" if k == "onlinecourse"
      k
    end

    def service_and_date_from(fname, matchers)
      matchers.each do |(re, kind)|
        if (md = fname.match(re))
          return [ "onlinecourses", md[1] ] if kind == :dash
          return [ service_alias(md[2]), md[3].tr("_", "-") ]
        end
      end
      nil
    end

    def normalize(s) = s.to_s.tr("_", "-")
    def humanize(s)  = normalize(s).tr("-", " ").gsub(/\b\w/) { _1.upcase }

    def extract_meta(path)
      data = YAML.safe_load_file(path, aliases: false) rescue nil
      return {} unless data.is_a?(Hash)
      course = data["course"] || data[:course]
      form   = data["form"]   || data[:form]   || data["questionnaire"] || data[:questionnaire]

      if course
        { title: course["title"] || course[:title], slug: course["slug"] || course[:slug], kind: "course" }
      elsif form
        { title: form["title"] || form[:title] || form["name"] || form[:name], slug: form["slug"] || form[:slug], kind: "form" }
      else
        {}
      end
    end

    def build_card(path:, fname:, svc_key:, date_s:, meta:)
      title = meta[:title] || pretty_from_filename(fname)
      slug  = meta[:slug]
      {
        service: svc_key,
        title:   title.to_s.presence || "(senza titolo)",
        slug:    slug,
        url:     card_url_for(svc_key, slug),
        date:    parse_date(date_s),
        file:    path
      }
    end

    def pretty_from_filename(fname)
      base = fname.sub(/\.(ya?ml)\z/i, "")
      base = base.sub(/-online-\d{4}-\d{2}-\d{2}\z/, "")
      base = base.sub(/_[a-z]+_?\d{4}[_-]\d{2}[_-]\d{2}\z/i, "")
      base.tr("_", "-").tr("-", " ").strip.capitalize
    end

    def parse_date(s)
      return nil if s.blank?
      s = s.tr("_", "-")
      Date.iso8601(s) rescue nil
    end

    def card_url_for(svc_key, slug)
      case svc_key.to_s
      when "onlinecourses"
        return nil if slug.blank?
        Rails.application.routes.url_helpers.onlinecourses_course_path(slug: slug.to_s.tr("_", "-"))
      when "questionnaire"
        h = Rails.application.routes.url_helpers
        if slug.present? && h.respond_to?(:questionnaire_form_path)
          return h.questionnaire_form_path(slug.to_s)
        end
        h.respond_to?(:questionnaire_forms_path) ? h.questionnaire_forms_path : "/questionnaire"
      else
        "/#{svc_key}"
      end
    rescue
      "/#{svc_key}"
    end
  end
