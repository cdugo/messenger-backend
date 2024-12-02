FactoryBot.define do
  factory :message_reaction do
    association :user
    association :message

    after(:build) do |reaction|
      # Ensure user is a member of the message's server
      reaction.message.server.users << reaction.user unless reaction.message.server.users.include?(reaction.user)
    end

    emoji { "👍" }
  end
end 