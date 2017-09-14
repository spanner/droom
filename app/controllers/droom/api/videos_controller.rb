module Droom::Api
  class VideosController < Droom::Api::ApiAssetsController

    before_action :get_videos, only: [:index]
    load_and_authorize_resource class: "Droom::Video", via: :current_user

    def index
      render json: @videos
    end

    def show
      render json: @video
    end

    def update
      if @video.update_attributes(video_params)
        render json: @video
      else
        render json: {
          errors: @video.errors.to_a
        }
      end
    end

    def create
      @video.user = current_user
      if @video.save
        render json: @video
      else
        render json: {
          errors: @video.errors.to_a
        }
      end
    end

    def destroy
      @video.destroy
      head :ok
    end

  protected

    def get_videos
      if current_user.admin?
        @videos = Droom::Video.order(created_at: :desc)
      else
        @videos = paginated(current_user.videos.order(created_at: :desc))
      end
    end

    def video_params
      params.require(:video).permit(:file, :remote_url, :caption)
    end

  end
end