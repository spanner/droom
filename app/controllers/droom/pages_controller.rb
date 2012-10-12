class PagesController < ApplicationController
  respond_to :html
  before_filter :require_admin!, :except => [:index, :show]
  before_filter :get_pages, :only => [:show, :index, :admin]
  before_filter :get_page, :only => [:show, :edit, :update, :destroy]
  before_filter :build_page, :only => [:new, :create]
  
  def index
    respond_with(@pages)
  end

  def show
    respond_with(@page)
  end

  def new
    respond_with(@page)
  end

  def create
    @page.update_attributes(params[:page])
    respond_with(@page)
  end

  def edit
    respond_with(@page)
  end

  def update
    @page.update_attributes(params[:page])
    respond_with(@page)
  end

protected

  def get_pages
    @show = params[:show] || 20
    @p = params[:page] || 1
    @pages = Page.page(@p).per(@show) unless @show == 'all'
  end
  
  def get_page
    @page = Page.find_by_slug(params[:slug]) || Page.find(params[:id])
  end

  def build_page
    @page = Page.new
  end
end