module WebRI

  # = Abstract Generator Component
  #
  class Component

    #

    attr :generator

    # New component instance. Components require the generator
    # they are augmenting.

    def initialize(generator)
      @generator = generator
      initialize_methods
    end

    # Path to the component. This should be defined in the
    # subclass as:
    #
    #  def path
    #   @path ||= Pathname.new(__FILE__).parent
    #  end
    #
    def path
      raise "Must be implemented by subclass!"
    end

    # Subcomponents use this to setup template provisions.
    #
    #   def initialize_methods
    #     provide :svninfo
    #   end
    #
    # See the #provide method.

    def initialize_methods
    end

    # This is the method that is called by the generator,
    # allowing the component in turn to generate the
    # files it needs. By default this copies the components
    # <tt>static</tt> directory.

    def generate
      generate_static
    end

    # Copy static files to output. All the common static content is
    # stored in the <tt>assets/</tt> directory. WebRI's <tt>assets/</tt>
    # directory more or less follows an <i>Abbreviated Monash</i> convention:
    #
    #   assets/
    #     css/      <- stylesheets
    #     json/     <- json data table (*maybe top level is better?)
    #     img/      <- images
    #     inc/      <- server-side includes
    #     js/       <- javascripts
    #
    # Components can utilize this method by providing a +path+.

    def generate_static
      from = Dir[(path_static + '**').to_s]
      dest = path_output.to_s
      show_from = path_static.to_s.sub(path.parent.to_s+'/', '')
      debug_msg "Copying #{show_from}/** to #{path_output_relative}:"
      fileutils.cp_r from, dest, :preserve => true
    end

    #

    def method_missing(s, *a, &b)
      generator.__send__(s,*a,&b)
    end      

    #

    def path_static
      path + 'static'
    end

    # Provide a method interface(s) to the generator. This extends
    # the generator's context with component methods. Since
    # ERB templates are rendering in the generator scope, this
    # is useful when a component needs to provide method access
    # to templates.

    def provision(method, &block)
      if block
        generator.provision(method, &block)
      else
        generator.provision(method) do |*a, &b|
          __send__(method, *a, &b)
        end
      end
    end

    # Output progress information if rdoc debugging is enabled

    def debug_msg(msg)
      return unless $DEBUG_RDOC
      case msg[-1,1]
        when '.' then tab = "= "
        when ':' then tab = "== "
        else          tab = "* "
      end
      $stderr.puts(tab + msg)
    end

  end

end

