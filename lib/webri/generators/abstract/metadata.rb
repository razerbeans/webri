require 'webri/components/abstract'
require 'ostruct'

module WebRI

  # Metadata mixin, needs #path_base.
  #
  module Metadata

    #
    def metadata
      @metadata ||= get_metadata
    end

    #
    def get_metadata
      data = OpenStruct.new
      begin
        require 'pom/metadata'
        pom = POM::Metadata.load(path_base)
        raise LoadError unless pom.name
        data.title       = pom.title
        data.version     = pom.version
        data.subtitle    = pom.subtitle
        data.homepage    = pom.homepage
        data.development = pom.development
        data.mailinglist = pom.mailinglist
        data.forum       = pom.forum
        data.wiki        = pom.wiki
        data.blog        = pom.blog
        data.copyright   = pom.copyright
      rescue LoadError
        if file = Dir[path_base + '*.gemspec'].first
          gem = YAML.load(file)
          data.title       = gem.title
          data.version     = gem.version
          data.subtitle    = nil
          date.homepage    = gem.homepage
          data.mailinglist = gem.email
          date.development = nil # TODO: how to improve?
          data.forum       = nil
          data.wiki        = nil
          data.blog        = nil
          data.copyright   = nil
        else
          # TODO: we may be able to develop some other hueristics here, but for now, nope.
        end
      end
      return data
    end

    #
    def scm
      Dir[File.join(path_base.to_s,"{.svn,.git}")].first
    end

  end

end

