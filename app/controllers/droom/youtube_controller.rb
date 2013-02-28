module Droom
  class YoutubeController < Droom::EngineController
    respond_to :js, :json
    before_filter :authenticate_user!
    before_filter :get_current_person
    before_filter :find_video, :only => :show
    before_filter :find_videos, :only => :index

    def show
      respond_with @video do |format|
        format.json {
          render :json => @video
        }
        format.js {
          render :partial => "droom/shared/yt_video"
        }
      end
    end

    def index
      
    end

  protected

    def find_video
      yt_id = params[:yt_id]
      vid = Droom.yt_client.video_by(yt_id)
      @video = {
        :title => vid.title,
        :yt_id => vid.unique_id,
        :thumb_url => vid.thumbnails[2].url,
        :mini_thumbs => [
          vid.thumbnails[0].url,
          vid.thumbnails[3].url,
          vid.thumbnails[4].url,
          vid.thumbnails[5].url
        ]
      }
    end

    def find_videos
      
    end

  end
end
