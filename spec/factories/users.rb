FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@fitfusion.test" }
    sequence(:name)  { |n| "Usuario #{n}" }
    password { "fitfusion123" }
    role { "client" }

    factory :practitioner do
      role { "practitioner" }
      after(:create) { |u| create(:practitioner_profile, user: u) }
    end

    factory :client do
      role { "client" }
      after(:create) { |u| create(:client_profile, user: u) }
    end
  end

  factory :practitioner_profile do
    user
    specialty { "trainer" }
  end

  factory :client_profile do
    user
    goal { "Hipertrofia" }
  end

  factory :practitioner_client do
    association :practitioner, factory: :practitioner
    association :client, factory: :client
    relationship_type { "trainer" }
    status { "active" }
  end
end
