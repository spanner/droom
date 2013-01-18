module Droom
  class PersonalFolder < ActiveRecord::Base
    belongs_to :person
    belongs_to :folder
    has_many :personal_documents
    acts_as_tree
    
    validates :person, :presence => true
    validates :folder, :presence => true
    
    delegate :name, :path, :to => :folder

  end
end
