require "test_helper"

class ShipsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get ships_index_url
    assert_response :success
  end

  test "should get show" do
    get ships_show_url
    assert_response :success
  end

  test "should get new" do
    get ships_new_url
    assert_response :success
  end

  test "should get create" do
    get ships_create_url
    assert_response :success
  end

  test "should get edit" do
    get ships_edit_url
    assert_response :success
  end

  test "should get update" do
    get ships_update_url
    assert_response :success
  end

  test "should get destroy" do
    get ships_destroy_url
    assert_response :success
  end

  test "should get set_active" do
    get ships_set_active_url
    assert_response :success
  end

  test "should get dock" do
    get ships_dock_url
    assert_response :success
  end

  test "should get undock" do
    get ships_undock_url
    assert_response :success
  end

  test "should get inventory" do
    get ships_inventory_url
    assert_response :success
  end
end
