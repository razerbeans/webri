require 'webri/engine'

module WebRI

  # This is the static website generator.
  #
  class Generator < Engine

    # Reference to CGI Service
    #attr :cgi

    # Reference to RI Service
    #attr :service

    # Directory in which to store generated html files
    attr :output

    #
    def initialize(service)
      super(service)
      #@cgi = {} #CGI.new('html4')
      #@service = service
      @directory_depth = 0
    end

    #
    #def directory
    #  @directory ||= File.dirname(__FILE__)
    #end

    #
    def tree
      #%[<iframe src="tree.html"></iframe>]
      @tree ||= heirarchy.to_html_static
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

    #
    #def to_html
    #  #filetext = File.read(File.join(File.dirname(__FILE__), 'template.rhtml'))
    #  template = ERB.new(template_source)
    #  template.result(binding)
    #  #heirarchy.to_html
    #end

    # generate webpages
    def generate(output=".")
      @output = File.expand_path(output)
      # traverse the the hierarchy

      generate_support_files

      #generate_recurse(heirarchy)

#      heirarchy.class_methods.each do |name|
#        p name
#      end

#      heirarchy.instance_methods.each do |name|
#        p name
#      end

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

      write(file, service.info(keyword))
      #File.open(file, 'w') { |f| f << service.info(keyword) } #to_html }

      entry.class_methods.each do |name|
        mname = "#{entry.full_name}.#{name}"
        mfile = File.join(output, "#{entry.file_name}/c-#{esc(name)}.html")
        write(mfile, service.info(mname))
        #File.open(mfile, 'w') { |f| f << service.info(mname) } #to_html }
      end

      entry.instance_methods.each do |name|
        mname = "#{entry.full_name}.#{name}"
        mfile = File.join(output, "#{entry.file_name}/i-#{esc(name)}.html")
        write(mfile, service.info(mname))
        #File.open(mfile, 'w') { |f| f << service.info(mname) } #to_html }
      end

      entry.subspaces.each do |child_name, child_entry|
        next if child_entry == entry
        @directory_depth += 1
        generate_recurse(child_entry)
        @directory_depth -= 1
      end
    end

    #
    def write(file, text)
      puts file
      FileUtils.mkdir_p(File.dirname(file))
      File.open(file, 'w') { |f| f << text.to_s }
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

=begin
    # = Generator Heirarchy
    #
    class Heirarchy
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


      def esc(text)
        OpEsc.escape(text.to_s)
      end

      def inspect
        "<#{self.class} #{name}>"
      end

    end #class NS
=end

  end #class Generator

end #module WebRI
