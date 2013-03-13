module Droom
  class SearchController < Droom::EngineController
    respond_to :json, :js, :html
    before_filter :authenticate_user!
    before_filter :get_classes
    before_filter :get_fields

    def index
      @results = []
      if @fragment = params[:term]
        @page = params[:page] || 1
        frag = @fragment.force_encoding("US-ASCII")
        # if term isn't empty
        unless frag == ""
          classes = Droom.searchable_classes.values.collect {|klass| klass.constantize}
          highlights = @highlights.collect {|field| field.to_sym}
          # search the searchable classes
          # highlight matching words from highlightable fields
          search = Sunspot.search classes do
            fulltext frag do
              highlights.each do |hl|
                highlight hl
              end
              with visible_to?(current_person)
            end
            paginate :page => @page, :per_page => 10
          end
          # push the hits (for retrieving highlights) into the search results
          search.each_hit_with_result do |hit, result|
            if @requested_types.include? result.class.to_s
              result[:hit] = if hit.highlights.length > 0 then hit else nil end
              @results.push result
            end
          end
        end
      end
      respond_with @results do |format|
        format.html { render "droom/shared/search" }
        format.json { render :json => @results.map(&:as_search_result).to_json }
        format.js { render :partial => "droom/shared/search_results" }
      end
    end

  protected

    def get_fields
      @highlights = []
      @requested_types.each do |klass|
        klass.constantize.highlight_fields.each do |hlf|
          @highlights.push hlf unless @highlights.include? hlf
        end
      end
    end

    def get_classes
      searchable_classes = Droom.searchable_classes
      @types = [params[:type]].flatten.compact.uniq
      @types = searchable_classes.keys if @types.empty?

      logger.warn ">>> requested_types is #{@types.inspect}"

      @requested_types = searchable_classes.values_at(*@types)
    end

  end
end
