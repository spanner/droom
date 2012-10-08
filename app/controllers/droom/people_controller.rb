module Droom
  class PeopleController < Droom::EngineController
    respond_to :json, :html, :js, :vcf
    layout :no_layout_if_pjax
    
    before_filter :authenticate_user!  
    before_filter :find_people, :only => :index
    before_filter :get_person, :only => [:show, :edit, :update]
    before_filter :build_person, :only => [:new, :create]
    before_filter :confine_to_self, :except => [:index, :show]
    
    def index
      respond_with @people do |format|
        format.js { render :partial => 'people'}
      end
    end
    
    def show
      respond_with @person
    end
    
    def create
      if @person.save
        render :partial => "created"
      else
        respond_with @person
      end
    end

    def update
      @person.update_attributes(params[:person])
      if @person.save
        render :partial => "person"
      else
        respond_with @person
      end
    end
    
    
  protected
    
    def build_person
      @person = Droom::Person.new(params[:person])
    end

    def get_person
      @person = Person.find(params[:id])
    end
    
    def find_people
      @people = Person.scoped({})

      unless params[:q].blank?
        @searching = true
        @people = @people.name_matching(params[:q])
      end
      
      @show = params[:show] || 10
      @page = params[:page] || 1
      @people.page(@page).per(@show)
    end
 
    def confine_to_self
      @person = current_user.person unless current_user.admin?
    end

  end
end