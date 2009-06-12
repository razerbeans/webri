require 'webri/engine'

module WebRI

  class Server < Engine

    # Reference to CGI Service
    #attr :cgi

    #def initialize(service)
    #  @cgi = {} #CGI.new('html4')
    #  @service = service
    #end

    #def directory
    #  File.dirname(__FILE__)
    #end

=begin
    def heirarchy
      ns = Heirarchy.new(nil)
      service.names.each do |m|
        if m.index('#')
          type = :instance
          space, method = m.split('#')
          spaces = space.split('::').collect{|s| s.to_sym }
          method = method.to_sym
        elsif m.index('::')
          type = :class
          spaces = m.split('::').collect{|s| s.to_sym }
          if spaces.last.to_s =~ /^[a-z]/
            method = spaces.pop
          else
            next # what to do about class/module ?
          end
        else
          next # what to do abot class/module ?
        end

        memo = ns
        spaces.each do |space|
          memo[space] ||= NS.new(space, memo)
          memo = memo[space]
        end

        if type == :class
          memo.class_methods << method
        else
          memo.instance_methods << method
        end
      end
      return ns
    end
=end

    #
    def tree
      @tree ||= heirarchy.to_html
    end

=begin
    #
    def lookup(req)
      keyw = File.basename(req.path_info)
      if keyw
        keyw.sub!('-','#')
        html = service.info(keyw)
#puts html
        #term = AnsiSys::Terminal.new.echo(ansi)
        #html = term.render(:html) #=> HTML fragment
        #html = ERB::Util.html_escape(html)
        html = "#{html}"
      else
        html = "<h1>ERROR</h1>"
      end
      return html
    end
=end

    #def template_source
    #  @template_source ||= File.read(File.join(File.dirname(__FILE__), 'template.rhtml'))
    #end

    #def to_html
    #  #filetext = File.read(File.join(File.dirname(__FILE__), 'template.rhtml'))
    #  template = ERB.new(template_source)
    #  template.result(binding)
    #  #heirarchy.to_html
    #end

  end

end

