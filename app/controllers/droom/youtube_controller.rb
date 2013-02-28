module Droom
  class YoutubeController < Droom::EngineController
    respond_to :js
    before_filter :authenticate_user!
    before_filter :find_video, :only => :show
    before_filter :find_videos, :only => :index

    def show
      respond_with @video do |format|
        format.js { render :partial => "droom/shared/yt_video" }
      end
    end

    def index
      
    end

  protected

    def find_video
      yt_id = params[:yt_id]
      @video = Droom.yt_client.video_by(yt_id)
    end

    def find_videos
      
    end

  end
end
