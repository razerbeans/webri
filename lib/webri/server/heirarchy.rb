module WebRI

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
      WebRI.entry_to_path(full_name)
    end

    #
    def inspect
      "<#{self.class} #{name}>"
    end

=begin
    # generate html tree
    #
    def to_html
      markup = []
      if root?
        markup << %[<div class="root">]
      else
        path = WebRI.entry_to_path(full_name)
        markup << %[
         <li class="trigger">
           <img src="assets/img/class.png" onClick="showBranch(this);"/>
           <span class="link" onClick="lookup_static(this, '#{path}');">#{name}</span>
        ]
        markup << %[<div class="branch">]
      end

      markup << %[<ul>]

      cmethods = class_methods.map{ |x| x.to_s }.sort
      cmethods.each do |method|
        path = WebRI.entry_to_path(full_name + ".#{method}")
        markup << %[
          <li class="meta_leaf">
            <span class="link" onClick="lookup_static(this, '#{path}');">#{method}</span>
          </li>
        ]
      end

      imethods = instance_methods.map{ |x| x.to_s }.sort
      imethods.each do |method|
        path = WebRI.entry_to_path(full_name + "##{method}")
        markup << %[
          <li class="leaf">
            <span class="link" onClick="lookup_static(this, '#{path}');">#{method}</span>
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

    #
    alias_method :to_html_static, :to_html
=end

=begin
    # generate dynamic html tree
    #
    def to_html
      markup = []
      if root?
        markup << %[<div class="root">]
      else
        markup << %[
         <li class="trigger">
           <img src="img/dir.gif" onClick="showBranch(this);"/>
           <span class="link" onClick="lookup(this, '#{full_name}');">#{name}</span>
        ]
        markup << %[<div class="branch">]
      end

      markup << %[<ul>]
      class_methods.each do |method|
        markup << %[
          <li class="meta_leaf">
            <span class="link" onClick="lookup(this, '#{full_name}.#{method}');">#{method}</span>
          </li>
        ]
      end

      instance_methods.each do |method|
        markup << %[
          <li class="leaf">
            <span class="link" onClick="lookup(this, '#{full_name}-#{method}');">#{method}</span>
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
=end

    #
    #def esc(text)
    #  OpEsc.escape(text.to_s)
    #  #CGI.escape(text.to_s).gsub('-','%2D')
    #end

  end #class Heirarchy

end #module WebRI

