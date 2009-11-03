require 'webri/generators/abstract'
require 'webri/components/icons'
require 'webri/components/subversion'

module WebRI

  # = Redfish Template
  #
  # Redfish is based on RDoc's default Darkfish generator,
  # heavily modified to provide only a single sidebar con
  # document layout. And, as the name indicates, colorized
  # to be red (instead of green).
  #
  # You can thank Darkfish, a by extension Redfish, for the
  # "-fish" naming scheme :)
  #
  class Newfish < Generator

    include Icons
    include Subversion

  end

end

