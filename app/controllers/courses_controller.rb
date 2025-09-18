class CoursesController < ApplicationController
  # nessun auth
  allow_unauthenticated_access
  before_action :load_course

  def show
    @course_title   = @course["titolo"]
    @course_desc    = @course["description"]
    @course_cover   = @course["url_copertina"].to_s
    @course_video   = @course["url_video"].to_s
    @course_pdf     = @course["url_pdf"].to_s
    @lessons        = (@course["lessons"] || [])
  rescue CourseLoader::NotFound
    render plain: "Corso non trovato", status: :not_found
  end

  private
  def load_course
    slug = params[:slug]
    slug = "igiene_posturale" if slug == "igieneposturale"
    @course = CourseLoader.load_course!(slug)
    @course_slug = @course["slug"]
  end
  # def load_course
  #   slug = params[:slug]
  #   # alias: igieneposturale → igiene_posturale
  #   slug = "igiene_posturale" if slug == "igieneposturale"
  #   @course = CourseLoader.load_course!(slug)
  #   @course_slug = @course["slug"]
  # end
end
