include ActionDispatch::TestProcess

FactoryGirl.define do

  factory :web_address do
    app
    name "link"
    sequence(:url)  {|n| "http://spanner.org/wa_#{n}" }
    
    factory :secure_web_address do
      name "secure link"
      sequence(:url)  {|n| "https://spanner.org/wa_#{n}" }
    end

    factory :broken_web_address do
      name "bad link"
      url "spannerorg"
    end
    
    factory :transport_address do
      name "transport"
      url 'http://app.lordmayorshow.org/transport'
    end
  end
  
  factory :app_tab do
    title "Tab"
    version 1
    icon { fixture_file_upload('spec/fixtures/images/tab_icon.png', 'image/png') }
    app
    
    factory :maps_tab do
      title "Maps"
      association :app_controller, :factory => :maps_controller
    end

    factory :travel_tab do
      title "Travel"
    end
  end
  
  factory :app_view do
    title "View"
    version 1
    background { fixture_file_upload('spec/fixtures/images/background.jpg', 'image/jpeg') }
    
    factory :travel_view do
      title "Travel"
    end
  end
  
  factory :app_button do
    title "Button"
    association :app
    version 1
    app_controller
    
    factory :about_button do
      title "About"
    end

    factory :take_me_button do
      title "Take me to the Show"
      point
      app_controller :factory => :nav_view_controller
    end

    factory :transport_button do
      title "Public Transport"
      app_controller :factory => :web_view_controller
      web_address :factory => :transport_address
    end

    factory :twitter_button do
      title "Twitter"
      app_controller :factory => :twitter_view_controller
      startstring "@spannr"
    end
  end
  
  factory :contact do
    name "info line"
    content "01234567890"
    content_type "phone number"
    highlighted false
  end
  
  factory :checklist_item do
    title "item"
    text "do something"
  end

  factory :event do
    link ""
    description "Rowing is a sport in which athletes race against each other on rivers, on lakes or on the ocean, depending upon the type of race and the discipline. The boats are propelled by the reaction forces on the oar blades as they are pushed against the water. The sport can be both recreational, focusing on learning the techniques required,[1] and competitive where overall fitness plays a large role. It is also one of the oldest Olympic sports. In the United States, high school and collegiate rowing is sometimes referred to as crew."
    name "Rowing"
    ending_time "16:00"
    starting_time "13:00"
    start_date "2019-12-31"
    point
    image { fixture_file_upload('spec/fixtures/images/msg_image.png', 'image/png') }
  end
  
end
