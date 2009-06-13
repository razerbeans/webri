require 'erb'
require 'yaml'
require 'cgi'
require 'webri/opesc'
require 'webri/heirarchy'

module WebRI

  # Base class for both Server and Generator.
  #
  class Engine

    # Reference to CGI Service
    #attr :cgi

    # Reference to RI Service
    attr :service

    # Directory in which to store generated html files
    #attr :output

    #
    def initialize(service)
      #@cgi = {} #CGI.new('html4')
      @service = service
      #@directory_depth = 0
    end

    #
    def directory
      @directory ||= File.dirname(__FILE__)
    end

    #
    def heirarchy
      @heirarchy ||=(
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
            memo[space] ||= Heirarchy.new(space, memo)
            memo = memo[space]
          end

          if type == :class
            memo.class_methods << method
          else
            memo.instance_methods << method
          end
        end
        ns
      )
    end

    #
    def tree
      #%[<iframe src="tree.html"></iframe>]
      @tree ||= heirarchy.to_html
    end

    #
    def lookup(path)
# puts "PATH: #{path.inspect}"
       entry = WebRI.path_to_entry(path)
# puts "ENTRY: #{keyw.inspect}"
      if entry
        html = service.info(entry)
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

    #
    def template_source
      @template_source ||= File.read(File.join(File.dirname(__FILE__), 'template.rhtml'))
    end

    #
    def to_html
      #filetext = File.read(File.join(File.dirname(__FILE__), 'template.rhtml'))
      template = ERB.new(template_source)
      template.result(binding)
      #heirarchy.to_html
    end

=begin
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
        mfile = File.join(output, "#{entry.file_name}--#{esc(name)}.html")
        write(mfile, service.info(mname))
        #File.open(mfile, 'w') { |f| f << service.info(mname) } #to_html }
      end

      entry.instance_methods.each do |name|
        mname = "#{entry.full_name}.#{name}"
        mfile = File.join(output, "#{entry.file_name}-#{esc(name)}.html")
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
      puts mfile
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
=end

    #
    def current_content
      @current_content
    end

    #
    def esc(text)
      OpEsc.escape(text.to_s)
      #CGI.escape(text.to_s).gsub('-','%2D')
    end

    #
    def self.esc(text)
      OpEsc.escape(text.to_s)
      #CGI.escape(text.to_s).gsub('-','%2D')
    end
  end #class Engine

end #module WebRI

