class CategorySlugs < ActiveRecord::Migration
  def change
    add_column :droom_categories, :slug, :string
  end
end
