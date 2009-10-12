module Syckle::Plugins

  # = WebRI Documentation Plugin
  #
  # The webri documentation plugin provides services for
  # generating webri documentation.
  #
  # By default it generates the documentaiton at doc/webri.
  #
  # This plugin provides three services for both the +main+ and +site+ pipelines.
  #
  # * +webri+ - Create webri docs
  # * +reset+ - Reset webri docs
  # * +clean+ - Remove webri docs
  #
  class WebRI < Service #Plugin

    cycle :main, :document
    cycle :site, :document

    cycle :main, :clean
    cycle :site, :clean

    cycle :main, :reset
    cycle :site, :reset

    #available do |project|
    #  !project.metadata.loadpath.empty?
    #end

    # Default location to store ri documentation files.
    DEFAULT_OUTPUT = "doc/webri"

    #
    DEFAULT_RIDOC  = "doc/ri"

    #
    def initialize_defaults
      @title  = metadata.title
      @ridoc  = DEFAULT_RIDOC
      @output = DEFAULT_OUTPUT
    end

    # Title of documents. Defaults to general metadata title field.
    attr_accessor :title

    # Where to save rdoc files (doc/webri).
    attr_accessor :output

    # Location of ri docs. Defaults to doc/ri.
    # These files must be preset for this plugin to work.
    attr_accessor :ridoc

    # In case one is inclined to #ridoc plural.
    alias_accessor :ridocs

    # Generate ri documentation. This utilizes
    # rdoc to produce the appropriate files.
    #
    def document
      output  = self.output

      #cmdopts = {}
      #cmdopts['o'] = output

      #input = files #.collect do |i|
      #  dir?(i) ? File.join(i,'**','*') : i
      #end

      if outofdate?(output, ridoc) or force?
        rm_r(output) if exist?(output) and safe?(output)  # remove old webri docs

        status "Generating #{output} ..."

        #vector = [ridoc, cmdopts]
        #if verbose?
          sh "webri -o #{output} #{ridoc}"
        #else
        #  silently do
        #    sh "webri #{vector.to_console}"
        #  end
        #end
      else
        report "webri docs are current (#{output.sub(Dir.pwd,'')})"
      end
    end

    # Set the output directory's mtime to furthest time in past.
    # This "marks" the documentation as out-of-date.
    def reset
      if File.directory?(output)
        File.utime(0,0,self.output)
        report "reset #{output}"
      end
    end

    # Remove ri products.
    def clean
      if File.directory?(output)
        rm_r(output)
        status "Removed #{output}" #unless dryrun?
      end
    end

  end

end

