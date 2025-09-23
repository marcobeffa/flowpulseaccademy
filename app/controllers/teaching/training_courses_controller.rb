module Teaching
  class TrainingCoursesController < BaseController
    def index
      # TODO: carica i corsi reali; intanto uno stub per verificare la route
      @courses = []
      respond_to do |format|
        format.html # render app/views/teaching/training_courses/index.html.erb (se esiste)
        format.json { render json: { ok: true, courses: @courses } }
        format.any  { render plain: "Teaching#index OK" }
      end
    end

    def show
      @slug = params[:slug]
      respond_to do |format|
        format.html
        format.json { render json: { ok: true, slug: @slug } }
        format.any  { render plain: "Teaching#show #{@slug}" }
      end
    end
  end
end
