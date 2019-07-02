module Droom
  class OrganisationType < Droom::DroomRecord
    include Droom::Concerns::Slugged

    has_many :organisations
    has_folder within: "Organisations" # within arguments sets the name of our parent folder

    before_validation :slug_from_name

    # before_validation :slug_from_name
    default_scope -> {order(:name)}

    def self.for_selection
      self.all.map {|et| [et.name, et.id]}
    end

    def self.default
      self.where(:slug => "other_organisations").first_or_create({
        name: "Other Organisations"
      })
    end

  end
end