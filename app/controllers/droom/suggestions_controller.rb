module Droom
  class SuggestionsController < Droom::DroomController
    respond_to :html, :json, :js
    layout false
    before_action :get_classes

    def index
      authorize! :index, :suggestions
      fragment = params[:term]
      max = params[:limit] || 20
      show_when_empty = params[:empty] == "all"

      Rails.logger.warn("🚘 fragment: #{fragment}")

      if !show_when_empty && fragment.blank?
        @suggestions = []
      else
        if @types.include?('event') && fragment.length > 6 && span = Chronic.parse(fragment, :guess => false)
          @suggestions = Droom::Event.falling_within(span).accessible_by(current_ability)
          @title = span.width > 1.day ? "Events in #{fragment}" : "Events on #{fragment}"
        else
          @suggestions = Searchkick.search fragment, models: @klasses, match: :word_start, limit: max, load: false
        end
      end

      Rails.logger.warn("🚘 @suggestions: #{@suggestions.inspect}")

      respond_with @suggestions do |format|
        format.json {
          serialized = @suggestions.map do |sugg|
            klass = sugg._type.classify.constantize
            serialized = klass.serialize_suggestion(sugg)
            # conform to the old suggestion interface by returning only the list of records
            serialized['data']['attributes']
          end
          render :json => serialized
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
      @klasses = suggestible_classes.values_at(*@types).map(&:constantize)
    end

  end
end
