require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  setup do
    @message = messages(:message_one)
    @server = servers(:one)
    @user = users(:one)
    @other_user = users(:two)
    sign_in_as @user
  end

  test "should get index" do
    get server_messages_url(@server), as: :json
    assert_response :success
  end

  test "should include user information in response" do
    get server_messages_url(@server), as: :json
    assert_response :success
    
    message = @response.parsed_body['messages'].first
    assert_includes message['user'].keys, 'username'
  end

  test "should paginate messages" do
    23.times do
      Message.create!(
        content: "Test message",
        user: @user,
        server: @server
      )
    end

    get server_messages_url(@server), as: :json
    assert_response :success
    
    assert_equal 25, @response.parsed_body['messages'].length
    assert_includes @response.parsed_body, 'pagination'
    assert_includes @response.parsed_body['pagination'], 'current_page'
    assert_includes @response.parsed_body['pagination'], 'total_pages'
    assert_includes @response.parsed_body['pagination'], 'total_count'
  end

  test "should get second page of messages" do
    53.times do
      Message.create!(
        content: "Test message",
        user: @user,
        server: @server
      )
    end

    get server_messages_url(@server, page: 2), as: :json
    assert_response :success
    
    assert_equal 5, @response.parsed_body['messages'].length
  end

  test "should include attachment urls in response" do
    message = Message.create!(
      content: "Test with attachment",
      user: @user,
      server: @server
    )
    message.attachments.attach(
      io: StringIO.new("test image"),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )

    get server_messages_url(@server), as: :json
    assert_response :success
    
    message_response = @response.parsed_body['messages'].find { |m| m['id'] == message.id }
    assert_not_nil message_response['attachment_urls']
    assert_not_empty message_response['attachment_urls']
  end

  test "should not get messages from server user is not member of" do
    other_server = servers(:two)
    @server.users.delete(@user) # Remove user from server
    
    get server_messages_url(@server), as: :json
    assert_response :forbidden
  end
end
