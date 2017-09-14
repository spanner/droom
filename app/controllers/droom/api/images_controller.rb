module Droom::Api
  class ImagesController < Droom::Api::ApiAssetsController

    before_action :get_images, only: [:index]
    load_and_authorize_resource via: :current_user

    def index
      render json: @images
    end

    def show
      render json: @image
    end

    def update
      if @image.update_attributes(image_params)
        render json: @image
      else
        render json: {
          errors: @image.errors.to_a
        }
      end
    end

    def create
      @image.user = current_user
      if @image.save
        render json: @image
      else
        render json: {
          errors: @image.errors.to_a
        }
      end
    end

    def destroy
      @image.destroy
      head :ok
    end

  protected

    def get_images
      if current_user.admin?
        @images = Image.order(created_at: :desc)
      else
        @images = paginated(current_user.images.order(created_at: :desc))
      end
    end

    def image_params
      params.require(:image).permit(:file, :caption)
    end

  end
end