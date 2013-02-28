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
      elsif params[:type] and params[:type] == "video"
        videos = Droom.yt_client.videos_by(:query => fragment, :per_page => max).videos
        @suggestions = []
        videos.each do |vid|
          sug = {
            :type => 'video',
            :prompt => vid.title,
            :value => vid.unique_id,
            :thumb_url => vid.thumbnails[2].url,
            :mini_thumbs => [
              vid.thumbnails[0].url,
              vid.thumbnails[3].url,
              vid.thumbnails[4].url,
              vid.thumbnails[5].url
            ]
          }
          @suggestions.push sug
        end
      else
        if @types.include?('event') && fragment.length > 6 && span = Chronic.parse(fragment, :guess => false)
          @suggestions = Droom::Event.falling_within(span).visible_to(current_person)
          @title = span.width > 86400 ? "Events in #{fragment}" : "Events on #{fragment}"
        else
          @suggestions = @klasses.collect {|klass|
            klass.constantize.visible_to(current_person).matching(fragment).limit(max.to_i)
          }.flatten.sort_by(&:name).slice(0, max.to_i)
        end
      end
      respond_with @suggestions do |format|
          
        format.json {
          if params[:type] == "video"
            render :json => @suggestions.to_json
          else
            render :json => @suggestions.map(&:as_suggestion).to_json
          end
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
