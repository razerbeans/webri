module WebRI

  class RiService

    attr :library

    def initialize(library=nil)
      @library = library
    end

    def info(keyword)
#puts "KEYWORD: #{keyword.inspect}"
      if library
        html = `ri -d #{library} -f html "#{keyword}"`
      else
        html = `ri -f html #{keyword}`
      end
      "<br/>#{html}<br/><br/>"
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

