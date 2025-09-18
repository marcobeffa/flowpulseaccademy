# frozen_string_literal: true

class Lesson
  attr_reader :course, :slug, :title, :order, :description,
              :url_pdf, :url_video, :sheets

  def initialize(course, attrs)
    @course      = course
    @slug        = attrs.fetch(:slug).to_s
    @title       = attrs[:title].to_s
    @order       = attrs[:order]
    @description = (attrs[:description].is_a?(String) || attrs[:description].nil?) ? attrs[:description].to_s : attrs[:description]
    @url_pdf     = attrs[:url_pdf].to_s
    @url_video   = attrs[:url_video].to_s
    @sheets      = Array(attrs[:sheets]).map { |s| Sheet.new(self, s.deep_symbolize_keys) }
  end

  def sheet(slug)
    sheets.find { |s| s.slug == slug.to_s }
  end
end
