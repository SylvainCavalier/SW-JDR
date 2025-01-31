require "test_helper"

class CombatControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get combat_index_url
    assert_response :success
  end

  test "should get new" do
    get combat_new_url
    assert_response :success
  end

  test "should get create" do
    get combat_create_url
    assert_response :success
  end

  test "should get update" do
    get combat_update_url
    assert_response :success
  end
end
