require 'paperclip'
require 'open-uri'

# This is a minimal alteration of the FileAdapter to go and retrieve the file first. All we have to do is 
# dump our retrieved IO object to a templfile and the rest of the paperclip adapter can kick in.

module Paperclip
  class UrlAdapter < FileAdapter
    
    # open() creates a tempfile, so all we need to do here is remember which one it created.
    #
    def initialize(target)
      @target = target.sub(/\?\d+$/, '')
      @tempfile = open(target)
    end

    # original_filename returns the base name we should use when saving this file.
    #
    def original_filename
      File.basename(@target)
    end

  end
end

Paperclip.io_adapters.register Paperclip::UrlAdapter do |target|
  String === target
end
