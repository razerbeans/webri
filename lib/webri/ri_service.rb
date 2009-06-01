module WebRI

  class RiService

    attr :library

    def initialize(library=nil)
      @library = library
    end

    def info(keyword)
      if library
        `ri -d #{library} -f html #{keyword}`
      else
        `ri -f html #{keyword}`
      end
    end

    def names
      @names ||= if library
        `ri -d #{library} --list-names`
      else
        `ri --list-names`
      end.split(/\s*\n/)
    end

  end

end

