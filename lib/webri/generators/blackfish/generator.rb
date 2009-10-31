require 'webri/generators/abstract'
require 'webri/components/search'
require 'webri/components/github'

module WebRI

  # Blackfish is based on Vladimir Kolesnikov's SDoc
  # (Copyright (c) 2009 Vladimir Kolesnikov).
  #
  # The SDoc code base was helpful in understanding how to
  # build an RDoc generator. It was convenient to keep a
  # copy in with the WebRI code for reference. Later, it was 
  # easy enough to integrate it with the rest of WebRI
  # (eg. splitting Search into a separate component),
  # and so it has stayed as an alernate template with
  # a few style modifications.
  #
  class Blackfish < WebRI::Generator

    include Search
    include GitHub

    #

    def path
      @path ||= Pathname.new(__FILE__).parent
    end

    #def generate_template
    #  super
    #end

    # TODO: Does this belong here or in the quicksearch component?

    def each_letter_group(methods, &block)
      group = {:name => '', :methods => []}
      methods.sort{ |a, b| a.name <=> b.name }.each do |method|
        gname = group_name method.name
        if gname != group[:name]
          yield group unless group[:methods].size == 0
          group = {
            :name => gname,
            :methods => []
          }
        end
        group[:methods].push(method)
      end
      yield group unless group[:methods].size == 0
    end
    
   protected

    #

    def group_name(name)
      if match = name.match(/^([a-z])/i)
        match[1].upcase
      else
        '#'
      end
    end

  end

end

