require 'webri/abstract/generator'
require 'webri/subversion/component'

module WebRI

  #
  class Redfish < Abstract::Generator

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

