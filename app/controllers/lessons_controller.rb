class LessonsController < ApplicationController
  allow_unauthenticated_access
  before_action :load_course
  before_action :load_lesson


  def show; end

  private

  def load_course
    course_slug = params[:course_slug] || params[:course_id] || params[:course_slug] || params[:slug]
    course_slug = "igiene_posturale" if course_slug == "igieneposturale"
    @course = CourseLoader.load_course!(course_slug)
  rescue CourseLoader::NotFound
    render plain: "Corso non trovato", status: :not_found
  end

  def load_lesson
    slug = params[:slug]
    @lesson = (@course["lessons"] || []).find { |l| l["slug"] == slug }
    return if @lesson.present?
    render plain: "Lezione non trovata", status: :not_found
  end
end
