FactoryGirl.define do
  
  factory :page do
    
    factory :calendar do
      slug "calendar"
      class_name "EventCalendarPage"
      body "<r:month />"
    end
    
  end
  
end
