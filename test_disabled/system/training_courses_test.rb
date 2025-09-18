require "application_system_test_case"

class TrainingCoursesTest < ApplicationSystemTestCase
  setup do
    @training_course = training_courses(:one)
  end

  test "visiting the index" do
    visit training_courses_url
    assert_selector "h1", text: "Training courses"
  end

  test "should create training course" do
    visit training_courses_url
    click_on "New training course"

    fill_in "Course slug", with: @training_course.course_slug
    fill_in "Lat", with: @training_course.lat
    fill_in "Lng", with: @training_course.lng
    fill_in "Location address", with: @training_course.location_address
    fill_in "Location gmaps", with: @training_course.location_gmaps
    fill_in "Location name", with: @training_course.location_name
    fill_in "Location phone", with: @training_course.location_phone
    fill_in "Package slug", with: @training_course.package_slug
    fill_in "Participants count", with: @training_course.participants_count
    fill_in "Registrations close at", with: @training_course.registrations_close_at
    fill_in "Registrations open at", with: @training_course.registrations_open_at
    fill_in "Teacher role", with: @training_course.teacher_role_id
    fill_in "Trainee role", with: @training_course.trainee_role_id
    fill_in "Tutor role", with: @training_course.tutor_role_id
    fill_in "Venue manager role", with: @training_course.venue_manager_role_id
    click_on "Create Training course"

    assert_text "Training course was successfully created"
    click_on "Back"
  end

  test "should update Training course" do
    visit training_course_url(@training_course)
    click_on "Edit this training course", match: :first

    fill_in "Course slug", with: @training_course.course_slug
    fill_in "Lat", with: @training_course.lat
    fill_in "Lng", with: @training_course.lng
    fill_in "Location address", with: @training_course.location_address
    fill_in "Location gmaps", with: @training_course.location_gmaps
    fill_in "Location name", with: @training_course.location_name
    fill_in "Location phone", with: @training_course.location_phone
    fill_in "Package slug", with: @training_course.package_slug
    fill_in "Participants count", with: @training_course.participants_count
    fill_in "Registrations close at", with: @training_course.registrations_close_at.to_s
    fill_in "Registrations open at", with: @training_course.registrations_open_at.to_s
    fill_in "Teacher role", with: @training_course.teacher_role_id
    fill_in "Trainee role", with: @training_course.trainee_role_id
    fill_in "Tutor role", with: @training_course.tutor_role_id
    fill_in "Venue manager role", with: @training_course.venue_manager_role_id
    click_on "Update Training course"

    assert_text "Training course was successfully updated"
    click_on "Back"
  end

  test "should destroy Training course" do
    visit training_course_url(@training_course)
    accept_confirm { click_on "Destroy this training course", match: :first }

    assert_text "Training course was successfully destroyed"
  end
end
