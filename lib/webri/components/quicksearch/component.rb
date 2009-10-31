require 'webri/abstract/component'
require 'iconv'

module WebRI

  #
  class QuickSearch < Abstract::Component

    #
    SEARCH_TREE_FILE  = 'search_tree.js'

    #
    SEARCH_INDEX_FILE = 'search_index.js'

    # Used in js to reduce index sizes
    TYPE_CLASS  = 1
    TYPE_METHOD = 2
    TYPE_FILE   = 3

    #

    def path
      @path ||= Pathname.new(File.dirname(__FILE__))
    end

    # Generate class tree and serach index.

    def generate
      generate_static
      generate_search_tree
      generate_search_index
    end

    # Create class tree structure and write it as json

    def generate_search_tree
      debug_msg "Generating Class Tree:"
      topclasses = classes.select {|klass| !(RDoc::ClassModule === klass.parent) }
      tree = generate_file_tree + generate_search_tree_level(topclasses)
      debug_msg "writing class tree to %s" % SEARCH_TREE_FILE

      File.open(SEARCH_TREE_FILE, "w", 0644) do |f|
        f.write('var tree = '); f.write(tree.to_json)
      end unless $dryrun
    end
   
    # Recursivly build class tree structure

    def generate_search_tree_level(classes)
      tree = []
      classes.select{|c| c.with_documentation? }.sort.each do |klass|
        item = [
          klass.name,
          klass.document_self_or_methods ? klass.path : '',
          klass.module? ? '' : (klass.superclass ? " < #{String === klass.superclass ? klass.superclass : klass.superclass.full_name}" : ''),
          generate_search_tree_level(klass.classes_and_modules)
        ]
        tree << item
      end
      tree
    end

    # Create search index for all classes, methods and files
    # Write as json.

    def generate_search_index
      debug_msg "Generating Search Index:"

      index = {
        :searchIndex => [],
        :longSearchIndex => [],
        :info => []
      }

      add_class_search_index(index)
      add_method_search_index(index)
      add_file_search_index(index)

      debug_msg "writing search index to %s" % SEARCH_INDEX_FILE
      data = {
        :index => index
      }
      File.open(SEARCH_INDEX_FILE, "w", 0644) do |f|
        f.write('var search_data = '); f.write(data.to_json)
      end unless $dryrun
    end

    # Add files to search +index+ array.

    def add_file_search_index(index)
      debug_msg "generating file search index"

      files.select { |file| file.document_self }.sort.each do |file|
        index[:searchIndex].push( search_string(file.name) )
        index[:longSearchIndex].push( search_string(file.path) )
        index[:info].push([
          file.name,
          file.path,
          file.path,
          '',
          snippet(file.comment),
          TYPE_FILE
        ])
      end
    end

    # Add classes to search +index+ array.

    def add_class_search_index(index)
      debug_msg "generating class search index"

      classes.select { |klass| klass.document_self_or_methods }.sort.each do |klass|
        modulename = klass.module? ? '' : (klass.superclass ? (String === klass.superclass ? klass.superclass : klass.superclass.full_name) : '')
        index[:searchIndex].push( search_string(klass.name) )
        index[:longSearchIndex].push( search_string(klass.parent.full_name) )
        index[:info].push([
          klass.name,
          klass.parent.full_name,
          klass.path,
          modulename ? " < #{modulename}" : '',
          snippet(klass.comment),
          TYPE_CLASS
        ])
      end
    end

    # Add methods to search +index+ array.

    def add_method_search_index(index)
      debug_msg "generating method search index"

      list = classes.map { |klass|
        klass.method_list
      }.flatten.sort{ |a, b| a.name == b.name ? a.parent.full_name <=> b.parent.full_name : a.name <=> b.name }.select { |method|
        method.document_self
      }
      unless options.show_all
        list = list.find_all {|m| m.visibility == :public || m.visibility == :protected || m.force_documentation }
      end

      list.each do |method|
        index[:searchIndex].push( search_string(method.name) + '()' )
        index[:longSearchIndex].push( search_string(method.parent.full_name) )
        index[:info].push([
          method.name,
          method.parent.full_name,
          method.path,
          method.params,
          snippet(method.comment),
          TYPE_METHOD
        ])
      end
    end

    # Build search index key.

    def search_string(string)
      string ||= ''
      string.downcase.gsub(/\s/,'')
    end

    #

    def generate_file_tree
      if files.length > 1
        @files_tree = FilesTree.new
        files.each do |file|
          @files_tree.add(file.relative_name, file.path)
        end
        [['', '', 'files', generate_file_tree_level(@files_tree)]]
      else
        []
      end
    end

    #

    def generate_file_tree_level(tree)
      tree.children.keys.sort.map do |name|
        child = tree.children[name]
        if String === child
          [name, child, '', []]
        else
          ['', '', name, generate_file_tree_level(child)]
        end
      end
    end

    #

    class FilesTree
      attr_reader :children
      def add(path, url)
        path = path.split(File::SEPARATOR) unless Array === path
        @children ||= {}
        if path.length == 1
          @children[path.first] = url
        else
          @children[path.first] ||= FilesTree.new
          @children[path.first].add(path[1, path.length], url)
        end
      end
    end

    # Strip comments on a space after 100 chars

    def snippet(str)
      str ||= ''
      if str =~ /^(?>\s*)[^\#]/
        content = str
      else
        content = str.gsub(/^\s*(#+)\s*/, '')
      end

      content = content.sub(/^(.{100,}?)\s.*/m, "\\1").gsub(/\r?\n/m, ' ')

      begin
        content.to_json
      rescue # might fail on non-unicode string
        begin
          # remove all non-unicode chars
          content = Iconv.conv('latin1//ignore', "UTF8", content)
          content.to_json
        rescue
          content = '' # something hugely wrong happend
        end
      end
      content
    end

  end

end

