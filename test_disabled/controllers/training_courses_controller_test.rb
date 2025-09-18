require "test_helper"

class TrainingCoursesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @training_course = training_courses(:one)
  end

  test "should get index" do
    get training_courses_url
    assert_response :success
  end

  test "should get new" do
    get new_training_course_url
    assert_response :success
  end

  test "should create training_course" do
    assert_difference("TrainingCourse.count") do
      post training_courses_url, params: { training_course: { course_slug: @training_course.course_slug, lat: @training_course.lat, lng: @training_course.lng, location_address: @training_course.location_address, location_gmaps: @training_course.location_gmaps, location_name: @training_course.location_name, location_phone: @training_course.location_phone, package_slug: @training_course.package_slug, participants_count: @training_course.participants_count, registrations_close_at: @training_course.registrations_close_at, registrations_open_at: @training_course.registrations_open_at, teacher_role_id: @training_course.teacher_role_id, trainee_role_id: @training_course.trainee_role_id, tutor_role_id: @training_course.tutor_role_id, venue_manager_role_id: @training_course.venue_manager_role_id } }
    end

    assert_redirected_to training_course_url(TrainingCourse.last)
  end

  test "should show training_course" do
    get training_course_url(@training_course)
    assert_response :success
  end

  test "should get edit" do
    get edit_training_course_url(@training_course)
    assert_response :success
  end

  test "should update training_course" do
    patch training_course_url(@training_course), params: { training_course: { course_slug: @training_course.course_slug, lat: @training_course.lat, lng: @training_course.lng, location_address: @training_course.location_address, location_gmaps: @training_course.location_gmaps, location_name: @training_course.location_name, location_phone: @training_course.location_phone, package_slug: @training_course.package_slug, participants_count: @training_course.participants_count, registrations_close_at: @training_course.registrations_close_at, registrations_open_at: @training_course.registrations_open_at, teacher_role_id: @training_course.teacher_role_id, trainee_role_id: @training_course.trainee_role_id, tutor_role_id: @training_course.tutor_role_id, venue_manager_role_id: @training_course.venue_manager_role_id } }
    assert_redirected_to training_course_url(@training_course)
  end

  test "should destroy training_course" do
    assert_difference("TrainingCourse.count", -1) do
      delete training_course_url(@training_course)
    end

    assert_redirected_to training_courses_url
  end
end
