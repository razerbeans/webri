require 'erb'
require 'yaml'

module WRI

  class Server

    # Reference to CGI Service
    attr :cgi

    # Reference to RI Service
    attr :service

    def initialize(service)
      @cgi = {} #CGI.new('html4')
      @service = service
    end

    def directory
      File.dirname(__FILE__)
    end

    def heirarchy
      ns = NS.new(nil)
      service.names.each do |m|
        if m.index('#')
          type = :instance
          space, method = m.split('#')
          spaces = space.split('::').collect{|s| s.to_sym }
          method = method.to_sym
        elsif m.index('::')
          type = :class
          space, method = m.split('::')
          spaces = space.split('::').collect{|s| s.to_sym }
          if spaces.last =~ /^[a-z]/
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

    def tree
      @tree ||= heirarchy.to_html
    end

    def lookup(req)
      keyw = File.basename(req.path_info)
      if keyw
        keyw.sub!('-','#')
        html = service.info(keyw)
puts html
        #term = AnsiSys::Terminal.new.echo(ansi)
        #html = term.render(:html) #=> HTML fragment
        #html = ERB::Util.html_escape(html)
        html = "#{html}"
      else
        html = "<h1>ERROR</h1>"
      end
      return html
    end

    def to_html
      filetext = File.read(File.join(File.dirname(__FILE__), 'template.rhtml'))
      template = ERB.new(filetext)
      template.result(binding)
      #heirarchy.to_html
    end

    #

    class NS
      attr :name
      attr :parent
      attr :subspaces
      attr :instance_methods
      attr :class_methods

      def initialize(name, parent=nil)
        @name = name
        @parent = parent if NS===parent
        @subspaces = {}
        @class_methods = []
        @instance_methods = []
      end

      def key
        full_name
      end

      def [](name)
        @subspaces[name]
      end

      def []=(name, value)
        @subspaces[name] = value
      end

      def root?
        !parent
      end

      def full_name
        if root?
          nil
        else
          [parent.full_name, name].compact.join("::")
        end
      end

      def to_html
        markup = []
        if root?
          markup << %[<div class="root">]
        else
          markup << %[
           <li class="trigger">
             <img src="img/dir.gif" onClick="showBranch(this);"/>
             <span class="link" onClick="lookup(this, '#{full_name}');">#{name}</span>
          ]
          markup << %[<div class="branch">]
        end

        markup << %[<ul>]
        class_methods.each do |method|
          markup << %[
            <li class="leaf"> 
              <span class="link" onClick="lookup(this, '#{full_name}::#{method}');">#{method}</span>
            </li>
          ]
        end

        instance_methods.each do |method|
          markup << %[
            <li class="leaf"> 
              <span class="link" onClick="lookup(this, '#{full_name}-#{method}');">#{method}</span>
            </li>
          ]
        end

        subspaces.to_a.sort{ |a,b| a[0].to_s <=> b[0].to_s }.each do |(name, subspace)|
        #subspaces.each do |name, subspace|
          markup << subspace.to_html
        end
        markup << %[</ul>]

        if root?
          markup << %[</div>]
        else
          markup << %[</div>]
          markup << %[</li>]
        end

        return markup.join("\n")
      end

      def esc(text)
        CGI.escape(text.to_s)
      end

      def inspect
        "<#{self.class} #{name}>"
      end

    end

  end

end

