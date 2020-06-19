require "pool/connection"

module Arachnid
  # Class for handling multiple simultanious requests for different hosts. Each host maintains it's own
  # dedicated pool of HTTP clients to pick from when needed, so as to keep things thread safe.
  class RequestHandler
    # The base client class to use for creating new pool items. All clients must extend
    # HTTP::Client in order to work. If your client needs special initialization
    # parameters, think about wrapping it in a class that doesn't and
    # providing initializers as class variables.
    property base_client : HTTP::Client.class

    # Any headers that should be sent on every request.
    property request_headers : HTTP::Headers

    # The maximum number of pools items to store per host. This will be the maximum number
    # of concurrent connections that any one host can have at a time.
    property max_pool_size : Int32

    # The initial size of each pool. Keep this number low, so as to avoid using too much memory.
    property initial_pool_size : Int32

    # The maximum amount of time to wait for a request to finish before raising an `IO::TimeoutError`.
    property connection_timeout : Time::Span

    # A client specific TLS context instance.
    # TODO: Allow this to be unique to each host.
    property tls_context : HTTP::Client::TLSContext

    # A map of host name to connection pool. If `max_hosts` is a non-nil value, this hash will
    # be limited in size to that number, with older hosts being deleted to save on
    # memory usage.
    getter session_pools : Hash(String, ConnectionPool(HTTP::Client))

    # Create a new `RequestHandler` instance.
    def initialize(@base_client,
                   @request_headers,
                   @tls_context : HTTP::Client::TLSContext = nil,
                   @max_pool_size  = 10,
                   @initial_pool_size = 1,
                   @connection_timeout = 1.second)
      @session_pools = {} of String => ConnectionPool(HTTP::Client)
    end

    # Make a request using the connection pool for the given URL's host. This could potentially
    # throw an `IO::TimeoutError` if a request is made and a new client isn't fetched in time.
    def request(method, url : String | URI, headers = nil)
      uri = url.is_a?(URI) ? url : URI.parse(url)
      pool = pool_for(url)
      client = pool.checkout
      headers = headers ? @request_headers.merge(headers) : @request_headers
      response = client.exec(method.to_s.upcase, uri.full_path, headers: headers)
      pool.checkin(client)
      response
    end

    # Retrieve the connection pool for the given `URI`.
    def pool_for(uri : URI)
      if host = uri.host
        session_pools[host] ||= ConnectionPool(HTTP::Client).new(capacity: @max_pool_size, initial: @initial_pool_size, timeout: @connection_timeout.total_seconds) do
          @base_client.new(host.to_s, tls: @tls_context)
        end
      else
        raise "Invalid URI" # TODO: Real error handling
      end
    end

    # Retrieve a connection pool for the given URL's host.
    def pool_for(url : String)
      uri = URI.parse(url)
      self.pool_for(uri)
    end
  end
end
