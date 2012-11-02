# This migration comes from droom (originally 20121012163201)
class CategorySlugs < ActiveRecord::Migration
  def change
    add_column :droom_categories, :slug, :string
  end
end
