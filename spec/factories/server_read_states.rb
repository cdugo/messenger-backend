FactoryBot.define do
  factory :server_read_state do
    association :user
    association :server

    after(:build) do |read_state|
      # Ensure user is a member of the server
      read_state.server.users << read_state.user unless read_state.server.users.include?(read_state.user)
    end

    last_read_at { Time.current }
    unread_count { 0 }
  end
end 