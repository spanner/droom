## Ajax transport
#
# We extend the standard rails jquery-ujs method with a standard response and failure handler. All our
# remote operations are channelled through this class and use callbacks to affect the page during and 
# after the request.
#
# This isn't very clever or complicated but it gives us a standard channel that handles requests in a 
# consistent way. It applies a PJAX header and defines a simple callback interface that makes the rest 
# of our code more readable. In most cases it also allows us to omit the [data-remote] and [data-type] 
# attributes from links.
#
# ### Callbacks
#
# * *on_prepare* is called when the remote control is first created. No arguments.
# * *on_request* is called before the remote call. Arguments: [event, xhr, settings]
# * *on_error* is called if the server returns an error. Arguments: [event, xhr, status]
# * *on_success* is called if the request is successful. First argument is the server response.
# * *on_complete* is called after the request, whether successful or not. No arguments. 
#
jQuery ($) ->
  class Remote
    constructor: (element, opts) ->
      @_control = $(element)
      @_options = $.extend {}, opts
      @_control.attr('data-remote', true)
      @_control.attr('data-type', 'html')
      @_control.on 'ajax:beforeSend', @pend
      @_control.on 'ajax:error', @fail
      @_control.on 'ajax:success', @receive
      @activate()
        
    activate: () => 
      @_control.find('a.cancel').click @cancel
      @_options.on_prepare?()

    pend: (event, xhr, settings) =>
      event.stopPropagation()
      xhr.setRequestHeader('X-PJAX', 'true')
      @_control.addClass('waiting')
      @_options.on_request?()

    fail: (event, xhr, status) ->
      event.stopPropagation()
      @_control.removeClass('waiting').addClass('erratic')
      @_options.on_error?(event, xhr, status)
      @_options.on_complete?()
  
    # Note that there is no special provision here for a server side failure that results in a success response:
    # eg if validation fails and we get the form back again, this Remote will be considered successful and disappear.
    # In that case the function which triggered the remote operation is expected to do the right thing with the 
    # returned html. Usually in that kind of situation you'd be using a popup, which checks for a returned form and
    # treats it as another iteration within the same window.
    #
    receive: (event, response, status) =>
      event.stopPropagation()
      @_control.removeClass('waiting')
      @_options.on_success?(response)
      @_options.on_complete?()
        
    cancel: (e) =>
      e.preventDefault() if e
      @_options.on_cancel()
      @_form.remove()

  $.fn.remote = (opts) ->
    @each ->
      new Remote @, opts 

  # *replace_with_remote_content* is a useful shortcut for links and forms that should simply be replaced with the
  # result of their action.
  #
  $.fn.replace_with_remote_content = (selector) ->
    selector ?= '.reviewer'
    @each ->
      $(@).remote
        on_complete: (r) =>
          replaced = $(@).parents(selector).first()
          replacement = $(r).insertAfter(replaced)
          replaced.remove()
          replacement.activate()

