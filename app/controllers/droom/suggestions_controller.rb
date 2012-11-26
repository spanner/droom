module Droom
  class SuggestionsController < Droom::EngineController
    respond_to :json, :js
    before_filter :authenticate_user!
    before_filter :get_current_person
    before_filter :get_classes

    @@searchable_classes = {
      "event" => "Droom::Event", 
      "person" => "Droom::Person", 
      "document" => "Droom::Document",
      "group" => "Droom::Group",
      "venue" => "Droom::Venue"
    }

    cattr_accessor :searchable_classes
    
    def index
      fragment = params[:term]
      max = params[:limit] || 10

      if @types.include?('event') && span = Chronic.parse(fragment, :guess => false)
        @suggestions = Droom::Event.falling_within(span).visible_to(@current_person)

      else
        @suggestions = @klasses.collect {|klass| 
          klass.constantize.visible_to(@current_person).name_matching(fragment).limit(max)
        }.flatten.sort_by(&:name).slice(0, max)
      end

      respond_with @suggestions do |format|
        format.json {
          render :json => @suggestions.map { |suggestion| {
            :type => suggestion.identifier,
            :text => suggestion.name,
            :id => suggestion.id
          }}.to_json
        }
        format.js {
          render :partial => "droom/shared/suggestions"
        }
      end
    end

  protected

    def get_classes
      if params[:type].blank?
        @types = self.class.searchable_classes.keys
        @klasses = self.class.searchable_classes.values
      else
        @types = self.class.searchable_classes.keys & [params[:type]].flatten
        @klasses = self.class.searchable_classes.values_at(*@types)
      end
    end

  end
end