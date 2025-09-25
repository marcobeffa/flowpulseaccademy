require "test_helper"

class SuperadminControllerTest < ActionDispatch::IntegrationTest
  test "should get indexlead" do
    get superadmin_leads_path_url
    assert_response :success
  end

  test "should get showlead" do
    get superadmin_showlead_url
    assert_response :success
  end
end
