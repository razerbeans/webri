require 'webri/server'

module WRI

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

library = ARGV[0]

service = WRI::RiService.new(library)

wri = WRI::Server.new(service)
#puts wri.to_html

require 'webrick'
include WEBrick

p wri.directory + "/public"

s = HTTPServer.new(
  :Port            => 8888,
  :DocumentRoot    => wri.directory + "/public"
)

s.mount_proc("/"){|req, res|
  res.body = wri.to_html
  res['Content-Type'] = "text/html"
}

s.mount_proc("/ri"){|req, res|
  res.body = wri.lookup(req)
  res['Content-Type'] = "text/html"
}

## mount subdirectories
s.mount("/js",  HTTPServlet::FileHandler, wri.directory + "/public/js")
s.mount("/css", HTTPServlet::FileHandler, wri.directory + "/public/css")
s.mount("/img", HTTPServlet::FileHandler, wri.directory + "/public/img")

trap("INT"){ s.shutdown }
s.start

