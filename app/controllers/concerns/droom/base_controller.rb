# Useful Controller boilerplate
#
module Droom::BaseController
  extend ActiveSupport::Concern

  included do
    rescue_from CanCan::AccessDenied, with: :not_allowed
    rescue_from Droom::PermissionDenied, with: :not_allowed
    rescue_from Droom::PasswordRequired, with: :request_password
    protect_from_forgery

    helper Droom::DroomHelper

    before_action :set_exception_context
    before_action :set_user_context
    before_action :check_user_has_password, except: [:set_password]
    before_action :set_access_control_headers
  end


  ## Permissions
  # authenticated users attempting unauthorized actions will end up at `not_allowed`.
  #
  def not_allowed(exception)
    respond_to do |format|
      format.html { render file: "#{Rails.root}/public/403.html", status: 403, layout: false }
      format.js { head :forbidden }
      format.json { head :forbidden }
    end
  end

  def admin?
    user_signed_in? && current_user.admin?
  end


  ## Exception reporting
  # is usually by honeybadger, and we like to know who hit the exception.
  #
  def set_exception_context
    Honeybadger.context({
      user_name: current_user.name,
      user_uid: current_user.uid,
      user_email: current_user.email,
      service: service_name
    }) if Honeybadger && user_signed_in?
  end

  def service_name
    "Data Room"
  end

  def set_user_context
    RequestStore.store[:current_user] = current_user if user_signed_in? && !devise_controller?
  end


  ## Password-on-arrival
  #  is our usual way of bringing invited users on board.
  #
  def check_user_has_password
    if user_signed_in? && !current_user.has_password?
      @destination = request.fullpath
      raise Droom::PasswordRequired
    end
  end

  def request_password
    render template: "/droom/users/password_required"
  end


  ## Pagination help
  # Not much used now because most index lists come from elasticsearch
  # but if you want to paginate an activerecord collection, here you go.
  
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


  ## CORS help
  # for API calls from other domains.
  #
  def set_access_control_headers
    if request.env["HTTP_ORIGIN"].present?
      headers['Access-Control-Allow-Origin'] = request.env["HTTP_ORIGIN"]
      headers["Access-Control-Allow-Credentials"] = "true"
      headers["Access-Control-Allow-Methods"] = %{DELETE, GET, PATCH, POST, PUT}
      headers['Access-Control-Request-Method'] = '*'
      headers['Access-Control-Allow-Headers'] = 'Origin, X-PJAX, X-Requested-With, X-ClientID, Content-Type, Accept, Authorization'
    end
  end

  protected

  def no_layout_if_pjax
    if pjax?
      false
    else
      Droom.layout
    end
  end

  def pjax?
    !!request.headers['X-PJAX']
  end

end