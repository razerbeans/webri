require 'uri'

module WebRI

  class RiService

    # Directory of ri doc files.
    attr_accessor :library

    attr_accessor :system

    attr_accessor :site

    attr_accessor :gems

    attr_accessor :home

    attr_accessor :ruby

    #
    def initialize(options)
      options.each do |k,v|
        send("#{k}=", v) if respond_to?("#{k}=")
      end
    end

    #
    def info(keyword)
      #puts "KEYWORD: #{keyword.inspect}"
      html = `ri #{ri_opts} -f html #{keyword}`
      return "<br/>#{html}<br/><br/>"
    end

    #
    def names
      @names ||= (library ? names_from_library : names_from_all)
    end

    #
    def names_from_library(lib=nil)
      files = nil
      Dir.chdir(lib || library) do
        files = Dir['**/*']
        files = files.map do |f|
          case f
          when /\-i.yaml$/
            (File.dirname(f) + '#' + URI.unescape(File.basename(f).chomp('-i.yaml'))).gsub('/' , '::')
          when /\-c.yaml$/
            (File.dirname(f) + '::' + URI.unescape(File.basename(f).chomp('-c.yaml'))).gsub('/' , '::')
          else
	    #f.sub(/^cdesc-/,'').gsub('/' , '::')
            nil
          end
        end.compact
      end
      files
    end

    #
    def names_from_all
      libraries = `ri #{ri_opts} -l`.split("\n")
      libraries.map do |lib|
        names_from_library(lib)
      end.flatten
    end

  private

    #
    def ri_opts
      cmd = []
      if library
        cmd << %[-d "#{library}" --no-standard-docs]
      else
        cmd << ( system ? "--system" : "--no-system" )
        cmd << (   site ? "--site"   : "--no-site"   )
        cmd << (   gems ? "--gems"   : "--no-gems"   )
        cmd << (   home ? "--home"   : "--no-home"   )
      end
      cmd.join(' ')
    end

  end

end

