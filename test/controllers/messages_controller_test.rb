require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @message = messages(:message_one)
    @server = servers(:one)
    @user = users(:one)
    sign_in_as @user
  end

  test "should get index" do
    get server_messages_url(@server), as: :json
    assert_response :success
  end

  test "should not get messages from server user is not member of" do
    other_server = servers(:two)
    get server_messages_url(other_server), as: :json
    assert_response :forbidden
  end

  test "should include pagination info in response" do
    get server_messages_url(@server), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_includes json_response, 'pagination'
    assert_includes json_response['pagination'], 'current_page'
    assert_includes json_response['pagination'], 'total_pages'
    assert_includes json_response['pagination'], 'total_count'
  end
end
