# Pages are currently just minimal text-holders. The text is entered in markdown, 
# rendered on save and placed into the usual layout.
#
module Droom
  class Page < ActiveRecord::Base
    before_validation :check_slug
    before_save :render_body
    validates :slug, :uniqueness => true, :presence => true
    validates :title, :presence => true
    default_scope order('title ASC')
  
  protected

    def check_slug
      ensure_presence_and_uniqueness_of(:slug, title.parameterize)
    end
  
    def render_body
      markdown = RDiscount.new(self.body)
      self.rendered_body = markdown.to_html
    end
  end
end