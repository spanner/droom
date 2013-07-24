# This has been pulled from the yearbook and simplified. Docs need updating to match.

module Droom
  class Person < ActiveRecord::Base

    # minimised but kept for a while to support migration away

    has_attached_file :image

  end
end

