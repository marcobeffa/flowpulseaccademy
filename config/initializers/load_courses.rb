require "yaml"

# Percorso alla directory dei corsi attivi
COURSES_PATH = Rails.root.join("config", "courses")

# Carica tutti i file YAML nella cartella dei corsi (esclude 'archives/')
course_files = Dir.glob(COURSES_PATH.join("*.yml"))

CORSI_DATA = course_files.each_with_object({}) do |file_path, acc|
  basename = File.basename(file_path, ".yml") # es: "igiene_posturale_17_09_2025"
  begin
    acc[basename] = YAML.load_file(file_path).with_indifferent_access
  rescue Psych::SyntaxError => e
    Rails.logger.error "Errore nel parsing YAML: #{file_path} - #{e.message}"
  rescue => e
    Rails.logger.error "Errore generico nel caricamento corso #{file_path}: #{e.message}"
  end
end.freeze
