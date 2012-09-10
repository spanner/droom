FactoryGirl.define do
  
  factory :download do
    name "A download"
    description "Test download"
    # document
    
    factory :grouped do
      name "grouped"
    end
    
    factory :alsogrouped do
      name "alsogrouped"
    end

    factory :ungrouped do
      name "ungrouped"
    end
        
  end
  
end