class TrainingCoursesController < ApplicationController
  before_action :set_training_course, only: %i[ show edit update destroy ]

  # GET /training_courses or /training_courses.json
  def index
    @training_courses = TrainingCourse.all
  end

  # GET /training_courses/1 or /training_courses/1.json
  def show
  end

  # GET /training_courses/new
  def new
    @training_course = TrainingCourse.new
  end

  # GET /training_courses/1/edit
  def edit
  end

  # POST /training_courses or /training_courses.json
  def create
    @training_course = TrainingCourse.new(training_course_params)

    respond_to do |format|
      if @training_course.save
        format.html { redirect_to @training_course, notice: "Training course was successfully created." }
        format.json { render :show, status: :created, location: @training_course }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @training_course.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /training_courses/1 or /training_courses/1.json
  def update
    respond_to do |format|
      if @training_course.update(training_course_params)
        format.html { redirect_to @training_course, notice: "Training course was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @training_course }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @training_course.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /training_courses/1 or /training_courses/1.json
  def destroy
    @training_course.destroy!

    respond_to do |format|
      format.html { redirect_to training_courses_path, notice: "Training course was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_training_course
      @training_course = TrainingCourse.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def training_course_params
      params.expect(training_course: [ :course_slug, :registrations_open_at, :registrations_close_at, :package_slug, :tutor_role_id, :teacher_role_id, :trainee_role_id, :venue_manager_role_id, :location_name, :location_address, :location_gmaps, :lat, :lng, :location_phone, :participants_count ])
    end
end
