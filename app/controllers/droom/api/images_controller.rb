require 'active_model_serializers'

module Droom::Api
  class ImagesController < Droom::Api::ApiAssetsController

    before_action :get_images, only: [:index]
    load_and_authorize_resource class: "Droom::Image", via: :current_user

    def index
      render json: ActiveModel::Serializer::CollectionSerializer.new(@images, serializer: Droom::ImageSerializer)
    end

    def show
      return_image
    end

    def update
      if @image.update_attributes(image_params)
        return_image
      else
        return_errors
      end
    end

    def create
      @image.user = current_user
      if @image.save
        return_image
      else
        return_errors
      end
    end

    def destroy
      @image.destroy
      head :ok
    end

    def return_image
      render json: @image, serializer: Droom::ImageSerializer
    end

    def return_errors
      render json: {
        errors: @image.errors.to_a
      }
    end

    protected

    def get_images
      if current_user.admin?
        @images = Droom::Image.order(created_at: :desc)
      else
        @images = paginated(current_user.images.order(created_at: :desc))
      end
    end

    def image_params
      params.require(:image).permit(:file, :file_name, :remote_url, :caption)
    end

  end
end