FactoryBot.define do
  factory :message do
    content { Faker::Lorem.sentence }
    association :user
    association :server

    after(:build) do |message|
      # Ensure user is a member of the server
      message.server.users << message.user unless message.server.users.include?(message.user)
    end

    trait :with_parent do
      transient do
        parent { create(:message) }
      end

      after(:build) do |message, evaluator|
        message.parent_message = evaluator.parent
        message.server = evaluator.parent.server
      end
    end

    trait :with_attachment do
      after(:build) do |message|
        message.attachments.attach(
          io: StringIO.new('test image'),
          filename: 'test.jpg',
          content_type: 'image/jpeg'
        )
      end
    end
  end
end 