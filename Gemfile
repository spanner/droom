source "http://rubygems.org"

# Declare your gem's dependencies in droom.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# jquery-rails is used by the dummy application
gem "jquery-rails"
gem "haml"

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'compass-rails'
  gem 'therubyracer', :platforms => :ruby
  gem 'uglifier', '>= 1.0.3'
end

group :test, :development do
  gem 'haml'
  gem 'paperclip', "~> 3.1.0"
  gem 'combustion', '~> 0.3.1'
  gem "rspec-rails", "~> 2.0"
  gem 'factory_girl_rails'
  gem 'shoulda-matchers'
  gem 'awesome_print'
end