module ActionDispatch::Routing

  class Mapper
    def droom
      droom_at('/')
    end

    def droom_at(prefix="/")
      prefix = "#{prefix}/" unless prefix.last == '/'
      mount Droom::Engine => "#{prefix}droom/", :as => :droom
    end
  end
end
