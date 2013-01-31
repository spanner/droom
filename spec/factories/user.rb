FactoryGirl.define do
  factory :user, :class => Droom::User do
    name "Will"
    email "will@spanner.org"
  end
end