# app/controllers/sheets_controller.rb
class SheetsController < ApplicationController
  def show
    @course = Course.find(params[:course_id])
    return redirect_to(courses_path, alert: "Corso non trovato") unless @course

    @lesson = @course.lesson(params[:lesson_id])
    return redirect_to(course_path(@course.slug), alert: "Lezione non trovata") unless @lesson

    @sheet = @lesson.sheet(params[:id])
    redirect_to(course_lesson_path(@course.slug, @lesson.slug), alert: "Scheda non trovata") unless @sheet
  end
end
