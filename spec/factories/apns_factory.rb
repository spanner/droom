require 'securerandom'

FactoryGirl.define do

  factory :device_token do
    app
    token { SecureRandom.hex(64) }
    
    factory :standard_token do
      token "ad601bcfa1a81f403e96f4f005666f3ac704b15e4329dba11b58fcfb3661b023"
    end
  end
  
  factory :rapns_app, :class => Rapns::App do
    key { SecureRandom.hex(12) }
    environment "development"
    connections 1
    password "password"
    certificate File.read(Rails.root + "spec/fixtures/certs/ck.pem")
  end

  factory :rapns_feedback, :class => Rapns::Feedback do
    app
    sequence(:key) {|n| "app_#{n}" }
    device_token { SecureRandom.hex(64) }
    failed_at {1.hour.ago}
    
    factory :standard_feedback do
      device_token "ad601bcfa1a81f403e96f4f005666f3ac704b15e4329dba11b58fcfb3661b023"
    end
  end

end


