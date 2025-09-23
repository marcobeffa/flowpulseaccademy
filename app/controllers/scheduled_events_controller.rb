class ScheduledEventsController < ApplicationController
  before_action :set_scheduled_event, only: %i[ show edit update destroy ]

  # GET /scheduled_events or /scheduled_events.json
  def index
    @scheduled_events = ScheduledEvent.all
  end

  # GET /scheduled_events/1 or /scheduled_events/1.json
  def show
  end

  # GET /scheduled_events/new
  def new
    @scheduled_event = ScheduledEvent.new
  end

  # GET /scheduled_events/1/edit
  def edit
  end

  # POST /scheduled_events or /scheduled_events.json
  def create
    @scheduled_event = ScheduledEvent.new(scheduled_event_params)

    respond_to do |format|
      if @scheduled_event.save
        format.html { redirect_to @scheduled_event, notice: "Scheduled event was successfully created." }
        format.json { render :show, status: :created, location: @scheduled_event }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @scheduled_event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /scheduled_events/1 or /scheduled_events/1.json
  def update
    respond_to do |format|
      if @scheduled_event.update(scheduled_event_params)
        format.html { redirect_to @scheduled_event, notice: "Scheduled event was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @scheduled_event }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @scheduled_event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /scheduled_events/1 or /scheduled_events/1.json
  def destroy
    @scheduled_event.destroy!

    respond_to do |format|
      format.html { redirect_to teaching_training_courses_path, notice: "Scheduled event was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_scheduled_event
      @scheduled_event = ScheduledEvent.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def scheduled_event_params
      params.expect(scheduled_event: [ :contact_id, :training_course_id, :lesson_slug, :start_at, :end_at, :note ])
    end
end
