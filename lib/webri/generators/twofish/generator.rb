require 'webri/generators/abstract'
require 'webri/components/subversion'

module WebRI

  # = Twofish Template
  #
  # The Twofish template is a two pane layout, providing
  # a navigation pane on the left and a document pane to
  # the right. The navigation pane presents a collapsable
  # namespace tree which updates the document pane, an iframe,
  # via targeted a href links.
  #
  class Twofish < Generator

    include Subversion

    #
    #def path
    #  @path ||= Pathname.new(__FILE__).parent
    #end

    #

    #def initialize_methods
    #  provision :html_tree
    #end

    #
    #def generate_template
    #  super
    #end

    #<ul>
    #  <li class="trigger">
    #    <img src="assets/icon/class.png" onClick="showBranch(this);"/>
    #
    #    <span class="link" path="__path__" onClick="lookup_static(this);">__entry.name__</span>
    #    
    #    <div class="branch">
    #      <ul>
    #        <li class="meta_leaf">
    #          <span class="link" path="__path__" onClick="lookup_static(this);">__method__</span>
    #        </li>
    #      </ul>
    #      <ul>
    #        <li class="leaf">
    #          <span class="link" path="__path__" onClick="lookup_static(this);">__method__</span>
    #        </li>
    #      </ul>
    #  </li>
    #</ul>
   
    #
    def html_tree
      #%[<iframe src="tree.html"></iframe>]
      @html_tree ||= (
        %[<div class="root">] + generate_html_tree(classes_toplevel) + %[</div>]   #heirarchy) #heirarchy.to_html
      )
    end

    # generate html tree
    #
    def generate_html_tree(classes)
      markup = ["<ul>"]

      classes = classes.sort{ |a,b| a.full_name <=> b.full_name }

      classes.each do |entry|
        path = entry.path  #WebRI.entry_to_path(entry.full_name)
        markup << %[
         <li class="trigger">
           <img src="assets/icon/class.png" onClick="showBranch(this);"/>
           <a class="link" href="#{path}" target="main">#{entry.name}</a>
        ]
        markup << %[<div class="branch">]

        markup << %[<ul>]
        
        cmethods, imethods = *entry.method_list.partition{ |m| m.singleton }

        cmethods = cmethods.sort{ |a,b| a.name <=> b.name }
        cmethods.each do |method|
          path = method.path   #entry.full_name + ".#{method.name}" #WebRI.entry_to_path(entry.full_name + ".#{method}")
          markup << %[
            <li class="meta_leaf">
              <a class="link" href="#{path}" target="main">#{method.name}</a>
            </li>
          ]
        end

        imethods = imethods.sort{ |a,b| a.name <=> b.name }
        imethods.each do |method|
          path = method.path   #WebRI.entry_to_path(entry.full_name + "##{method}")
          markup << %[
            <li class="leaf">
              <a class="link" href="#{path}" target="main">#{method.name}</a>
            </li>
          ]
        end

        #entry.classes.sort{ |a,b| a[0].to_s <=> b[0].to_s }.each do |(name, subspace)|
        #subspaces.each do |name, subspace|
        markup << generate_html_tree(entry.classes_and_modules) if entry.classes
        #end

        markup << %[</ul>]

        #if entry.root?
        #  markup << %[</div>]
        #else
          markup << %[</div>]
          markup << %[</li>]
        #end
      end
      markup << "</ul>"
      return markup.join("\n")
    end

  end

end#module WebRI

