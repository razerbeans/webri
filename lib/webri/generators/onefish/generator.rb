require 'webri/generators/abstract'
#require 'webri/components/search'
#require 'webri/components/github'

module WebRI

  # Onefishm as teh name suggests builds
  # a single page.
  #
  class Onefish < WebRI::Generator

    def generate_files
    end

    def generate_classes
    end

    #
    #def path
    #  @path ||= Pathname.new(__FILE__).parent
    #end

    #def generate_template
    #  super
    #end

#    # TODO: Does this belong here or in the quicksearch component?
#    def each_letter_group(methods, &block)
#      group = {:name => '', :methods => []}
#      methods.sort{ |a, b| a.name <=> b.name }.each do |method|
#        gname = group_name method.name
#        if gname != group[:name]
#          yield group unless group[:methods].size == 0
#          group = {
#            :name => gname,
#            :methods => []
#          }
#        end
#        group[:methods].push(method)
#      end
#      yield group unless group[:methods].size == 0
#    end
    
#   protected

#    ##

#    def group_name(name)
#      if match = name.match(/^([a-z])/i)
#        match[1].upcase
#      else
#        '#'
#      end
#    end

  end

end

