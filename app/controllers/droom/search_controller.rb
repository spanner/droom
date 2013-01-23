module Droom
  class SearchController < Droom::EngineController
    respond_to :json, :js, :html
    before_filter :authenticate_user!
    before_filter :get_current_person
    before_filter :get_classes

    def index
      if @fragment = params[:term]
        max = params[:limit] || 10
        @results = @klasses.collect {|klass|
          search = klass.constantize.visible_to(@current_person).search{
            fulltext @fragment
          }.results
          # search.each do |hit|
          #   hit.highlights.each do |highlight|
          #     highlight.format {|word| "<b>#{word}</b>"}
          #   end
          # end          
        }.flatten.slice(0, max.to_i)
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
      requested_types = %w{event person document group venue} if requested_types.empty?

      logger.warn ">>> requested_types is #{requested_types.inspect}"

      @types = searchable_classes.keys & requested_types
      logger.warn ">>> @types is #{@types.inspect}"

      @klasses = searchable_classes.values_at(*@types)
    end

  end
end
