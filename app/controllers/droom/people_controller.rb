module Droom
  class PeopleController < Droom::EngineController
    respond_to :json, :html, :js, :vcf
    layout :no_layout_if_pjax
    
    before_filter :authenticate_user! 
    before_filter :scale_image_params, :only => [:create, :update]
    before_filter :find_people, :only => :index
    before_filter :get_groups
    before_filter :get_person, :only => [:show, :edit, :update, :destroy, :invite]
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
      @person.update_attributes(params[:person])
      respond_with @person do |format|
        format.js { render :partial => "droom/users/user_or_person" }
      end
    end

    def update
      Rails.logger.warn ">>> updating person with #{params[:person].inspect}"
      @person.update_attributes(params[:person])
      Rails.logger.warn "    person.valid? #{@person.valid?.inspect}: errors #{@person.errors.full_messages}"
      Rails.logger.warn "    person: #{@person.inspect}"
      respond_with @person
    end
    
    def destroy
      @user = @person.user
      @person.destroy
      if @user
        respond_with @user do |format|
          format.js { render :partial => "droom/users/user_or_person"}
          format.html { head :ok }
        end
      else
        head :ok 
      end
    end
    
    def invite
      @user = @person.invite!
      
      Rails.logger.warn ">>> Inviting person #{@person.inspect} gave us #{@user.inspect}"
      
      render :partial => "droom/users/user_or_person", :locals => {:user_or_person => @person}
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
        @people = Person.scoped({})
      else
        @people = Person.visible_to(current_person)
      end
      
      if params[:not_group_id]
        @people = @people.not_in_group(Droom::Group.find(params[:not_group_id]))
      end

      unless params[:q].blank?
        @searching = true
        @people = @people.matching(params[:q])
      end
      
      @show = params[:show] || 10
      @page = params[:page] || 1
      @people = @people.page(@page).per(@show)
    end
 
    def confine_to_self
      @person = current_user.person unless current_user.admin?
    end

    def scale_image_params
      multiplier = params[:multiplier] || 4
      Rails.logger.warn ">>> before scale_image_params (with multiplier #{multiplier}), params for person: #{params[:person].inspect}"
      if params[:person]
        [:image_scale_width, :image_scale_height, :image_offset_left, :image_offset_top].each do |p|
          params[:person][p] = (params[:person][p].to_i * multiplier.to_i) unless params[:person][p].blank?
        end
      end
      Rails.logger.warn ">>> after scale_image_params, params for person: #{params[:person].inspect}"
    end
  
  end
end