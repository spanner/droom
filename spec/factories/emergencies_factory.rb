# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :emergency do
    app
    active true
    sequence(:name)  {|n| "Emergency #{n}" }
    area :factory => :emergency_area
    period
    text { Forgery::LoremIpsum.paragraphs(1) }
    
    factory :standard_emergency do
      name "There is an angry elephant on Pall Mall"
      text "Beware of the elephant. Do not approach the elephant. Avoid making eye contact with the elephant and do not put buns in your pocket."

      factory :present_emergency do
        period :factory => :present_period
      end
      factory :future_emergency do
        period :factory => :future_period
      end
      factory :past_emergency do
        period :factory => :past_period
      end
      factory :set_emergency do
        period :factory => :set_period
      end
    end
  end
end