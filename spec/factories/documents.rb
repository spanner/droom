FactoryGirl.define do
  factory :document, :class => "Droom::Document" do
    name "A document"
    description "Test document"
    file Rack::Test::UploadedFile.new('/private/var/www/gems/droom/spec/fixtures/images/rat.png', 'image/png')
    
    factory :grouped do
      name "grouped"
    end
            
  end
  
end