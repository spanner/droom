module Droom
  class SuggestionsController < Droom::EngineController
    respond_to :json, :js
    before_filter :authenticate_user!
    before_filter :get_classes
    
    def index
      fragment = params[:term]
      max = params[:limit] || 10
      show_when_empty = params[:empty] == "all"
      if !show_when_empty && fragment.blank?
        @suggestions = []
      else
        if @types.include?('event') && fragment.length > 6 && span = Chronic.parse(fragment, :guess => false)
          @suggestions = Droom::Event.falling_within(span).visible_to(current_user)
          @title = span.width > 86400 ? "Events in #{fragment}" : "Events on #{fragment}"
        else
          @suggestions = @klasses.collect {|klass|
            klass.constantize.visible_to(current_user).matching(fragment).limit(max.to_i)
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
      requested_types = [params[:type]].flatten.compact.uniq
      requested_types = Droom.suggestible_classes.keys if requested_types.empty?
      @types = suggestible_classes.keys & requested_types
      @klasses = suggestible_classes.values_at(*@types)
    end

  end
end
