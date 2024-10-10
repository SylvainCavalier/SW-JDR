require "test_helper"

class HolonewsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get holonews_new_url
    assert_response :success
  end

  test "should get create" do
    get holonews_create_url
    assert_response :success
  end
end
