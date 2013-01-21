module Droom
  class SuggestionsController < Droom::EngineController
    respond_to :json, :js
    before_filter :authenticate_user!
    before_filter :get_current_person
    before_filter :get_classes
    
    def index
      fragment = params[:term]
      max = params[:limit] || 10
      if @types.include?('event') && fragment.length > 6 && span = Chronic.parse(fragment, :guess => false)
        @suggestions = Droom::Event.falling_within(span).visible_to(@current_person)
      else
        @suggestions = @klasses.collect {|klass|
          klass.constantize.visible_to(@current_person).name_matching(fragment).limit(max.to_i)
        }.flatten.sort_by(&:name).slice(0, max.to_i)
        # @suggestions = @klasses.collect {|klass|
        #   klass.constantize.visible_to(@current_person).search{
        #     fulltext fragment
        #     order_by :score, :desc
        #   }.results
        # }.flatten.slice(0, max.to_i)
      end

      respond_with @suggestions do |format|
        format.json {
          render :json => @suggestions.map(&:as_suggestion).to_json
        }
        format.js {
          render :partial => "droom/shared/suggestions"
        }
      end
    end

  protected

    def get_classes
      suggestible_classes = Droom.suggestible_classes
      requested_types = [params[:type]].flatten.compact.uniq
      requested_types = %w{event person document group venue} if requested_types.empty?

      logger.warn ">>> requested_types is #{requested_types.inspect}"
      
      @types = suggestible_classes.keys & requested_types
      logger.warn ">>> @types is #{@types.inspect}"

      @klasses = suggestible_classes.values_at(*@types)
    end

  end
end
