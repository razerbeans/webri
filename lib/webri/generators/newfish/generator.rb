require 'webri/generators/abstract'
require 'webri/components/icons'
require 'webri/components/highlight'
require 'webri/components/subversion'

module WebRI

  # = Newfish Template
  #
  # Newfish is very much like Redfish, but with a cleaner
  # look and feel, eg. no red.
  #
  class Newfish < Generator

    include Icons
    include Highlight
    include Subversion

  end

end

