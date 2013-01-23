module Droom
  class SearchController < Droom::EngineController
    respond_to :json, :js, :html
    before_filter :authenticate_user!
    before_filter :get_current_person
    before_filter :get_classes

    def index
      if @fragment = params[:term]
        frag = @fragment.force_encoding("US-ASCII")
        # if the search box isn't empty
        @results = []
        unless frag == ""
          max = params[:limit] || 10
          classes = @klasses.collect {|klass| klass.constantize}
          search = Sunspot.search classes do
            fulltext frag do
              highlight :description
              highlight :extracted_text
            end
          end
          search.each_hit_with_result do |hit, result|
            result[:hit] = hit
            @results.push result
          end
          
        else
          @results = []
        end
      end
      respond_with @results do |format|
        format.html {
          render "droom/shared/search"
        }
        format.json {
          render :json => @results.map(&:as_search_result).to_json
        }
        format.js {
          render :partial => "droom/shared/search_results"
        }
      end
    end

  protected

    def get_classes
      searchable_classes = Droom.searchable_classes
      requested_types = [params[:type]].flatten.compact.uniq
      requested_types = %w{event document group venue} if requested_types.empty?

      logger.warn ">>> requested_types is #{requested_types.inspect}"

      @types = searchable_classes.keys & requested_types
      logger.warn ">>> @types is #{@types.inspect}"

      @klasses = searchable_classes.values_at(*@types)
    end

  end
end
