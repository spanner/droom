module Droom
  class DocumentAttachmentsController < Droom::EngineController
    respond_to :html, :js
    layout :no_layout_if_pjax
    before_filter :get_group, :only => :destroy

    def destroy
      @document_attachment.destroy
      head :ok
    end

  protected

    def get_group
      @document_attachment = Droom::DocumentAttachment.find(params[:id])
    end
    
  end
end
