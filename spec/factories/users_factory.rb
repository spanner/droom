FactoryGirl.define do
  factory :user do
    account
    forename "Test"
    surname "User"
    password "Passw0rd"
    password_confirmation "Passw0rd"
    sequence(:email, 0) {|n| "user#{n}@spanner.org" }
    
    factory :activated_user do
      password "password"
      password_confirmation "password"
      activated true
      after(:create) { |u| u.confirm! }
    end

    factory :new_user do
      activated false
      # association :account
    end
  end
  
  factory :account do
    name "Test Account"
    # association :owner, :factory => :activated_user
  end
  
  factory :ip_address do
    address "0.0.0.0"
    # association :account, :factory => :account
  end
  
  
end
