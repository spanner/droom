module Droom::Concerns::LocalApi
  extend ActiveSupport::Concern

  included do
    skip_before_action :authenticate_user!, if: :api_local?, raise: false
    before_action :assert_local_request!, if: :api_local?
  end

  def api_local?
    Droom.config.api_local?
  end

  def assert_local_request!
    if (Rails.env.production? || Rails.env.staging?) && !local_request?
      raise CanCan::AccessDenied 
    end
  end

  def local_request?
    if local_subnet_defined?
      permitted_ip_range = IPAddr.new(ENV['LOCAL_SUBNET'] || "172.0.0.0/8")
      permitted_ip_range === IPAddr.new(request.ip)
    else
      false
    end
  end

  def local_subnet_defined?
    ENV['LOCAL_SUBNET'].present
  end

end