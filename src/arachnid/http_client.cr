require "uri"

module Arachnid
  class HTTPClient

    property browser : Marionette::Browser?

    property endpoint : URI?

    property read_timeout : Int32

    property connect_timeout : Int32

    property max_redirects : Int32

    property headers : Hash(String, String)

    def initialize(
      browser : Marionette::Browser? = nil,
      endpoint : URI? = nil,
      read_timeout : Int32? = nil,
      connect_timeout : Int32? = nil,
      max_redirects : Int32? = nil,
      headers : Hash(String, String)? = nil
    )
      @browser = browser
      @endpoint = endpoint
      @read_timeout = read_timeout || Arachnid.read_timeout
      @connect_timeout = connect_timeout || Arachnid.connect_timeout
      @max_redirects = max_redirects || Arachnid.max_redirects
      @headers = headers || {} of String => String

      @client = Halite::Client.new(
        endpoint: @endpoint.to_s,
        timeout: Halite::Timeout.new(
          connect: @connect_timeout,
          read:  @read_timeout
        ),
        follow: Halite::Follow.new(
          hops: @max_redirects,
          strict: false
        ),
        headers: headers,
      )
    end

    {% for method in [:get, :post, :put, :patch, :delete] %}
      def {{ method.id }}(path, options)
        request({{ method.id.stringify }}, path, options)
      end

      def {{ method.id }}(path, **options)
        request({{ method.id.stringify }}, path, **options)
      end
    {% end %}

    getter client : Halite::Client

    def request(method, path, options)
      if browser = @browser
        url = URI.parse(File.join(@endpoint.to_s, path))
        headers = options[:headers]? ? options[:headers].each_with_object(HTTP::Headers.new) { |(k, v), h| h.add(k,v) } : nil
        body = options[:body]?
        res = browser.proxy.not_nil!.exec(method, url.to_s, headers, body)
        Halite::Response.new(url, res)
      else
        options = Halite::Options.new(**options)
        @client.request(method.to_s, path.to_s, options)
      end
    end

    def request(method, path, **options)
      request(method, path, options)
    end
  end
end
