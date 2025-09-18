require "test_helper"

class SuperadminControllerTest < ActionDispatch::IntegrationTest
  test "should get indexcontact" do
    get superadmin_contacts_path_url
    assert_response :success
  end

  test "should get showcontact" do
    get superadmin_showcontact_url
    assert_response :success
  end
end
