module Droom
  class MembershipsController < Droom::EngineController
    respond_to :js, :html
    
    load_and_authorize_resource :group, :class => Droom::Group
    load_and_authorize_resource :membership, :through => :group, :class => Droom::Membership

    def destroy
      @membership = Membership.find(params[:id])
      @group = @membership.group
      @user = @membership.user
      @membership.destroy
      render :partial => "toggle"
    end
        
    def new
      if params[:user_id]
        @user = Droom::User.find(params[:user_id])
        @membership = @group.memberships.create!(:user_id => @user.id, :group_id => @group.id)
        render :partial => "button"
      else
        respond_with @membership
      end
    end
    
    def create
      if @membership.save
        @user = @membership.user
        render :partial => "toggle"
      else
        respond_with @membership
      end
    end

  protected

    def membership_params
      permitted_user_attributes = [:title, :family_name, :given_name, :chinese_name, :email, :password, :password_confirmation, :phone, :description, :admin, :preferences_attributes, :confirm, :old_id, :invite_on_creation, :post_line1, :post_line2, :post_city, :post_region, :post_country, :post_code, :mobile, :dob, :organisation_id, :public, :private, :female, :image, :send_confirmation]
      params.require(:membership).permit(:group_id, :user_id, user_attributes: permitted_user_attributes)
    end

  end
end
