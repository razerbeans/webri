require 'webri/components/abstract'


module WebRI

  #
  class Subversion < Component

    #

    def path
      @path ||= Pathname.new(__FILE__).parent
    end

    #

    def initialize_methods
      provision :svninfo
    end

    #
    def svninfo(klass)
      @svninfo ||= {}
      @svninfo[klass] ||= get_svninfo(klass)
    end

    # Try to extract Subversion information out of the first constant whose value looks like
    # a subversion Id tag. If no matching constant is found, and empty hash is returned.
    def get_svninfo(klass)
      constants = klass.constants or return {}

      constants.find {|c| c.value =~ SVNID_PATTERN } or return {}

      filename, rev, date, time, committer = $~.captures
      commitdate = Time.parse( date + ' ' + time )

      return {
        :filename    => filename,
        :rev         => Integer( rev ),
        :commitdate  => commitdate,
        :commitdelta => time_delta_string( Time.now.to_i - commitdate.to_i ),
        :committer   => committer,
      }
    end

    # Subversion rev
    #SVNRev = %$Rev: 52 $

    # Subversion ID
    #SVNId = %$Id: darkfish.rb 52 2009-01-07 02:08:11Z deveiant $

    #
    SVNID_PATTERN = /
      \$Id:\s
        (\S+)\s          # filename
        (\d+)\s          # rev
        (\d{4}-\d{2}-\d{2})\s  # Date (YYYY-MM-DD)
        (\d{2}:\d{2}:\d{2}Z)\s  # Time (HH:MM:SSZ)
        (\w+)\s           # committer
      \$$
    /x

  end

end
