namespace :courses do
  desc "Normalizza '*-online-DD-MM-YYYY.yml' in ISO e sincronizza course.version (usa DRY_RUN=0 per eseguire)"
  task fix_dates: :environment do
    require "yaml"
    require "date"
    require "fileutils"

    root = Rails.root.join("config/courses")
    dry  = ENV["DRY_RUN"] != "0"
    n = 0

    Dir.glob(root.join("**/*-online-??-??-????.y{a,}ml")).each do |path|
      fname = File.basename(path)
      dir   = File.dirname(path)

      if (m = fname.match(/\A([a-z0-9-]+-online-)(\d{2}-\d{2}-\d{4})(\.ya?ml)\z/))
        prefix, euro, ext = m[1], m[2], m[3]
        dd, mm, yyyy = euro.split("-")
        iso = "#{yyyy}-#{mm}-#{dd}"
        newname = "#{prefix}#{iso}#{ext}"
        newpath = File.join(dir, newname)

        puts "#{fname}  →  #{newname}"
        unless dry
          FileUtils.mv(path, newpath)
          begin
            data = YAML.safe_load_file(newpath, aliases: false)
          rescue => e
            puts "  (warn) YAML non leggibile dopo rename: #{e.class}: #{e.message}"
            next
          end

          if data.is_a?(Hash)
            course = data["course"] || data[:course]
            # Se course.version era 'DD-MM-YYYY', portala a ISO
            if course
              cur_ver = course["version"] || course[:version]
              if cur_ver == euro
                course["version"] = iso
                File.write(newpath, YAML.dump(data))
                puts "  updated course.version → #{iso}"
              end
            end
          end
        end

        n += 1
      end
    end

    puts(dry ? "DRY RUN: rinominerei #{n} file." : "Fatto: rinominati #{n} file.")
  end
end


# vedere i task
# bin/rails -T | grep courses

# dry-run (default): mostra cosa farebbe, ma non tocca nulla
# bin/rails courses:fix_dates

# esegue davvero i rename/aggiornamenti
#  DRY_RUN=0 bin/rails courses:fix_dates
