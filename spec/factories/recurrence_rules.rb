FactoryGirl.define do
  
  factory :recurrence_rule do
    factory :date_limited do
      period "weekly"
      interval 1
      basis "limit"
      limiting_date DateTime.civil(2009, 2, 24)
    end

    factory :count_limited do
      period "monthly"
      interval 2
      basis "count"
      limiting_date DateTime.civil(2009, 2, 24)
      limiting_count 12
    end

    factory :unlimited do
      period "daily"
      interval 2
    end

  end
  
end
