require 'webri/ri/server/server'

module WebRI

  # This is the static website generator.
  #
  class Generator < Server

    # Reference to CGI Service
    #attr :cgi

    # Reference to RI Service
    #attr :service

    # Directory in which to store generated html files
    attr :output

    #
    def initialize(service, options={})
      super(service, options)
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

    # Generate webpages.
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

    # Recrusive HTML generation on a hierarchy entry.
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
      file = File.join(output, file)

      #file = keyword
      #file = file.gsub('::', '--')
      #file = file.gsub('.' , '--')
      #file = file.gsub('#' , '-')
      #file = File.join(output, file + '.html')

      write(file, service.info(keyword))

      cmethods = entry.class_methods.map{ |x| x.to_s }.sort
      cmethods.each do |name|
        mname = "#{entry.full_name}.#{name}"
        mfile = WebRI.entry_to_path(mname)
        mfile = File.join(output, mfile)
        #mfile = File.join(output, "#{entry.file_name}/c-#{esc(name)}.html")
        write(mfile, service.info(mname))
      end

      imethods = entry.instance_methods.map{ |x| x.to_s }.sort
      imethods.each do |name|
        mname = "#{entry.full_name}##{name}"
        mfile = WebRI.entry_to_path(mname)
        mfile = File.join(output, mfile)
        #mfile = File.join(output, "#{entry.file_name}/i-#{esc(name)}.html")
        write(mfile, service.info(mname))
      end

      entry.subspaces.each do |child_name, child_entry|
        next if child_entry == entry
        @directory_depth += 1
        generate_recurse(child_entry)
        @directory_depth -= 1
      end
    end

    # Generate files.
    def generate_support_files
      FileUtils.mkdir_p(output)

      write(File.join(output, 'index.html'),  index)
      #write(File.join(output, 'header.html'), page_header)
      #write(File.join(output, 'tree.html'),   page_tree)
      #write(File.join(output, 'main.html'),   page_main)

      # copy assets
      dir = File.join(directory, 'assets')
      FileUtils.cp_r(dir, output)
    end

    # Write file.
    def write(file, text)
      puts file
      FileUtils.mkdir_p(File.dirname(file))
      File.open(file, 'w') { |f| f << text.to_s }
    end

    #
    def current_content
      @current_content
    end

  end #class Generator

end #module WebRI

