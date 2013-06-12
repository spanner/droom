module Droom
  class YoutubeController < Droom::EngineController
    respond_to :js, :json
    before_filter :authenticate_user!
    layout nil

    def show
      @video = Droom.yt_client.video_by(params[:yt_id])
      respond_with @video
    end

    def index
      fragment = params[:term]
      max = params[:limit] || 10
      @suggestions = []
      unless fragment.blank?
        videos = Droom.yt_client.videos_by(:query => fragment, :per_page => max).videos.to_a
        @suggestions = videos.map { |vid|
          vid.as_json.slice('unique_id', 'title', 'description', 'thumbnails').merge({"type" => "video"})
        }
      end
      respond_with @suggestions
    end
  end
end
