module WebRI

  module Abstract

    module Commons

      #
      # TODO: options = { :verbose => $DEBUG_RDOC, :noop => $dryrun }

      def fileutils
        $dryrun ? FileUtils::DryRun : FileUtils
      end

      # Output progress information if debugging is enabled

      def debug_msg(msg)
        return unless $DEBUG_RDOC
        case msg[-1,1]
          when '.' then tab = "= "
          when ':' then tab = "== "
          else          tab = "* "
        end
        $stderr.puts(tab + msg)
      end

    end

  end

end

