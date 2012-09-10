class User < ActiveRecord::Base
  attr_accessible :name, :email
  belongs_to :person
  
end
