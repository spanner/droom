module Droom
  class MembershipsController < Droom::EngineController
    respond_to :js, :html
    
    before_filter :build_membership, :only => [:new, :create]
    before_filter :get_membership, :only => :destroy

    def destroy
      @membership = Membership.find(params[:id])
      @group = @membership.group
      @person = @membership.person
      @membership.destroy
      render :partial => "button"
    end
        
    def new
      if params[:person_id]
        @group = Droom::Group.find(params[:group_id])
        @person = Droom::Person.find(params[:person_id])
        @membership = @group.memberships.create!(:person_id => @person.id, :group_id => @group.id)
        render :partial => "button"
      else
        render :partial => "form"
      end
    end
    
    def create
      if @membership.save
        render :partial => "created"
      else
        respond_with @membership
      end
    end

    protected
    
    def build_membership
      @group = Droom::Group.find(params[:group_id])
      @membership = @group.memberships.new(params[:membership])
    end

    def get_membership
      @membership = Droom::Membership.find(params[:id])
    end

  end
end
