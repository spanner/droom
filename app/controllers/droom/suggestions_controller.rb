module Droom
  class SuggestionsController < Droom::EngineController
    respond_to :json, :js
    before_filter :authenticate_user!
    before_filter :get_classes

    def index
      fragment = params[:term]
      max = params[:limit] || 10

      if @types.include?('event') && span = Chronic.parse(fragment, :guess => false)
        @suggestions = Droom::Event.falling_within(span)
      
      else
        @suggestions = @klasses.collect {|klass| 
          klass.constantize.name_matching(fragment).limit(max) 
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
        @types = searchable_classes.keys
        @klasses = searchable_classes.values
      else
        @types = searchable_classes.keys & [params[:type]].flatten
        @klasses = searchable_classes.values_at(*@types)
      end
    end
  
    def searchable_classes
      {
        "event" => "Droom::Event", 
        "person" => "Droom::Person", 
        "document" => "Droom::Document",
        "venue" => "Droom::Venue"
      }
    end
    
  end
end