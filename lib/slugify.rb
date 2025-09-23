# frozen_string_literal: true

# lib/slugify.rb
module Slugify
  DEFAULT_MAX = 80
  KEBAB_RE    = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  # Converte una stringa in uno slug kebab-case.
  #
  # Opzioni:
  #   max:          lunghezza massima (default 80)
  #   replacements: hash di sostituzioni extra, es. { "%" => " percento " }
  #   transliterate: abilita/disabilita translitterazione (default true)
  #
  # NOTE:
  # - non gestisce l'unicità (usa Slugify.unique)
  def self.call(str, max: DEFAULT_MAX, replacements: {}, transliterate: true)
    s = str.to_s

    # 0) Translitterazione accenti/simboli → ASCII
    if transliterate
      if defined?(ActiveSupport::Inflector) && ActiveSupport::Inflector.respond_to?(:transliterate)
        s = ActiveSupport::Inflector.transliterate(s)
      elsif defined?(I18n) && I18n.respond_to?(:transliterate)
        s = I18n.transliterate(s)
      else
        # Fallback: rimuove diacritici
        s = s.unicode_normalize(:nfd).gsub(/\p{Mn}/, "")
      end
    end

    # 1) Normalizza trattini tipografici in "-"
    # (‐ - ‒ – — ―) + eventuali sequenze
    s = s.gsub(/[‐-‒–—―]+/, "-")

    # 2) Normalizza simboli comuni (italiano)
    s = s.gsub(/[’'`]/, "")      # apostrofi
         .gsub("&",  " e ")
         .gsub(/\+/, " piu ")
         .gsub("@",  " at ")
         .gsub("%",  " percento ")
         .gsub("€",  " euro ")
         .gsub("/",  " ")

    # 3) Sostituzioni custom (prima di ripulire)
    replacements.each { |from, to| s = s.gsub(from, to) } if replacements && !replacements.empty?

    # 4) Solo a-z0-9, spazi e trattini; tutto minuscolo
    s = s.downcase
         .gsub(/[^a-z0-9\- ]/, " ")
         .strip
         .gsub(/[ _.]+/, "-")    # spazi/underscore/punti → trattino
         .gsub(/-+/, "-")        # comprime trattini multipli
         .gsub(/\A-+|-+\z/, "")  # toglie trattini ai bordi

    # 5) Troncamento “pulito”
    if s.length > max
      s = s[0, max]
      s = s.gsub(/-+\z/, "")     # evita taglio con trattino in coda
    end

    s.empty? ? "untitled" : s
  end

  # Verifica se uno slug è in kebab-case (a-z0-9 e trattini)
  def self.kebab?(slug)
    KEBAB_RE.match?(slug.to_s)
  end

  # Rende unico uno slug, apponendo suffissi -2, -3, ...
  #
  # Uso:
  #   Slugify.unique(Slugify.call(title)) { |slug| Model.exists?(slug: slug) }
  #
  # Opzioni:
  #   max: lunghezza massima finale (default 80)
  def self.unique(base, max: DEFAULT_MAX, &taken)
    # se non passo un block per verificare unicità, ritorno base
    return base unless block_given?

    slug = base
    n = 2
    while taken.call(slug)
      suffix  = "-#{n}"
      cut_len = [ max - suffix.length, 1 ].max
      base_cut = base[0, cut_len].gsub(/-+\z/, "") # evita trattino in coda
      slug = "#{base_cut}#{suffix}"
      n += 1
    end
    slug
  end
end
