require 'dropbox_sdk'

module Droom
  module DroomHelper
    
    def dropbox?
      !!current_user.dropbox_access_token
    end
    
    def dropbox_auth_url
      dbs = dropbox_session
      # get an auth link address, with our register action as the callback
      authorization_url = dbs.get_authorize_url(droom.register_dropbox_tokens_url)
      # store the requesting dropbox session, serialized, in our user's session cookie
      # if the oauth confirmation is successful, we will need it.
      session[:dropbox_session] = dbs.serialize
      authorization_url
    end
    
    def dropbox_session
      # note that here we never want to pick up the existing dropbox session. That happens in the dropbox_tokens_controller
      # when we register an access token. In the view, any existing session has probably expired and we're better off with a new one.
      DropboxSession.new(Droom.dropbox_app_key, Droom.dropbox_app_secret)
    end

    def editable?(thing)
      current_user.admin?
    end

    def nav_link_to(name, url, options={})
      options[:class] ||= ""
      options[:class] << "here" if (request.path == url) || (request.path =~ /^#{url}/ && url != "/")
      link_to name, url, options
    end

    def month_header_for(date)
      content_tag('h3', l(date, :format => :month_header))
    end
    
    def pagination_summary(collection, options = {})
      entry_name = options[:entry_name] || (collection.empty?? 'entry' : collection.first.class.name.underscore.sub('_', ' '))
      summary = if collection.num_pages < 2
        case collection.total_count
        when 0; "No #{entry_name.pluralize} found"
        when 1; "Displaying <strong>1</strong> #{entry_name}:"
        else;   "Displaying <strong>all #{collection.total_count}</strong> #{entry_name.pluralize}:"
        end
      else
        offset = (collection.current_page - 1) * collection.limit_value
        %{Displaying <strong>%d&nbsp;-&nbsp;%d</strong> of <strong>%d</strong> #{entry_name.pluralize}: } % [
          offset + 1,
          offset + collection.length,
          collection.total_count
        ]
      end
      summary.html_safe
    end

    # This will apply cloud-weighting to any list of items.
    # They must have a 'weight' attribute
    # and be ready to accept a 'cloud_size' attribute.

    def cloud(these, threshold=0, biggest=3.0, smallest=1.3)
      counts = these.map{|t| t.weight.to_i}.compact
      if counts.any?
        max = counts.max
        min = counts.min
        if max == min
          these.each do |this|
            this.cloud_size = sprintf("%.2f", biggest/2 + smallest/2)
          end
        else
          steepness = Math.log(max - (min-1))/(biggest - smallest)
          these.each do |this|
            offset = Math.log(this.weight.to_i - (min-1))/steepness
            this.cloud_size = sprintf("%.2f", smallest + offset)
          end
        end
        if block_given?
          these.each do |this|
            yield this
          end
        end
      end
    end
    
    def url_for_month(date)
      droom.calendar_url(:year => date.year, :month => date.month)
    end

    def url_for_date(date)
      droom.calendar_url(:year => date.year, :month => date.month, :mday => date.day)      
    end
    
    def day_names
      ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    end
    
  end
end
