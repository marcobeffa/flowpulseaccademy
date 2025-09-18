# app/helpers/courses_helper.rb
module CoursesHelper
  def resource_links(url_content:, url_video:, url_pdf:)
    items = []
    items << link_to("Contenuti", url_content, target: "_blank", rel: "noopener") if url_content.present?
    items << link_to("Video",     url_video,   target: "_blank", rel: "noopener") if url_video.present?
    items << link_to("PDF",       url_pdf,     target: "_blank", rel: "noopener") if url_pdf.present?
    safe_join(items, " · ".html_safe)
  end

  def type_badge(text)
    return if text.blank?
    content_tag :span, text.to_s.humanize,
      class: "inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ring-1 ring-inset
              bg-slate-50 text-slate-700 ring-slate-200"
  end
end
