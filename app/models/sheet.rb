# frozen_string_literal: true

class Sheet
  attr_reader :lesson, :slug, :type, :title, :description,
              :url_pdf, :url_video

  def initialize(lesson, attrs)
    @lesson = lesson
    @slug   = attrs.fetch(:slug).to_s
    @type   = attrs[:type].to_s

    raw_title = attrs[:title]
    @title = raw_title.present? ? raw_title.to_s : @slug.to_s.humanize

    @description = attrs[:description] # può essere String o Array (la view gestisce entrambi)

    @url_pdf   = attrs[:url_pdf].to_s
    @url_video = attrs[:url_video].to_s
  end

  def description_list?
    description.is_a?(Array)
  end
end
