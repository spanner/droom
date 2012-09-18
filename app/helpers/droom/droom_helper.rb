module Droom
  module DroomHelper
    
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
      calendar_url(:date => date, :view => "month")
    end

    def url_for_date(date)
      calendar_url(:date => date, :view => "day")      
    end
    
    def day_names
      ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    end
    
  end
end
