require 'webri/generators/abstract'
require 'webri/components/subversion'

module WebRI

  #
  class Redfish < Generator

    include Subversion

    #
    def path
      @path ||= Pathname.new(__FILE__).parent
    end

    #
    #def generate_template
    #  super
    #end

  end

end

