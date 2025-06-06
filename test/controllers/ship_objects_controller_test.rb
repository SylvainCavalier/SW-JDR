require "test_helper"

class ShipObjectsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get ship_objects_new_url
    assert_response :success
  end

  test "should get create" do
    get ship_objects_create_url
    assert_response :success
  end

  test "should get edit" do
    get ship_objects_edit_url
    assert_response :success
  end

  test "should get update" do
    get ship_objects_update_url
    assert_response :success
  end

  test "should get destroy" do
    get ship_objects_destroy_url
    assert_response :success
  end
end
