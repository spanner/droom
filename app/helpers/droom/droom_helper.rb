module Droom
  module DroomHelper

    def droom_template_exists?(path)
      lookup_context.find_all("droom/#{path}").any?
    end

    def partial_exists?(path)
      path_parts = path.split('/')
      path_parts.push "_" + path_parts.pop
      lookup_context.find_all(path_parts.join('/')).any?
    end

    def droom_section_nav
      if @section && droom_template_exists?("nav/_#{@section}")
        render partial: "droom/nav/#{@section}"
      end
    end

    def clean_html(html)
      fragment = Loofah.fragment(html)
      fragment.xpath('text()').wrap('<p/>')
      fragment.scrub!(scrubber)
      fragment.scrub!(empty_node_scrubber)
      fragment.to_s.gsub(/[\r\n]+/, ' ').html_safe
    end

    def scrubber
      @_scrubber ||= Droom::Scrubber.new
    end

    def empty_node_scrubber
      @emptiness_scrubber ||= Loofah::Scrubber.new do |node|
        if !node.text? && node.children.empty? && node.name != 'img' && (node.text == "" || node.text =~ /^\s+$/)
          node.remove
        end
      end
    end

    def facet_options(facet, options={})
      if klass = options[:klass]
        options[:primary_key] ||= :id
        terms = facet.map{|f| f[:key]}
        models = klass.constantize.where({options[:primary_key] => terms}).to_a
        facet.each do |f|
          if model = models.find {|m| m.send(options[:primary_key]) == f[:key]}
            f[:name] = model.name
          end
        end
      end
      data = facet.select{|f| f[:key].present?}.map { |f| ["#{f[:name] || f[:key]} (#{f[:doc_count]})", f[:key]] }.sort_by {|o| o[0].to_s }
      data.reverse! if options[:desc]
      options_for_select(data, options[:selected])
    end
    alias :facet_option_tags :facet_options

    def aggs_options(agg, options={})
      if klass = options[:klass]
        options[:primary_key] ||= :id
        terms = agg.map{|f| f['key']}
        models = klass.constantize.where({options[:primary_key] => terms}).to_a
        agg.each do |f|
          if model = models.find {|m| m.send(options[:primary_key]) == f['key']}
            f[:name] = model.name
          end
        end
      end
      data = agg.select{|f| f['key'].present?}.map { |f| ["#{f[:name] || f['key']} (#{f['doc_count']})", f['key']] }.sort_by {|o| o[0].to_s }
      data.reverse! if options[:desc]
      options_for_select(data, options[:selected])
    end
    alias :aggs_option_tags :aggs_options

    def allowed?(permission_code)
      current_user.admin? || current_user.permitted?(permission_code)
    end

    def action_menulink(thing, html_options={}, group=nil)
      if can?(:edit, thing)
        classname = thing.class.to_s.underscore.split('/').last
        html_options.reverse_merge!({
          :class => "",
          :data => {:menu => "#{classname}_#{thing.id}#{group.try(:id)}"}
        })
        html_options[:class] << ' menu'
        link_to t(:edit), "#", html_options if can?(:edit, thing)
      end
    end
    
    def action_menu(thing, locals={})
      if can?(:edit, thing)
        type = thing.class.to_s.underscore
        classname = type.split('/').last
        locals[classname.to_sym] = thing
        render :partial => "#{type.pluralize}/action_menu", :locals => locals
      end
    end
    
    def help_link(slug, category=nil, title="")
      render 'droom/helps/show/link', slug: slug, category: category, title: title
    end

    def admin?
      user_signed_in? && current_user.admin?
    end

    def organisation_admin?(organisation=nil)
      user_signed_in? &&
        current_user.admin? || 
        (current_user.organisation_admin? && !organisation || current_user.organisation == organisation)
    end

    def external_user?
      Droom.require_internal_organisation? && current_user.external?
    end

    def pageclass
      controller.controller_name
    end

    def preference_checkbox(key, options={})
      render :partial => "droom/preferences/checkbox", :locals => options.merge({:key => key})
    end

    def preference_radio_set(key, *values)
      render :partial => "droom/preferences/radio_set", :locals => {:key => key, :values => values}
    end

    def render_page(page)
      page.render
    end

    def render_published_page(page)
      page.render_published
    end

    def shorten(text, length=64, separator=" ")
      text = strip_tags(text)
      length = length[:length] if length.is_a?(Hash)
      content_tag :span, class: 'shortened', title: text do
        truncate(text, {:length => length, :separator => separator})
      end
    end

    def nav_link_to(name, url, options={})
      options[:class] ||= ""
      options[:class] << "here" if (request.path == url) || (url != "/" && request.path =~ /^#{url}/)
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

    def check_recaptcha?
      if ENV['RECAPTCHA_CHECK'] && ENV['RECAPTCHA_CHECK'] == 'true'
        true
      else
        false
      end
    end

    def recaptcha_execute(action)
      id = "recaptcha_token_#{SecureRandom.hex(10)}"
  
      raw %Q{
        <input name="recaptcha_token" type="hidden" id="#{id}"/>
        <script>
          grecaptcha.ready(function() {
            grecaptcha.execute('#{ENV['RECAPTCHA_SITE_KEY']}', {action: '#{action}'}).then(function(token) {
              document.getElementById("#{id}").value = token;
            });
          });
        </script>
      }
    end
  end
end
