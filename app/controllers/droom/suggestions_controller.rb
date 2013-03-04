module Droom
  class SuggestionsController < Droom::EngineController
    respond_to :json, :js
    before_filter :authenticate_user!
    before_filter :get_classes
    
    def index
      fragment = params[:term]
      max = params[:limit] || 10
      if fragment.blank?
        @suggestions = []
      else
        if @types.include?('event') && fragment.length > 6 && span = Chronic.parse(fragment, :guess => false)
          @suggestions = Droom::Event.falling_within(span).visible_to(current_person)
          @title = span.width > 86400 ? "Events in #{fragment}" : "Events on #{fragment}"
        else
          @suggestions = @klasses.collect {|klass|
            logger.warn ">>> getting #{klass}"
            klass.constantize.visible_to(current_person).matching(fragment).limit(max.to_i)
          }.flatten.sort_by(&:name).slice(0, max.to_i)
        end
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
      logger.warn ">>> suggestible_classes is #{suggestible_classes.inspect}"
      
      requested_types = [params[:type]].flatten.compact.uniq
      requested_types = Droom.suggestible_classes.keys if requested_types.empty?
      @types = suggestible_classes.keys & requested_types
      logger.warn ">>> @types is #{@types.inspect}"

      @klasses = suggestible_classes.values_at(*@types)
    end

  end
end
