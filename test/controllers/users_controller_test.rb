require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should create user" do
    assert_difference("User.count") do
      post signup_url, params: { 
        username: "newuser", 
        email: "new@example.com",
        password: "password123"
      }, as: :json
    end

    assert_response :created
  end

  test "should show current user" do
    sign_in_as @user
    get me_url, as: :json
    assert_response :success
    assert_equal @user.id, JSON.parse(response.body)["user"]["id"]
  end

  test "should not show user when not authenticated" do
    get me_url, as: :json
    assert_response :unauthorized
  end
end
