source "http://rubygems.org"

# Declare your gem's dependencies in droom.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# jquery-rails is used by the dummy application
gem "jquery-rails"
gem "haml"
gem "geocoder"
gem "paperclip", '~> 3.1.0'
gem "debugger"
gem "ri_cal", :git => "git://github.com/quasor/ri_cal.git"
gem "date_validator"
gem 'time_of_day'
gem "rubyzip"
gem "snail"
gem "vcard"
gem "chronic"
gem "dynamic_form"
gem 'acts_as_list'
gem 'rdiscount'
gem 'ancestry'
gem 'dropbox-sdk'

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'compass-rails'
  gem 'therubyracer', :platforms => :ruby
  gem 'uglifier', '>= 1.0.3'
end

group :test, :development do
  gem 'mysql2'
  gem 'haml'
  gem 'paperclip', "~> 3.1.0"
  gem "capybara"
  gem "rspec-rails", "~> 2.0"
  gem 'watchr'
  gem 'spork'
  gem 'factory_girl_rails'
  gem "database_cleaner"
  gem 'shoulda-matchers'
  gem 'awesome_print'
end