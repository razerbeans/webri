#begin
#  # requiroing rubygems is needed here b/c ruby comes with
#  # rdoc but it's not the latest version.
#  require 'rubygems'
#  #gem 'rdoc', '>= 2.4' unless ENV['RDOC_TEST'] or defined?($rdoc_rakefile)
#  gem "rdoc", ">= 2.4.2"
#rescue
#end

if Gem.available? "json"
  gem "json", ">= 1.1.3"
else
  gem "json_pure", ">= 1.1.3"
end

require 'json'
require 'pp'
require 'pathname'
#require 'fileutils'
require 'yaml'

require 'rdoc/rdoc'
require 'rdoc/generator'
require 'rdoc/generator/markup'

require 'webri/extensions/rdoc'
require 'webri/extensions/fileutils'

require 'webri/generators/abstract/timedelta'
require 'webri/generators/abstract/erbtemplate'

#
module WebRI

  # = Abstract Generator Base Class
  #
  class Generator

    #include ERB::Util
    include TimeDelta

    #
    # C O N S T A N T S
    #

    PATH = Pathname.new(File.dirname(__FILE__))

    # Common template directory.
    PATH_STATIC = PATH + 'static'

    # Common template directory.
    PATH_TEMPLATE = PATH + 'template'

    # Directory where generated classes live relative to the root
    DIR_CLASS = 'classes'

    # Directory where generated files live relative to the root
    DIR_FILE = 'files'

    # Directory where static assets are located in the template
    DIR_ASSETS = 'assets'

    #
    # C L A S S   M E T H O D S
    #

    #::RDoc::RDoc.add_generator(self)

    def self.inherited(base)
      ::RDoc::RDoc.add_generator(base)
    end

    #

    def self.include(*mods)
      comps, mods = *mods.partition{ |m| m < Component }
      components.concat(comps)
      super(*mods)
    end

    #

    def self.components
      @components ||= []
    end

    # Standard generator factory method.

    def self.for(options)
      new(options)
    end

    #
    #  I N S T A N C E   M E T H O D S
    #

    # User options from the command line.

    attr :options

    # TODO: Get from metadata -- use POM if available.
    def title
      options.title
    end

    # FIXME: Pull copyright from project.
    def copyright
      "(c) 2009".sub("(c)", "&copy;")
    end

    # List of all classes and modules.
    #def all_classes_and_modules
    #  @all_classes_and_modules ||= RDoc::TopLevel.all_classes_and_modules
    #end

    # In the world of the RDoc Generators #classes is the same as 
    # #all_classes_and_modules. Well, except that its sorted too.
    # For classes sans modules, see #types.

    def classes
      @classes ||= RDoc::TopLevel.all_classes_and_modules.sort
    end

    # Only toplevel classes and modules.

    def classes_toplevel
      @classes_toplevel ||= classes.select {|klass| !(RDoc::ClassModule === klass.parent) }
    end

    # Documented classes and modules sorted by salience first, then by name.

    def classes_salient
      @classes_salient ||= sort_salient(classes)
    end

    #

    def classes_hash
      @classes_hash ||= RDoc::TopLevel.modules_hash.merge(RDoc::TopLevel.classes_hash)
    end

    #

    def modules
      @modules ||= RDoc::TopLevel.modules.sort
    end

    #

    def modules_toplevel
      @modules_toplevel ||= modules.select {|klass| !(RDoc::ClassModule === klass.parent) }
    end

    #

    def modules_salient
      @modules_salient ||= sort_salient(modules)
    end

    #

    def modules_hash
      @modules_hash ||= RDoc::TopLevel.modules_hash
    end

    #

    def types
      @types ||= RDoc::TopLevel.classes.sort
    end

    #

    def types_toplevel
      @types_toplevel ||= types.select {|klass| !(RDoc::ClassModule === klass.parent) }
    end

    #

    def types_salient
      @types_salient ||= sort_salient(types)
    end

    #

    def types_hash
      @types_hash ||= RDoc::TopLevel.classes_hash
    end

    #

    def files
      @files ||= RDoc::TopLevel.files
    end

    # List of toplevel files. RDoc supplies this via the #generate method.

    def files_toplevel
      @files_toplevel
    end

    #

    def files_hash
      @files ||= RDoc::TopLevel.files_hash
    end

    # List of all methods in all classes and modules.

    def methods_all
      @methods_all ||= classes.map{ |m| m.method_list }.flatten.sort
    end

    #

    def find_class_named(*a,&b)
      RDoc::TopLevel.find_class_named(*a,&b) || RDoc::TopLevel.find_module_named(*a,&b)
    end

    #

    def find_module_named(*a,&b)
      RDoc::TopLevel.find_module_named(*a,&b)
    end

    #

    def find_type_named(*a,&b)
      RDoc::TopLevel.find_class_named(*a,&b)
    end

    #

    def find_file_named(*a,&b)
      RDoc::TopLevel.find_file_named(*a,&b)
    end

    #
    # TODO: What's this then?

    def json_creatable?
      RDoc::TopLevel.json_creatable?
    end


    # RDoc needs this to function. ?

    def class_dir ; DIR_CLASS ; end

    # RDoc needs this to function. ?

    def file_dir  ; DIR_FILE ; end


    # Build the initial indices and output objects
    # based on an array of top level objects containing
    # the extracted information.

    def generate(toplevel_files)
      @files_toplevel = toplevel_files.sort
      generate_setup
      generate_commons
      generate_static
      generate_template
      generate_components
    rescue StandardError => err
      debug_msg "%s: %s\n  %s" % [ err.class.name, err.message, err.backtrace.join("\n  ") ]
      raise
    end

    # Components may need to define a method on
    # the rendering context.

    def provision(method, &block)
      #if block
        #@provisions[method] = block
        (class << self; self; end).class_eval do
          define_method(method) do |*a, &b|
            block.call(*a, &b)
          end
        end
      #else
      #  @provisions[method] = lambda do |*a, &b|
      #    __send__(method, *a, &b)
      #  end
      #end
    end

  protected

    #

    def sort_salient(classes)
      nscounts = classes.inject({}) do |counthash, klass|
        top_level = klass.full_name.gsub( /::.*/, '' )
        counthash[top_level] ||= 0
        counthash[top_level] += 1
        counthash
      end
      # Sort based on how often the top level namespace occurs, and then on the
      # name of the module -- this works for projects that put their stuff into
      # a namespace, of course, but doesn't hurt if they don't.
      classes.sort_by do |klass|
        top_level = klass.full_name.gsub( /::.*/, '' )
        [nscounts[top_level] * -1, klass.full_name]
      end.select do |klass|
        klass.document_self
      end
    end

    ##
    ## Initialization
    ##

    def initialize(options)
      @options = options
      @options.diagram = false  # why?

      @path_base   = Pathname.pwd.expand_path
      @path_output = Pathname.new(@options.op_dir).expand_path(@path_base)

      @provisions = {}

      initialize_template
      initialize_methods
      initialize_components
    end

    #

    def initialize_template
      @template = @options.template #|| DEFAULT_TEMPLATE
      raise RDoc::Error, "could not find template #{template.inspect}" unless path_template.directory?
    end

    # Overide this method to set up any rendering provisions.

    def initialize_methods
    end

    #

    def initialize_components
      @components = []
      self.class.components.each do |comp|
        @components << comp.new(self)
      end
    end

    # Component instances.

    attr :components

    # Component provisions.

    attr :provisions

    # The template type selected to be generated.

    attr :template

    # Current pathname.

    attr :path_base

    # The output path.

    attr :path_output

    # Path to the static files. This should be defined in the
    # subclass as:
    #
    #  def path
    #   @path ||= Pathname.new(__FILE__).parent
    #  end
    #
    def path
      raise "Must be implemented by subclass!"
    end

    # Path to static files. This is <tt>path + 'static'</tt>.
    def path_static
      path + 'static'
    end

    # Path to static files. This is <tt>path + 'template'</tt>.
    def path_template
      path + 'template'
    end

    #
    def path_output_relative(path=nil)
      if path
        path.to_s.sub(path_base.to_s+'/', '')
      else
        @path_output_relative ||= path_output.to_s.sub(path_base.to_s+'/', '')
      end
    end

    # Prepare generator.

    def generate_setup
    end

    # This method files copies the common static files of the abstract
    # generator, which are overlayed with the files from the subclass.
    # This way there is always a standard base to draw upon, and anything
    # the subclass doesn't like it can override, which provides a sort-of,
    # albeit simplistic, file inheritence system.

    def generate_commons
      from = Dir[(PATH_STATIC + '**').to_s]
      dest = path_output.to_s
      show_from = PATH_STATIC.to_s.sub(PATH.parent.to_s+'/','')
      debug_msg "Copying #{show_from}/** to #{path_output_relative}/:"
      fileutils.cp_r from, dest, :preserve => true
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
      debug_msg "Copying #{show_from}/** to #{path_output_relative}/:"
      fileutils.cp_r from, dest, :preserve => true
    end

    # Rendered and save templates.

    def generate_template
      generate_files
      generate_classes
      generate_index
    end

    # Let the components generate what they need. Iterates through
    # each componenet and calls #generate.

    def generate_components
      components.each do |component|
        component.generate
      end
    end

    # Create the directories the generated docs will live in if
    # they don't already exist.
    #def gen_sub_directories
    #  @path_output.mkpath
    #end

    # Generate a documentation file for each file

    def generate_files
      debug_msg "Generating file documentation in #{path_output_relative}:"
      templatefile = self.path_template + 'file.rhtml'

      files_toplevel.each do |file|
        outfile     = self.path_output + file.path
        debug_msg "working on %s (%s)" % [ file.full_name, path_output_relative(outfile) ]

        rel_prefix  = self.path_output.relative_path_from( outfile.dirname )
        #context     = binding()

        debug_msg "rendering #{path_output_relative(outfile)}"
        self.render_template(templatefile, outfile, :file=>file, :rel_prefix=>rel_prefix)
      end
    end

    # Generate a documentation file for each class

    def generate_classes
      debug_msg "Generating class documentation in #{path_output_relative}:"
      templatefile = self.path_template + 'class.rhtml'

      classes.each do |klass|
        debug_msg "working on %s (%s)" % [ klass.full_name, klass.path ]
        outfile    = self.path_output + klass.path

        rel_prefix = self.path_output.relative_path_from(outfile.dirname)

        debug_msg "rendering #{path_output_relative(outfile)}"
        self.render_template( templatefile, outfile, :klass=>klass, :rel_prefix=>rel_prefix )
      end
    end

    # Create index.html

    def generate_index
      debug_msg "Generating index file in #{path_output_relative}:"
      templatefile = self.path_template + 'index.rhtml'
      outfile      = self.path_output   + 'index.html'

      index_path   = index_file.path

      debug_msg "rendering #{path_output_relative(outfile)}"
      self.render_template(templatefile, outfile, :index_path=>index_path)
    end

    # TODO: Make public?

    def index_file
      if self.options.main_page && file = self.files.find { |f| f.full_name == self.options.main_page }
        file
      else
        self.files.first
      end
    end

