FactoryGirl.define do
  factory :point do
    sequence(:name)  {|n| "Point #{n}" }
    lat 51.523456789
    lng -0.112345678
    area
    
    factory :nw_point do
      lat 51.5
      lng -5.0
    end
    
    factory :ne_point do
      lat 51.5
      lng -4.5
    end
    
    factory :sw_point do
      lat 51.0
      lng -5.0
    end
    
    factory :se_point do
      lat 51.0
      lng -4.5
    end
  end
  
  factory :area do
    factory :standard_area do
      after(:create) do |area|
        create :nw_point, :area => area, :position => 1
        create :ne_point, :area => area, :position => 2
        create :sw_point, :area => area, :position => 3
        create :se_point, :area => area, :position => 4
      end
    end
    factory :emergency_area do
      after(:create) do |area|
        create :nw_point, :area => area, :position => 1
        create :ne_point, :area => area, :position => 2
        create :sw_point, :area => area, :position => 3
      end
    end
  end
  
  factory :poi_type do
    sequence(:name)  {|n| "POI Type #{n}" }
    icon { fixture_file_upload('spec/fixtures/images/icon.png', 'image/png') }
  end
  
  factory :poi do
    sequence(:name)  {|n| "POI #{n}" }
    text { Forgery::LoremIpsum.paragraphs(1) }
    web_address
    point
    poi_type
  end

  factory :map_layer do
    sequence(:name)  {|n| "Map Layer #{n}" }
    layer_type "google_maps"
    image { fixture_file_upload('spec/fixtures/images/map.jpg', 'image/jpeg') }
    width 842
    height 596
    sw_point
    ne_point
    revision_number 1
    showposition true
  end
end
