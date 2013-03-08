require 'dropbox_sdk'

module Droom
  module DroomHelper

    def action_menulink(thing, html_options={})
      classname = thing.class.to_s.downcase.underscore.split('/').last
      html_options.reverse_merge!({
        :class => "",
        :data => {:menu => "#{classname}_#{thing.id}"}
      })
      html_options[:class] << " menu"
      link_to t(:edit), "#", html_options if editable?(thing)
    end
    
    def action_menu(thing, locals={})
      if editable?(thing)
        type = thing.class.to_s.downcase.underscore
        classname = type.split('/').last
        locals[classname.to_sym] = thing
        render :partial => "#{type.pluralize}/action_menu", :locals => locals
      end
    end
    
    def dropbox_link(folder)
      if dropbox? && current_user.pref('dropbox.strategy') == 'clicked' && folder.populated? && !folder.dropboxed_for?(current_user)
        link_to t(:copy_to_dropbox), droom.dropbox_folder_url(folder), :id => "dropbox_folder_#{folder.id}", :class => 'dropboxer minimal', :data => {:action => "remove", :removed => "#dropbox_folder_#{folder.id}"}
      end
    end

    def admin?
      current_user and current_user.admin?
    end

    def pageclass
      controller.controller_name
    end

    def preference_checkbox(key)
      render :partial => "droom/preferences/checkbox", :locals => {:key => key}
    end

    def preference_radio_set(key, *values)
      render :partial => "droom/preferences/radio_set", :locals => {:key => key, :values => values}
    end

    def shorten(text, length=64)
      length = length[:length] if length.is_a?(Hash)
      truncate(strip_tags(text), {:length => length, :separator => " "})
    end

    def dropbox?
      current_user and !!current_user.dropbox_token
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
    
    def visible?(thing)
      admin? || privileged? || current_user.can_see?(thing)
    end
    
    def editable?(thing)
      admin? || current_user == thing.created_by
    end

    def deletable?(thing)
      admin? || current_user == thing.created_by
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
      droom.events_url(:year => date.year, :month => date.month)
    end

    def url_for_date(date)
      droom.events_url(:year => date.year, :month => date.month, :mday => date.day)      
    end
    
    def day_names
      ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    end
    
  end
end
