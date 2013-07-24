FactoryGirl.define do
  factory :user, :class => Droom::User do
    sequence(:name) {|n|  "User#{n} Smith"}
    password "Passw0rd"
    password_confirmation "Passw0rd"
    sequence(:email) {|n| "user#{n}.smith@spanner.org" }
  end
end