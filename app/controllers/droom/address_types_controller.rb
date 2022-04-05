# Address book data is always nested. Here we are only providing add-item form partials through #new.
#
module Droom
  class AddressTypesController < Droom::DroomController
    load_and_authorize_resource

    def index
      respond_with @address_types
    end

    def show
      respond_with @address_type
    end

    def new
      respond_with @address_type
    end

    def create
      @address_type.update(address_type_params)
      respond_with @address_type
    end

    def edit
      respond_with @address_type
    end
    
    def update
      @address_type.update(address_type_params)
      respond_with @address_type
    end

    def destroy
      @address_type.destroy
      head :ok
    end

    protected

    def address_type_params
      params.require(:address_type).allow(:name)
    end

  end
end