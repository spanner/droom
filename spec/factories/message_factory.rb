FactoryGirl.define do

  factory :message do
    sequence(:title, 0) {|n| "title #{n}" }
    sequence(:text, 0) {|n| "text #{n}" }
    association :message_type
    
    factory :general_message do
      sequence(:title, 0) {|n| "general title #{n}" }
      sequence(:text, 0) {|n| "general text #{n}" }
      association :message_type, :factory => :general_message_type
    end
  end
  
  factory :message_type do
    name "Message Type"
    slug "message_type"
    
    factory :general_message_type do
      name "General"
      slug "general"
    end
  end
  
  factory :loc_message do
    app
    revision_number 0
    sequence(:title, 0) {|n| "title #{n}" }
    text { Forgery::LoremIpsum.paragraphs(1) }
    image { fixture_file_upload('spec/fixtures/images/msg_image.png', 'image/png') }
    association :area
    association :web_address
    after(:create) { |lm|
      lm.loc_message_days << create(:loc_message_day)
      lm.loc_message_times << create(:loc_message_time)
    }
  end
  
  factory :loc_message_day do
    day Date.parse("2012/12/12")
  end
  
  factory :loc_message_time do
    start Time.parse("10:00")
    finish Time.parse("18:00")
  end
  
end
