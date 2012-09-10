FactoryGirl.define do
  factory :app do
    name 'App'
    slug  'app'
    description "An app"
    pushy false
    panicky false
    revision_number 0
    icon { fixture_file_upload('spec/fixtures/images/icon.png', 'image/png') }
    
    factory :test_app do
      name 'App'
      slug  'test_app'
      description "Basic app for unit tests"
    end

    factory :emergency_app do
      name 'Emergency'
      slug  'emergency_app'
      description "Emergency app for dispatcher tests"
    end

    factory :active_app do
      name 'Active'
      slug  'active_app'
      pushy false
      panicky false
      description "Fully populated app for dispatcher tests"
      area :factory => :standard_area
      after(:create) { |app|
        app.recording_periods << create(:recording_period, :app => app)
      }
    end

    factory :pushy_app do
      name 'Pushy'
      slug  'pushy_app'
      description "pushy app for message push tests"
      pushy true
      panicky false
      rapns_app

      factory :panicky_app do
        name 'Panicky'
        slug  'panicky_app'
        panicky true
        description "panicky app for emergency push tests"
      end
    end
  end

  factory :api do
    name 'Original'
    version 1
  end
    
  factory :app_controller do
    name "About"
    controller_name "AboutViewController"
    web_address_required false
    point_required false
    startstring_required false
    online false

    factory :maps_controller do
      name "Maps"
      controller_name "MapsViewController"
      online true
    end

    factory :calendar_controller do
      name "Calendar"
      controller_name "CalendarViewController"
      online true
    end
    
    factory :web_view_controller do
      name "Website"
      controller_name "WebViewController"
      web_address_required true
      point_required false
      startstring_required true
      online true
    end

    factory :nav_view_controller do
      name "Take me there"
      controller_name "TakeMeThereViewController"
      web_address_required false
      point_required true
      startstring_required true
      online true
    end

    factory :twitter_view_controller do
      name "Twitter"
      controller_name "TwitterViewController"
      web_address_required false
      point_required false
      startstring_required true
      online true
    end

  end

end
