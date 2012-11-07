module Droom
  class PeopleController < Droom::EngineController
    respond_to :json, :html, :js, :vcf
    layout :no_layout_if_pjax
    
    before_filter :authenticate_user! 
    before_filter :get_current_person
    before_filter :find_people, :only => :index
    before_filter :get_groups, :only => :index
    before_filter :get_person, :only => [:show, :edit, :update, :destroy]
    before_filter :build_person, :only => [:new, :create]
    before_filter :confine_to_self, :except => [:index, :show]
    
    def index
      respond_with @people do |format|
        format.js { render :partial => 'droom/people/people' }
        format.vcf { render :vcf => @people.map(&:to_vcf) }
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
      Rails.logger.warn params[:person]
      @person.update_attributes(params[:person])
      @person.save!
      respond_with @person do |format|
        format.json {
          render
        }
      end
      # if @person.save
      #   render :partial => "person"
      # else
      #   respond_with @person
      # end
    end
    
    def destroy
      @person.destroy
      head :ok
    end
    
  protected
    
    def build_person
      @person = Droom::Person.new(params[:person])
    end

    def get_person
      @person = Person.find(params[:id])
    end
    
    def get_groups
      @groups = Droom::Group.all
    end
    
    def find_people
      if current_user.admin?
        @people = Person.all
      else
        @people = Person.visible_to(@current_person)
      end
      
      if params[:group_id]
        @people = @people.not_in_group(Droom::Group.find(params[:group_id]))
      end

      unless params[:q].blank?
        @searching = true
        @people = @people.name_matching(params[:q])
      end
      
      @people
    end
 
    def confine_to_self
      @person = current_user.person unless current_user.admin?
    end

  end
end