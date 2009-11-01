require 'webri/server/server'

module WebRI

  # This is the static website generator which creates
  # a single page.
  #
  class GeneratorOne < Server

    # Reference to CGI Service
    #attr :cgi

    # Reference to RI Service
    #attr :service

    # Dir in which to store generated html
    attr :output

    #
    attr :html

    #
    def initialize(service, options={})
      super(service, options)

      @html = ""

      #@cgi = {} #CGI.new('html4')
      #@service = service
      @directory_depth = 0
    end

    #
    #def tree
    #  #%[<iframe src="tree.html"></iframe>]
    #  @tree ||= heirarchy.to_html_static
    #end

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
      @assets = {}
      # traverse the the hierarchy

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

      generate_support_files
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

      file = entry.file_name
      #file = File.join(output, file)

      #file = keyword
      #file = file.gsub('::', '--')
      #file = file.gsub('.' , '--')
      #file = file.gsub('#' , '-')
      #file = File.join(output, file + '.html')

      html << %[<h1>#{entry.full_name}</h1>]

      html << %[\n<div id="#{file}" class="slot module">\n]
      html << service.info(keyword)
      html << %[\n</div>\n]

      #html << %[<h1>Class Methods</h1>]
      cmethods = entry.class_methods.map{ |x| x.to_s }.sort
      cmethods.each do |name|
        mname = "#{entry.full_name}.#{name}"
        mfile = WebRI.entry_to_path(mname)
        #mfile = File.join(output, mfile)
        #mfile = File.join(output, "#{entry.file_name}/c-#{esc(name)}.html")
        html << %[\n<div id="#{mfile}" name="#{mfile}" class="slot cmethod">\n]
        html << service.info(mname)
        html << %[\n</div>\n]
        #write(mfile, service.info(mname))
      end

      #html << %[<h1>Instance Methods</h1>]
      imethods = entry.instance_methods.map{ |x| x.to_s }.sort
      imethods.each do |name|
        mname = "#{entry.full_name}##{name}"
        mfile = WebRI.entry_to_path(mname)
        #mfile = File.join(output, mfile)
        #mfile = File.join(output, "#{entry.file_name}/i-#{esc(name)}.html")
        html << %[\n<div id="#{mfile}" name="#{mfile}" class="slot imethod">\n]
        html << service.info(mname)
        html << %[\n</div>\n]
        #write(mfile, service.info(mname))
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

      index = render(template('index1'))

      #base = base.strip.chomp('</html>').strip.chomp('</body>').strip.chomp('</div>')
      #base = base + html
      #base = base + "</div>\n</body>\n</html>"

      write(File.join(output, 'webri.html'), index)

      #write(File.join(output, 'header.html'), page_header)
      #write(File.join(output, 'tree.html'),   page_tree)
      #write(File.join(output, 'main.html'),   page_main)

      # copy assets
      #dir = File.join(directory, 'assets')
      #FileUtils.cp_r(dir, output)
    end

    #
    def current_content
      @current_content
    end

    #
    def asset(name)
      @assets[name] ||= File.read(File.join(directory, 'assets', name))
    end

    #
    def css
      asset('css/style1.css')
    end

    #
    def jquery
      '' #  asset('js/jquery.js')
    end

    #
    def rijquery
      '' #asset('js/ri.jquery.js')
    end

  end #class Generator

end #module WebRI

