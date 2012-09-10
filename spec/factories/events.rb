FactoryGirl.define do
  
  factory :event, :class => "Droom::Event"  do
    description "an event"
    
    factory :simple do
      title "Simple Event"
      start_date "2009-11-03 18:30:00"
    end
    
    factory :repeating do
      title "Repeating Event"
      start_date "2009-11-03 18:30:00"
      end_date "2009-11-03 20:00:00"
      after(:create) { ||
        event.recurrence_rules.create(:period => "weekly", :interval => "1", :basis => 'count', :limiting_count => "4")
      }
    end

    factory :spanning do
      title "Simple Event"
      start_date "2009-11-03 09:00:00"
      end_date "2009-11-04 17:00:00"
    end
    
    factory :allday do
      title "All Day Event"
      start_date "2009-11-03 09:00:00"
      end_date "2009-11-04 17:00:00"
      all_day true
    end
    
  end
  
end
