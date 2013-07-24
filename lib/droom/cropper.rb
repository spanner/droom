require "paperclip"
require "paperclip/validators/attachment_height_validator"
require "paperclip/validators/attachment_width_validator"
require "paperclip/geometry_transformation"
require "paperclip_processors/offset_thumbnail"

# For inclusion into any model class with a croppable image. Turns crop values into Imagemagick `convert` paramaters.
#
module Paperclip::Croppable
  # Offset+crop geometry is taken from model attributes at runtime
  # and scaled up by the resolution_multiplier to produce the larger images required by high resolution screens on mobile devices.
  #
  def scale_geometry
    "#{image_scale_width * Settings.resolution_multiplier}x"
  end

  def crop_geometry
    "%dx%d%+d%+d" % [image_scale_width, image_scale_height, -image_offset_left, -image_offset_top].map {|x| x * Settings.resolution_multiplier}
  end
  
end