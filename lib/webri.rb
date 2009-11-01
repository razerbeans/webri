#$:.unshift File.dirname(__FILE__)

begin
  require "rubygems"
  gem "rdoc", ">= 2.4.2"

  require "rdoc/rdoc"

  module WebRI
    LOADPATH = File.dirname(__FILE__)
    VERSION  = "1.0.0"  #:till: VERSION="<%= version %>"
  end

  require "rdoc/c_parser_fix"

  unless defined? $WEBRI_FIXED_RDOC_OPTIONS
    $WEBRI_FIXED_RDOC_OPTIONS = 1

    class RDoc::Options
      #alias_method :rdoc_initialize, :initialize
      #def initialize
      #  rdoc_initialize
      #  @generator = RDoc::Generator::RDazzle
      #end

      alias_method :rdoc_parse, :parse

#FIXME: look up templates dynamically

      def parse(argv)
        rdoc_parse(argv)
        if %w{redfish twofish blackfish longfish onefish}.include?(@template)
          require "webri/generators/#{template}"
          @generator = WebRI.const_get(@template.capitalize)
        end
      end
    end

  end

rescue Exception

  warn "WebRI requires RDoc v2.4.2 or greater."

end

