module Droom
  class SuggestionsController < Droom::EngineController
    respond_to :json, :js
    before_filter :authenticate_user!
    before_filter :get_current_person
    before_filter :get_classes
    
    def index
      fragment = params[:term]
      max = params[:limit] || 10
      if @types.include?('event') && span = Chronic.parse(fragment, :guess => false)
        @suggestions = Droom::Event.falling_within(span).visible_to(@current_person)
      else
        logger.warn ">>> suggestion types: #{@types.inspect}"
        logger.warn ">>> suggestion klasses: #{@klasses.inspect}"
        @suggestions = @klasses.collect {|klass|
          klass.constantize.visible_to(@current_person).name_matching(fragment).limit(max.to_i)
        }.flatten.sort_by(&:name).slice(0, max.to_i)
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
      logger.warn ">>> searchable types: #{suggestible_classes.keys.inspect}"
      logger.warn ">>> type: #{params[:type].inspect}"
      
      if params[:type].blank?
        @types = suggestible_classes.keys
        @klasses = suggestible_classes.values
      else
        @types = suggestible_classes.keys & [params[:type]].flatten
        @klasses = suggestible_classes.values_at(*@types)
      end
    end

  end
end
