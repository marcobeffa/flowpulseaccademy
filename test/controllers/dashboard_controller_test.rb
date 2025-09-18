require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get user" do
    get dashboard_user_url
    assert_response :success
  end
end
