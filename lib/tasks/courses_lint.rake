# lib/tasks/courses_lint.rake
namespace :courses do
  desc "Lint tassonomia e slug (kebab-case, unicità, struttura + versioni online)"
  task lint: :environment do
    require "yaml"
    require "date"
    require "pathname"

    module CoursesLint
      module_function

      # solo a-z0-9 con gruppi separati da '-', niente underscore/spazi/accénti
      def kebab?(name)
        !!(name =~ /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)
      end

      # dir = ".../01-igiene-posturale/"
      def package_dir_info(dirpath)
        base = File.basename(dirpath.to_s.chomp("/"))
        m = base.match(/\A(?<idx>\d{2})-(?<slug>[a-z0-9]+(?:-[a-z0-9]+)*)\z/)
        m && { order_index: m[:idx].to_i, slug: m[:slug], base: base }
      end

      # accetta "slug-online-YYYY-MM-DD.yml" oppure "slug-online-DD-MM-YYYY.yml"
      # ritorna [iso_date_string, :iso|:euro] oppure nil
      def online_version_from_filename(filename)
        if (m = filename.match(/\A[a-z0-9-]+-online-(\d{4}-\d{2}-\d{2})\.ya?ml\z/))
          [ m[1], :iso ]
        elsif (m = filename.match(/\A[a-z0-9-]+-online-(\d{2}-\d{2}-\d{4})\.ya?ml\z/))
          dd, mm, yyyy = m[1].split("-")
          [ "#{yyyy}-#{mm}-#{dd}", :euro ]
        else
          nil
        end
      end

      # estrae la parte prima di "-online-"
      def file_slug_from_online(filename)
        filename.sub(/-online-.*\z/, "").sub(/\.(ya?ml)\z/, "")
      end

      def valid_iso_date!(iso_date)
        Date.iso8601(iso_date)
        true
      rescue
        false
      end
    end

    root  = Rails.root.join("config/courses")
    bad   = []  # errori bloccanti
    warnn = []  # avvisi

    seen  = Hash.new(0)          # conteggio slug pacchetto (canonico)
    versions_by_pkg  = Hash.new { |h, k| h[k] = [] }  # pkg_rel => [iso_dates]
    parent_indexes   = Hash.new { |h, k| h[k] = [] }  # parent_rel => [NN]

    # 1) Naming kebab-case su file/dir (ignora nascosti e directory base)
    Dir.glob(root.join("**/*"), File::FNM_DOTMATCH).each do |path|
      rel  = Pathname(path).relative_path_from(root).to_s
      name = File.basename(path)
      next if name == "." || name == ".."
      next if name.start_with?(".") # ignora nascosti (.DS_Store, .keep, ...)

      if File.directory?(path)
        # se è pacchetto, deve rispettare NN-slug; altrimenti kebab-case libero
        if CoursesLint.package_dir_info(path)
          # ok
        else
          bad << "Cartella non kebab-case o nome non valido: #{rel}" unless CoursesLint.kebab?(name) || name.match?(/\A\d{2}-[a-z0-9-]+\z/)
        end
      else
        # file: consentiti solo kebab-case + .yml|.yaml
        unless name =~ /\A[a-z0-9\-]+\.ya?ml\z/
          bad << "File non kebab-case o estensione non valida: #{rel}"
        end
      end
    end

    # 2) Identifica cartelle pacchetto e validazione contenuto online
    Dir.glob(root.join("**/*/")).each do |dir|
      rel  = Pathname(dir).relative_path_from(root).to_s
      info = CoursesLint.package_dir_info(dir)
      next unless info # non è pacchetto

      canonical_slug = info[:slug]
      seen[canonical_slug] += 1

      # univocità NN tra fratelli
      parent_key = Pathname(dir).parent.relative_path_from(root).to_s
      parent_indexes[parent_key] << info[:order_index]

      # cerca file online
      online_files = Dir.glob(File.join(dir, "*-online-*.yml")) + Dir.glob(File.join(dir, "*-online-*.yaml"))
      if online_files.empty?
        bad << "Manca file online in pacchetto #{rel} (atteso: #{canonical_slug}-online-YYYY-MM-DD.yml)"
        next
      end

      # valida naming versione e YAML base
      online_files.each do |file|
        fname = File.basename(file)

        v = CoursesLint.online_version_from_filename(fname)
        if v.nil?
          bad << "Nome file online non conforme (usa #{canonical_slug}-online-YYYY-MM-DD.yml): #{rel}/#{fname}"
          next
        end
        iso_date, fmt = v
        warnn << "Versione online in formato DD-MM-YYYY: #{rel}/#{fname} → normalizzata a #{iso_date}" if fmt == :euro

        unless CoursesLint.valid_iso_date!(iso_date)
          bad << "Data non valida nel nome file: #{rel}/#{fname}"
        end

        file_slug = CoursesLint.file_slug_from_online(fname)
        if file_slug != canonical_slug
          bad << "Slug file '#{file_slug}' ≠ cartella '#{canonical_slug}' in #{rel}/#{fname}"
        end

        begin
          data = YAML.safe_load_file(file, aliases: false)
        rescue => e
          bad << "YAML non valido: #{rel}/#{fname} (#{e.class}: #{e.message})"
          next
        end

        # Struttura minima attesa
        course = (data["course"] || data[:course])
        online = (data["online"] || data[:online])
        specv  = (data["spec_version"] || data[:spec_version])

        bad << "Manca chiave 'course' in #{rel}/#{fname}" unless course
        bad << "Manca chiave 'online' in #{rel}/#{fname}" unless online
        bad << "Manca 'spec_version' in #{rel}/#{fname}" unless specv

        if course
          yslug = (course["slug"] || course[:slug])
          if yslug && yslug != canonical_slug
            bad << "Mismatch slug: cartella=#{canonical_slug} vs course.slug=#{yslug} in #{rel}/#{fname}"
          end

          yver = (course["version"] || course[:version])
          warnn << "Suggerito impostare course.version='#{iso_date}' in #{rel}/#{fname}" unless yver
          warnn << "course.version (#{yver}) ≠ file version (#{iso_date}) in #{rel}/#{fname}" if yver && yver.to_s != iso_date.to_s
        end

        # lezioni: array + slug kebab-case unici
        if online
          lessons = (online["lessons"] || online[:lessons])
          unless lessons.is_a?(Array)
            bad << "Chiave 'online.lessons' non è un array in #{rel}/#{fname}"
          else
            slugs = lessons.map { |ls| (ls["slug"] || ls[:slug]).to_s }
            dup = slugs.group_by(&:itself).select { |_s, a| a.size > 1 }.keys
            bad << "Slug lezioni duplicati: #{dup.join(', ')} (#{rel}/#{fname})" if dup.any?

            slugs.each_with_index do |lslug, i|
              bad << "Lezione ##{i+1} con slug mancante in #{rel}/#{fname}" if lslug.empty?
              bad << "Lezione ##{i+1} slug non kebab-case: #{lslug} (#{rel}/#{fname})" unless lslug.empty? || CoursesLint.kebab?(lslug)
            end
          end
        end

        versions_by_pkg[rel] << iso_date if iso_date
      end
    end

    # 3) Duplicati slug pacchetto (canonici)
    dups = seen.select { |_, c| c > 1 }.keys
    bad << "Duplicati slug di pacchetto (canonici): #{dups.join(', ')}" unless dups.empty?

    # 4) NN duplicati tra fratelli
    parent_indexes.each do |parent, idxs|
      dup_nn = idxs.group_by(&:itself).select { |_n, a| a.size > 1 }.keys
      bad << "Indice NN duplicato in cartella #{parent.presence || '.'}: #{dup_nn.join(', ')}" if dup_nn.any?
    end

    # 5) Più versioni online nello stesso pacchetto → avviso
    versions_by_pkg.each do |pkg, dates|
      if dates.size > 1
        warnn << "Più versioni 'online' in #{pkg}: #{dates.sort.join(', ')} → usa la più recente (#{dates.max})"
      end
    end

    # Report
    if warnn.any?
      puts "AVVISI:"
      warnn.each { |m| puts " - #{m}" }
      puts
    end

    if bad.empty?
      puts "OK: tassonomia e slug coerenti."
    else
      puts "ERRORI:"
      bad.each { |m| puts " - #{m}" }
      abort "Lint fallito (vedi messaggi sopra)."
    end
  end
end
