FactoryGirl.define do
  factory :person, :class => "Droom::Person" do
    name "Droom"
    email "droom@spanner.org"
    
    factory :public_person do
      name "Public Person"
      public true
    end

    factory :private_person do
      name "Private Person"
      shy true
    end
  end  
end
