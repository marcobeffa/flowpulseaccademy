# app/models/course_loader.rb
# frozen_string_literal: true

class CourseLoader
  ROOTS = [
    Rails.root.join("config", "courses"),
    Rails.root.join("courses")
  ].freeze

  class NotFound < StandardError; end

  def self.load_course!(slug)
    found = find_course_yaml(slug)
    raise NotFound, "Course YAML not found for #{slug}" unless found

    path, root = found
    data = YAML.safe_load(File.read(path), aliases: true) || {}
    course = data["course"] || {}

    # Ordina lezioni
    if course["lessons"].is_a?(Array)
      course["lessons"] = course["lessons"].sort_by { |l| l["order"].to_i }
    end

    # Metadati utili
    course["_source_path"] = path.to_s

    # Taxonomy fallback dalle cartelle se mancante
    if course["taxonomy_path"].blank?
      rel = Pathname(path).dirname.to_s.sub(/^#{Regexp.escape(root.to_s)}\/?/, "")
      segments = rel.split(File::SEPARATOR).reject(&:blank?)
      course["taxonomy_path"] = segments unless segments.empty?
    end

    course
  end

 def self.find_course_yaml(slug)
  return nil if slug.blank?

  patterns = [
    slug,
    slug.tr("_", "-"),
    slug.delete("_"),
    slug.tr("_", " ") # nel caso avessi file con spazi
  ].uniq

    ROOTS.each do |root|
      files = Dir.glob(root.join("**", "*.yml"))
      hit = files.find do |f|
        fname = File.basename(f).downcase
        patterns.any? { |p| fname.include?(p.downcase) }
      end
      return [ hit, root ] if hit
    end

    nil
  end
end
