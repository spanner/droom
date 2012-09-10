FactoryGirl.define do
  
  factory :document, :class => "Droom::Document"   do
    name "A document"
    description "Test document"
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