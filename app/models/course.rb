# frozen_string_literal: true

class Course
  COURSES_ROOT = Rails.root.join("config/courses")

  attr_reader :slug, :titolo, :taxonomy_path, :entrypoint_hosts,
              :professional_roles, :pacchetti,
              :url_pdf, :url_video, :moduli_propedeutici,
              :lessons, :source_path, :mtime

  def initialize(attrs, taxonomy_path:, source_path:, mtime:)
    @slug   = attrs.fetch(:slug).to_s
    @titolo = attrs[:titolo].to_s

    @taxonomy_path = Array(taxonomy_path) # cartelle → ["flowpulse","salute",...]
    @source_path   = source_path
    @mtime         = mtime

    routing = attrs[:routing] || {}
    @entrypoint_hosts = Array(routing[:entrypoints]).flat_map { |e|
      # supporta sia {domain: "..."} che {domain: ["...", "..."]}
      v = e.is_a?(Hash) ? (e[:domain] || e["domain"]) : e
      Array(v)
    }.compact.map(&:to_s).uniq

    @professional_roles  = Array(attrs[:professional_roles]).map(&:to_s)
    @pacchetti           = Array(attrs[:pacchetti]).map { |p| p.deep_symbolize_keys }
    @url_pdf             = attrs[:url_pdf].to_s
    @url_video           = attrs[:url_video].to_s

    @moduli_propedeutici = Array(attrs[:moduli_propedeutici]).map { |m| m.deep_symbolize_keys }
    @lessons             = Array(attrs[:lessons]).map { |l| Lesson.new(self, l.deep_symbolize_keys) }
  end

  # ---------- Repository (file-based) ----------

  def self.all
    @all ||= begin
      Dir.glob(COURSES_ROOT.join("**/*.yml")).filter_map do |path|
        rel    = Pathname(path).relative_path_from(COURSES_ROOT)         # flowpulse/.../igiene_posturale.yml
        parts  = rel.each_filename.to_a
        next if parts.empty?

        taxonomy = parts[0..-2]                                          # cartelle senza filename
        data = YAML.safe_load(File.read(path), aliases: true)
        data = data.is_a?(Hash) ? data.deep_symbolize_keys : {}
        course_hash = data[:course]
        next unless course_hash

        new(course_hash,
            taxonomy_path: taxonomy,
            source_path: path,
            mtime: File.mtime(path))
      end
    end
  end

  def self.reload!
    @all = nil
    all
  end

  def self.find(slug)
    all.find { |c| c.slug == slug.to_s }
  end

  # Filtra per prefisso tassonomico (es. ["flowpulse","salute"])
  def self.where_taxonomy_prefix(prefix_segments)
    prefix = Array(prefix_segments).reject(&:blank?)
    return all if prefix.empty?
    all.select { |c| c.taxonomy_path[0, prefix.length] == prefix }
  end

  # ---------- Helper di dominio/URL ----------

  # Se entrypoints è vuoto → visibile ovunque
  def visible_on_host?(host)
    return true if entrypoint_hosts.blank?
    entrypoint_hosts.include?(host.to_s)
  end

  def preferred_host
    entrypoint_hosts.first
  end

  # Path canonico (piatto) o "annidato" per UX
  def path(nested: false)
    if nested && taxonomy_path.present?
      "/courses/#{(taxonomy_path + [ slug ]).join('/')}"
    else
      "/courses/#{slug}"
    end
  end

  # ---------- Navigazione interna ----------

  def lesson(slug_or_order)
    lessons.find { |l| l.slug == slug_or_order.to_s || l.order.to_s == slug_or_order.to_s }
  end
end
