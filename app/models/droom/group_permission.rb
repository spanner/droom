module Droom
  class GroupPermission < ActiveRecord::Base
    belongs_to :group
    belongs_to :permission
  end
end