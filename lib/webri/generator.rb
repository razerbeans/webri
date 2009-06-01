require 'erb'
require 'yaml'
require 'cgi'

module WebRI

  # This is the static website generator.
  #
  class Generator

    # Reference to CGI Service
    attr :cgi

    # Reference to RI Service
    attr :service

    # Directory in which to store generated html files
    attr :output

    #
    def initialize(service)
      @cgi = {} #CGI.new('html4')
      @service = service

      @directory_depth = 0
    end

    #
    def directory
      File.dirname(__FILE__)
    end

    #
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

    #
    def tree
      #%[<iframe src="tree.html"></iframe>]
      @tree ||= heirarchy.to_html
    end

    #
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

    #
    def to_html
      filetext = File.read(File.join(File.dirname(__FILE__), 'template.rhtml'))
      template = ERB.new(filetext)
      template.result(binding)
      #heirarchy.to_html
    end

    # generate webpages
    def generate(output=".")
      @output = File.expand_path(output)
      # traverse the the hierarchy

      generate_support_files

      #generate_recurse(heirarchy)

      heirarchy.class_methods.each do |name|
        p name
      end

      heirarchy.instance_methods.each do |name|
        p name
      end

      heirarchy.subspaces.each do |name, entry|
        #p name, entry
        generate_recurse(entry)
      end
    end

    #
    def generate_recurse(entry)
      keyword = entry.full_name

      if keyword
        puts keyword
        @current_content = service.info(keyword) #lookup(keyword)
      else
        keyword = ''
        @current_content = "Welcome"
      end

      file = entry.file_name + '.html'
      file = File.join(output, file)

      #file = keyword
      #file = file.gsub('::', '--')
      #file = file.gsub('.' , '--')
      #file = file.gsub('#' , '-')
      #file = File.join(output, file + '.html')

      File.open(file, 'w') { |f| f << service.info(keyword) } #to_html }

      entry.class_methods.each do |name|
        mname = "#{entry.full_name}.#{name}"
        mfile = File.join(output, "#{entry.file_name}--#{esc(name)}.html")
puts mfile
        File.open(mfile, 'w') { |f| f << service.info(mname) } #to_html }
      end

      entry.instance_methods.each do |name|
        mname = "#{entry.full_name}.#{name}"
        mfile = File.join(output, "#{entry.file_name}-#{esc(name)}.html")
puts mfile
        File.open(mfile, 'w') { |f| f << service.info(mname) } #to_html }
      end

      entry.subspaces.each do |child_name, child_entry|
        next if child_entry == entry
        @directory_depth += 1
        generate_recurse(child_entry)
        @directory_depth -= 1
      end
    end

    #
    def generate_support_files
      FileUtils.mkdir_p(output)

      # generate index file
      file = File.join(output, 'index.html')
      File.open(file, 'w') { |f| f << to_html }

      # copy css file
      dir = File.join(directory,'public','css')
      FileUtils.cp_r(dir, output)

      # copy images
      dir = File.join(directory,'public','img')
      FileUtils.cp_r(dir, output)

      # copy scripts
      dir = File.join(directory,'public','js')
      FileUtils.cp_r(dir, output)
    end

    #
    def current_content
      @current_content
    end

    #
    def esc(text)
      CGI.escape(text.to_s)
    end

    #
    #
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

      def file_name
        file = full_name
        file = file.gsub('::', '--')
        file = file.gsub('.' , '--')
        file = file.gsub('#' , '-')
        #file = File.join(output, file + '.html')
        file
      end

      # generate tree html
      def to_html
        markup = []
        if root?
          markup << %[<div class="root">]
        else
          markup << %[
           <li class="trigger">
             <img src="img/dir.gif" onClick="showBranch(this);"/>
             <span class="link" onClick="lookup_static(this, '#{file_name}.html');">#{name}</span>
          ]
          markup << %[<div class="branch">]
        end

        markup << %[<ul>]
        class_methods.each do |method|
          markup << %[
            <li class="meta_leaf"> 
              <span class="link" onClick="lookup_static(this, '#{file_name}--#{esc(method)}.html');">#{method}</span>
            </li>
          ]
        end

        instance_methods.each do |method|
          markup << %[
            <li class="leaf"> 
              <span class="link" onClick="lookup_static(this, '#{file_name}-#{esc(method)}.html');">#{method}</span>
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

    end #class NS

  end

end #module WebRI

