FactoryBot.define do
  factory :server do
    sequence(:name) { |n| "Server #{n}" }
    sequence(:description) { |n| "Description for server #{n}" }

    transient do
      owner { create(:user) }
    end

    after(:build) do |server, evaluator|
      server.owner_id = evaluator.owner.id
    end

    after(:create) do |server, evaluator|
      server.users << evaluator.owner unless server.users.include?(evaluator.owner)
      server.reload
    end

    trait :with_members do
      transient do
        members_count { 3 }
      end

      after(:create) do |server, evaluator|
        create_list(:server_member, evaluator.members_count - 1, server: server)
      end
    end
  end
end 