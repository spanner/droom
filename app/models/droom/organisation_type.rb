module Droom
  class OrganisationType < ActiveRecord::Base
    has_many :organisations
  end
  end
end