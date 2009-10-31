require 'erb'
require 'yaml'
require 'cgi'
require 'webri/opesc'
require 'webri/heirarchy'

module WebRI

  # Server class and base class for Generator.
  #
  class Server

    # Reference to CGI Service
    #attr :cgi

    # Reference to RI Service
    attr :service

    # Directory in which to store generated html files
    #attr :output

    # Title of docs to add to webpage header.
    attr :title

    #
    def initialize(service, options={})
      #@cgi = {} #CGI.new('html4')
      @service = service
      @templates = {}

      @title = options[:title]
    end

    # Tile of documentation as given by commandline option
    # or a the namespace of the root entry of the heirarchy.
    def title
      @title ||= heirarchy.full_name
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
      @tree ||= generate_tree(heirarchy) #heirarchy.to_html
    end

    # generate html tree
    #
    def generate_tree(entry)
      markup = []
      if entry.root?
        markup << %[<div class="root">]
      else
        path = WebRI.entry_to_path(entry.full_name)
        markup << %[
         <li class="trigger">
           <img src="assets/img/class.png" onClick="showBranch(this);"/>
           <span class="link" onClick="lookup_static(this, '#{path}');">#{entry.name}</span>
        ]
        markup << %[<div class="branch">]
      end

      markup << %[<ul>]

      cmethods = entry.class_methods.map{ |x| x.to_s }.sort
      cmethods.each do |method|
        path = WebRI.entry_to_path(entry.full_name + ".#{method}")
        markup << %[
          <li class="meta_leaf">
            <span class="link" onClick="lookup_static(this, '#{path}');">#{method}</span>
          </li>
        ]
      end

      imethods = entry.instance_methods.map{ |x| x.to_s }.sort
      imethods.each do |method|
        path = WebRI.entry_to_path(entry.full_name + "##{method}")
        markup << %[
          <li class="leaf">
            <span class="link" onClick="lookup_static(this, '#{path}');">#{method}</span>
          </li>
        ]
      end

      entry.subspaces.to_a.sort{ |a,b| a[0].to_s <=> b[0].to_s }.each do |(name, subspace)|
      #subspaces.each do |name, subspace|
        markup << generate_tree(subspace) #subspace.to_html
      end
      markup << %[</ul>]

      if entry.root?
        markup << %[</div>]
      else
        markup << %[</div>]
        markup << %[</li>]
      end

      return markup.join("\n")
    end

    #
    def lookup(path)
      entry = WebRI.path_to_entry(path)
      if entry
        html = service.info(entry)
        html = autolink(html, entry)

        #term = AnsiSys::Terminal.new.echo(ansi)
        #html = term.render(:html) #=> HTML fragment
        #html = ERB::Util.html_escape(html)

        html = "#{html}<br/><br/>"
      else
        html = "<h1>ERROR</h1>"
      end
      return html
    end

    # Search for certain patterns within the HTML and subs in hyperlinks.
    #
    # Eg.
    #
    #   <h2>Instance methods:</h2>
    #   current_content, directory, generate, generate_recurse, generate_tree
    #
    def autolink(html, entry)
      link = entry.gsub('::','/')

      re = Regexp.new(Regexp.escape(entry), Regexp::MULTILINE)
      if md = re.match(html)
        title = %[<a class="link title" href="javascript: lookup_static(this, '#{link}.html');">#{md[0]}</a>]
        html[md.begin(0)...md.end(0)] = title
      end

      # class methods
      re = Regexp.new(Regexp.escape("<h2>Class methods:</h2>") + "(.*?)" + Regexp.escape("<"), Regexp::MULTILINE)
      if md = re.match(html)
        meths = md[1].split(",").map{|m| m.strip}
        meths = meths.map{|m| %[<a class="link" href="javascript: lookup_static(this, '#{link}/c-#{m}.html');">#{m}</a>] }
        html[md.begin(1)...md.end(1)] = meths.join(", ")
      end

      # instance methods
      re = Regexp.new(Regexp.escape("<h2>Instance methods:</h2>") + "(.*?)" + Regexp.escape("<"), Regexp::MULTILINE)
      if md = re.match(html)
        meths = md[1].split(",").map{|m| m.strip}
        meths = meths.map{|m| %[<a class="link" href="javascript: lookup_static(this, '#{link}/i-#{m}.html');">#{m}</a>] }
        html[md.begin(1)...md.end(1)] = meths.join(", ")
      end

      return html
    end

    #
    def template(name)
      @templates[name] ||= File.read(File.join(directory, 'templates', name + '.html'))
    end

    #
    #def to_html
    #  #filetext = File.read(File.join(File.dirname(__FILE__), 'template.rhtml'))
    #  template = ERB.new(template_source)
    #  template.result(binding)
    #  #heirarchy.to_html
    #end

    #
    def render(source)
      template = ERB.new(source)
      template.result(binding)
    end

    #
    #def page_header
    #  render(template('header'))
    #end

    #
    #def page_tree
    #  render(template('tree'))
    #end

    #
    def index
      render(template('index'))
    end

    #
    #def page_main
    #  render(template('main'))
    #end

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

