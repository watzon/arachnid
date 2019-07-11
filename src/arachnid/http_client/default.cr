require "halite"

module Arachnid
  abstract class HTTPClient
    class Default < HTTPClient

      getter client : Halite::Client

      def initialize(
        endpoint : URI? = nil,
        read_timeout : Int32? = nil,
        connect_timeout : Int32? = nil,
        max_redirects : Int32? = nil,
        headers : Hash(String, String)? = nil
      )
        super(endpoint, read_timeout, connect_timeout, max_redirects, headers)

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

      def request(method, path, options)
        options = Halite::Options.new(**options)
        @client.request(method.to_s, path.to_s, options)
      end

    end
  end
end
