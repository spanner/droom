module Droom::Concerns::ControllerHelpers
  extend ActiveSupport::Concern

  included do
    rescue_from CanCan::AccessDenied, :with => :not_allowed
    rescue_from Droom::PermissionDenied, :with => :not_allowed
    rescue_from Droom::PasswordRequired, :with => :prompt_for_password
    rescue_from Droom::OrganisationRequired, :with => :prompt_for_organisation

    before_action :authenticate_user!
    before_action :set_exception_context
    before_action :check_user_has_password, except: [:set_password]
    before_action :check_user_has_organisation, except: [:set_organisation]
    before_action :note_current_user
    before_action :set_access_control_headers
    before_action :set_section

    layout :no_layout_if_pjax
  end


  # CORS blanket approval
  #
  def set_access_control_headers
    if request.env["HTTP_ORIGIN"].present? && Droom.cors_domains.empty? || Droom.cors_domains.include?(request.env["HTTP_ORIGIN"])
      headers['Access-Control-Allow-Origin'] = request.env["HTTP_ORIGIN"]
      headers["Access-Control-Allow-Credentials"] = "true"
      headers["Access-Control-Allow-Methods"] = %{DELETE, GET, PATCH, POST, PUT}
      headers['Access-Control-Request-Method'] = '*'
      headers['Access-Control-Allow-Headers'] = 'Origin, X-PJAX, X-Requested-With, X-ClientID, Content-Type, Accept, Authorization'
    end
  end


  ## Authorization helpers
  #
  def admin?
    user_signed_in? && current_user.admin?
  end

  def organisation_admin?(organisation=nil)
    Droom::use_organisations? &&
      user_signed_in? &&
      current_user.admin? ||
      (current_user.organisation_admin? && !organisation || current_user.organisation == organisation)
  end

  def note_current_user
    RequestStore.store[:current_user] = current_user if user_signed_in? && !devise_controller?
  end

  def not_allowed(exception)
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/403.html", :status => 403, :layout => false }
      format.js { head :forbidden }
      format.json { head :forbidden }
    end
  end


  ## Exception reporting
  #
  def set_exception_context
    Honeybadger.context({
      :user_name => current_user.name,
      :user_uid => current_user.uid,
      :user_email => current_user.email,
      :service => "Data room"
    }) if user_signed_in?
  end


  ## User setup interruptions
  #  Post-registration or post-confirmation helpers to allow for late password-setting
  #  and any other configuration steps that should happen between confirmation and use of site.
  #
  def check_user_has_password
    if user_signed_in? && !current_user.encrypted_password?
      @destination = request.fullpath
      raise Droom::PasswordRequired
    end
  end

  def prompt_for_password
    render template: "/droom/users/password_required"
  end

  def check_user_has_organisation
    if user_signed_in? && Droom.use_organisations? && Droom.require_organisation? && !current_user.organisation
      @destination = request.fullpath
      raise Droom::OrganisationRequired
    end
  end

  def prompt_for_organisation
    @organisations = Droom::Organisation.matching_email(current_user.email)
    render template: "/droom/users/organisation_required"
  end


  ## Pagination helpers
  #
  def paginated(collection, default_show=10, default_page=1)
    @show = (params[:show] || default_show).to_i
    @page = (params[:page] || default_page).to_i
    collection.page(@page).per(@show)
  end

  def set_pagination_headers
    if results = instance_variable_get("@#{name_from_controller}")
      if results.respond_to? :total_count
        headers["X-Pagination"] = {
          limit: results.limit_value,
          offset: results.offset_value,
          total_count: results.total_count
        }.to_json
      end
    end
  end


  ## Subview selection

  def get_view
    @view = params[:view] if permitted_views.include? params[:view]
    @view ||= default_view
  end

  def permitted_views
    ['full', 'listed']
  end

  def default_view
    'full'
  end


  # Misc
  #
  def partial_exists?(path)
    lookup_context.find_all(path).any?
  end

  def set_section
    @section = controller_name.to_sym
  end

  def no_layout_if_pjax
    if pjax?
      false
    else
      default_layout
    end
  end

  def pjax?
    request.headers['X-PJAX'].present?
  end

  def default_layout
    Droom.layout
  end

end