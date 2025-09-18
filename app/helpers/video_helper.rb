module VideoHelper
  def youtube_iframe(url, css: "w-full aspect-video rounded-xl shadow")
    return if url.blank?
    vid = extract_youtube_id(url)
    return if vid.blank?
    content_tag(:div, class: css) do
      content_tag(:iframe, "", src: "https://www.youtube.com/embed/#{vid}",
                  title: "YouTube video player", frameborder: 0,
                  allow: "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share",
                  allowfullscreen: true)
    end
  end

  private

  def extract_youtube_id(url)
    return if url.blank?
    uri = URI.parse(url) rescue nil
    return if uri.nil?
    if uri.host&.include?("youtu.be")
      uri.path.delete_prefix("/")
    elsif uri.host&.include?("youtube.com")
      Rack::Utils.parse_query(uri.query)["v"]
    end
  end
end
