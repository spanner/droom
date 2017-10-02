## Configuration
#
# The Config is a simple config-by-environment mechanism. It's only one level deep:
# basically a list of default settings that can be overridden for each environment,
# and some regexes for detecting the environment in which we are running.

class Ed.Config
  defaults: 
    api_url: "/api"
    logging: false
    trap_errors: true
    display_errors: false
    badger_errors: true

  production:
    display_errors: false
    badger_errors: true
    logging: false

  staging:
    display_errors: true
    badger_errors: true
    trap_errors: false

  development:
    logging: false
    display_errors: true
    badger_errors: false
    trap_errors: false

  constructor: (options={}) ->
    options.environment ?= @guessEnvironment()
    @_settings = _.defaults options, @[options.environment], @defaults

  guessEnvironment: () ->
    stag = new RegExp(/staging/)
    dev = new RegExp(/\.dev/)
    href = window.location.href
    if stag.test(href)
      "staging"
    else if dev.test(href)
      "development"
    else
      "production"

   settings: =>
     @_settings

   get: (key) =>
    @_settings[key]