=begin
  # Generate an index page
  def generate_index_file
    debug_msg "Generating index file in #@path_output"
    templatefile = @path_template + 'index.rhtml'

    template_src = templatefile.read

    template = ERB.new(template_src, nil, '<>')
    template.filename = templatefile.to_s
    context = binding()

    output = nil

    begin
      output = template.result(context)
    rescue NoMethodError => err
      raise RDoc::Error, "Error while evaluating %s: %s (at %p)" % [
        templatefile,
        err.message,
        eval( "_erbout[-50,50]", context )
      ], err.backtrace
    end

    outfile = path_base + @options.op_dir + 'index.html'
    unless $dryrun
      debug_msg "Outputting to %s" % [outfile.expand_path]
      outfile.open( 'w', 0644 ) do |fh|
        fh.print( output )
      end
    else
      debug_msg "Would have output to %s" % [outfile.expand_path]
    end
  end
=end


    # Load and render the erb template in the given +templatefile+ within the
    # specified +context+ (a Binding object) and write it out to +outfile+.
    # Both +templatefile+ and +outfile+ should be Pathname-like objects.

    def render_template(templatefile, outfile, local_assigns)
      output = erb_template.render(templatefile, local_assigns)

      #output = eval_template(templatefile, context)
      # TODO: delete this dirty hack when documentation for example for GeneratorMethods will not be cutted off by <script> tag
      begin
        if output.respond_to? :force_encoding
          encoding = output.encoding
          output = output.force_encoding('ASCII-8BIT').gsub('<script>', '&lt;script;&gt;').force_encoding(encoding)
        else
          output = output.gsub('<script>', '&lt;script&gt;')
        end
      rescue Exception => e
      end

      unless $dryrun
        outfile.dirname.mkpath
        outfile.open( 'w', 0644 ) do |file|
          file.print( output )
        end
      else
        debug_msg "would have written %d bytes to %s" %
        [ output.length, outfile ]
      end
    end

    # Load and render the erb template in the given +templatefile+ within the
    # specified +context+ (a Binding object) and return output
    # Both +templatefile+ and +outfile+ should be Pathname-like objects.

    def eval_template(templatefile, context)
      template_src = templatefile.read
      template = ERB.new(template_src, nil, '<>')
      template.filename = templatefile.to_s

      begin
        template.result(context)
      rescue NoMethodError => err
        raise RDoc::Error, "Error while evaluating %s: %s (at %p)" % [
          templatefile.to_s,
          err.message,
          eval("_erbout[-50,50]", context)
        ], err.backtrace
      end
    end

    #

    def erb_template
      @erb_template ||= ERBTemplate.new(self, provisions)
    end

=begin
  def render_template( templatefile, context, outfile )
    template_src = templatefile.read
    template = ERB.new( template_src, nil, '<>' )
    template.filename = templatefile.to_s

    output = begin
               template.result( context )
             rescue NoMethodError => err
               raise RDoc::Error, "Error while evaluating %s: %s (at %p)" % [
                 templatefile.to_s,
                 err.message,
                 eval( "_erbout[-50,50]", context )
               ], err.backtrace
             end

    unless $dryrun
      outfile.dirname.mkpath
      outfile.open( 'w', 0644 ) do |ofh|
        ofh.print( output )
      end
    else
      debug_msg "  would have written %d bytes to %s" %
      [ output.length, outfile ]
    end
  end
=end

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

