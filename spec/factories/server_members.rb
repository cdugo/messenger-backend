FactoryBot.define do
  factory :server_member do
    association :user
    association :server

    after(:create) do |member|
      member.server.create_read_state_for_user(member.user)
    end
  end
end 