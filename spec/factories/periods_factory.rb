# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :period do
    sequence(:name)  {|n| "Period #{n}" }
    start DateTime.new(2012, 12, 12, 10, 0)
    finish DateTime.new(2012, 12, 12, 18, 0)

    factory :present_period do
      start { 3.hours.ago }
      finish { 7.hours.from_now }
    end
    factory :future_period do
      start { 1.hour.from_now }
      finish { 9.hours.from_now }
    end
    factory :past_period do
      start { 10.hours.ago }
      finish { 2.hours.ago }
    end
    factory :short_period do
      start DateTime.new(2012, 12, 12, 10, 0)
      finish DateTime.new(2012, 12, 12, 10, 5)
    end
    factory :long_period do
      start DateTime.new(2012, 12, 12, 10, 0)
      finish DateTime.new(2012, 12, 13, 18, 0)
    end
    factory :set_period do
      start DateTime.new(3012, 5, 30, 9, 0)
      finish DateTime.new(3012, 5, 30, 13, 0)
    end
    factory :interesting_period do
      name "Moon Landing"
      start DateTime.strptime("July 20, 1969 20:17:40 UT", '%B %d, %Y %H:%M:%S %Z')
      finish DateTime.strptime("July 21, 1969 17:54:01 UT", '%B %d, %Y %H:%M:%S %Z')
    end
  end
  
  factory :recording_period do
    sequence(:name)  {|n| "Recording period #{n}" }
    app
    period
    
    factory :present_recording_period do
      period :factory => :present_period
    end
    factory :future_recording_period do
      period :factory => :future_period
    end
  end
  
end
