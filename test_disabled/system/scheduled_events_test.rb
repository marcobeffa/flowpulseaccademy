require "application_system_test_case"

class ScheduledEventsTest < ApplicationSystemTestCase
  setup do
    @scheduled_event = scheduled_events(:one)
  end

  test "visiting the index" do
    visit scheduled_events_url
    assert_selector "h1", text: "Scheduled events"
  end

  test "should create scheduled event" do
    visit scheduled_events_url
    click_on "New scheduled event"

    fill_in "Contact", with: @scheduled_event.contact_id
    fill_in "End at", with: @scheduled_event.end_at
    fill_in "Lesson slug", with: @scheduled_event.lesson_slug
    fill_in "Note", with: @scheduled_event.note
    fill_in "Start at", with: @scheduled_event.start_at
    fill_in "Training course", with: @scheduled_event.training_course_id
    click_on "Create Scheduled event"

    assert_text "Scheduled event was successfully created"
    click_on "Back"
  end

  test "should update Scheduled event" do
    visit scheduled_event_url(@scheduled_event)
    click_on "Edit this scheduled event", match: :first

    fill_in "Contact", with: @scheduled_event.contact_id
    fill_in "End at", with: @scheduled_event.end_at.to_s
    fill_in "Lesson slug", with: @scheduled_event.lesson_slug
    fill_in "Note", with: @scheduled_event.note
    fill_in "Start at", with: @scheduled_event.start_at.to_s
    fill_in "Training course", with: @scheduled_event.training_course_id
    click_on "Update Scheduled event"

    assert_text "Scheduled event was successfully updated"
    click_on "Back"
  end

  test "should destroy Scheduled event" do
    visit scheduled_event_url(@scheduled_event)
    accept_confirm { click_on "Destroy this scheduled event", match: :first }

    assert_text "Scheduled event was successfully destroyed"
  end
end
