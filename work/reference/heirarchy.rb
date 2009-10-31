module RDazzle

  module Heirarchable

    #
    def self.entry_to_path(entry)
      path = entry.to_s
      path = path.gsub('::', '/')
      path = path.gsub('#' , '/i-')
      path = path.gsub('.' , '/c-')
      path = OpEsc.escape(path)
      path = path + '.html'
    end

    #
    def self.path_to_entry(path)
      entry = path.to_s
      entry = entry.chomp('.html')
      entry = OpEsc.unescape(entry)
      entry = entry.gsub('/c-' , '.')
      entry = entry.gsub('/i-' , '#')
      entry = entry.gsub('/'   , '::')
    end

    # Tile of documentation as given by commandline option
    # or a the namespace of the root entry of the heirarchy.
    def title
      @title ||= heirarchy.full_name
    end

# TODO: Rather then build a hierachy in memeory, it may just be possible
# to build it in the HTML itself.

    def entries
      @entries ||= (
        e = []
        @classes.each do |c|
          c.each_method do |m|
            <a href="#<%= meth.aref %>"><%= meth.singleton ? '::' : '#' %><%= meth.name %></a></li>
          <% end %>

            e << "#{c}##{m}"
          end
        end
        e
      )
    end

    #
    def heirarchy
      @heirarchy ||=(
        ns = Heirarchy.new(nil)
        entries.each do |m|
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
      @tree ||= generate_html_tree(heirarchy) #heirarchy.to_html
    end

    # generate html tree
    #
    def generate_html_tree(entry)
      markup = []
      if entry.root?
        markup << %[<div class="root">]
      else
        path = Heirarchable.entry_to_path(entry.full_name)
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
        path = Heirarchable.entry_to_path(entry.full_name + ".#{method}")
        markup << %[
          <li class="meta_leaf">
            <span class="link" onClick="lookup_static(this, '#{path}');">#{method}</span>
          </li>
        ]
      end

      imethods = entry.instance_methods.map{ |x| x.to_s }.sort
      imethods.each do |method|
        path = Heirarchable.entry_to_path(entry.full_name + "##{method}")
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


    # = Heirarchy
    #
    class Heirarchy
      attr :name
      attr :parent
      attr :subspaces
      attr :instance_methods
      attr :class_methods

      def initialize(name, parent=nil)
        @name = name
        @parent = parent if Heirarchy===parent
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

      # Path name for a given class, module or method.
      #
      def file_name
      #  file = full_name
      #  file = file.gsub('::', '/')
      #  file = file.gsub('#' , '/')
      #  file = file.gsub('.' , '-')
      #  #file = File.join(output, file + '.html')
      #  file
        Heirarchable.entry_to_path(full_name)
      end

      #
      def inspect
        "<#{self.class} #{name}>"
      end

    end

  end

end

