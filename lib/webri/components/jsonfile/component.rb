module WebRI

  require 'webri/abstract/component'

  # TODO: This component is not finished. The actual json produced
  # needs to be fleshed out more, making sure we have all the data
  # we want in there, and theat it is layedout in the optimal structure.
  #
  # TODO: RDoc has some json related stuff going on. I found 
  # RDoc::TopLevel.json_creatable?, so maybe there's a much better
  # wat to do this component.
  
  class JSONFile < Abstract::Component

    # Save as json.
    def generate

puts RDoc::TopLevel.json_creatable?
puts RDoc::TopLevel.to_json

      save_data(class_tree, 'classes.json')
      save_data(file_tree , 'files.json')
      save_data(methods   , 'methods.json')
    end

    # Save class tree
    def save_data(data, file)
      debug_msg "writing data to %s" % file
      File.open(file, "w", 0644) do |f|
        f.write(data.to_json)
      end unless $dryrun
    end

    # -- CLASS/MODULES ----------------------------------------------------

    def classes
      generator.all_classes_and_modules
    end

    # Build class/module namespace tree structure.
    def class_tree
      @class_tree ||= generate_class_tree
    end

    def generate_class_tree
      debug_msg "Generating class tree:"
      topclasses = classes.select {|klass| !(RDoc::ClassModule === klass.parent) }
      generate_class_tree_level(topclasses)
    end

    # Recursivly build class/module namespace tree structure
    def generate_class_tree_level(classes)
      tree = []
      list = classes.select{|c| c.with_documentation? }
      list = list.sort
      list.each do |c|
        item = c.to_h
        item[:methods] = c.method_list.map{ |m| m.to_h }
        item[:classes] = generate_class_tree_level(c.classes_and_modules)
        tree << item
      end
      tree
    end

    # Recursivly build class tree structure
    #def generate_class_tree_level(classes)
    #  tree = []
    #  list = classes.select{|c| c.with_documentation? }
    #  list = list.sort
    #  list.each do |c|
    #    item = [
    #      c.name,
    #      c.document_self_or_methods ? c.path : '',
    #      c.module? ? '' : (c.superclass ? " < #{String === c.superclass ? c.superclass : c.superclass.full_name}" : ''),
    #      generate_class_tree_level(c.classes_and_modules)
    #    ]
    #    tree << item
    #  end
    #  tree
    #end

    # -- FILES ------------------------------------------------------

    def files
      generator.files
    end

    def file_tree
      @file_tree ||= generate_file_tree
    end

    #
    def generate_file_tree
      debug_msg "Generating file tree:"
      return {} if files.empty?
      ftree = {}
      files.each do |file|
        path = file.full_name
        generate_file_tree_level(path, file, ftree)
      end
      ftree
    end

    def generate_file_tree_level(path, file, tree)
      parent, *subpath = *path.split(File::SEPARATOR)
      subpath = subpath.join(File::SEPARATOR)
      tree[parent] ||= {}
      e = tree[parent]
      e[:name] = parent
      if subpath.empty?
        e.merge!(file.to_h)
      else
        e[:files] ||= {}
        generate_file_tree_level(subpath, file, e[:files])
      end
    end

=begin
  #
  def generate_file_tree
    debug_msg "Generating file tree:"

    if @files.length > 1
      @files_tree = FilesTree.new
      @files.each do |file|
        @files_tree.add(file.relative_name, file.path)
      end
      generate_file_tree_level(@files_tree)
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
=end

    # -- METHODS ----------------------------------------------------

    # All methods.

    def all_methods
      @methods ||= (
        list = []
        classes.map do |mod|
          mod.method_list.each do |method|
            list << method
          end
        end
        list
      )
    end

  end

end

