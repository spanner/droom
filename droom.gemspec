$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "droom/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "droom"
  s.version     = Droom::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Droom."
  s.description = "TODO: Description of Droom."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 3.2.8"
  s.add_dependency "jquery-rails"
  s.add_dependency 'paperclip', "~> 3.1.0"
  s.add_dependency 'enumerize'
  s.add_dependency 'geokit-rails3'
  s.add_dependency 'chronic'
  s.add_dependency 'time_of_day'
  s.add_dependency 'kaminari'
  s.add_dependency 'haml'
  s.add_dependency "uuidtools"
  s.add_dependency "date_validator"
  s.add_dependency "dav4rack"
  s.add_dependency "ri_cal"
  s.add_dependency "snail"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "shoulda-matchers", "~>1.0"#, "~> 3.0"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "database_cleaner"
end
