require "uri"
require "./http_client"

module Arachnid
  # Stores active HTTP Sessions organized by scheme, host-name and port.
  class SessionCache

    # The HTTPClient class to use for requests
    property client : HTTPClient.class

    # Optional read timeout.
    property read_timeout : Int32

    # Optional connect timeout.
    property connect_timeout : Int32

    # Max redirects to follow.
    property max_redirects : Int32?

    @sessions = {} of Tuple(String?, String?, Int32?) => HTTPClient

    # Create a new session cache
    def initialize(
      client : HTTPClient?.class = nil,
      read_timeout : Int32? = nil,
      connect_timeout : Int32? = nil,
      max_redirects : Int32? = nil
    )
      @client = client || HTTPClient::Default
      @read_timeout = read_timeout || Arachnid.read_timeout
      @connect_timeout = connect_timeout || Arachnid.connect_timeout
      @max_redirects = max_redirects || Arachnid.max_redirects
    end

    # Determines if there is an active session for the given URL
    def active?(url)
      # normalize the url
      url = URI.parse(url) unless url.is_a?(URI)

      # session key
      key = key_for(url)

      @sessions.has_key?(key)
    end

    # Provides an active session for a given URL.
    def [](url)
      # normalize the url
      url = URI.parse(url) unless url.is_a?(URI)

      # session key
      key = key_for(url)

      # normalize the endpoint
      endpoint = url.dup
      endpoint.scheme ||= "http"
      endpoint.query = nil
      endpoint.fragment = nil
      endpoint.path = ""

      headers = Hash(String, String).new

      unless @sessions.has_key?(key)
        session = @client.new(
          endpoint: endpoint,
          read_timeout:  @read_timeout,
          connect_timeout: @connect_timeout,
          max_redirects: @max_redirects,
          headers: headers,
        )

        @sessions[key] = session
      end

      @sessions[key]
    end

    # Destroys an HTTP session for the given scheme, host, and port.
    def kill!(url)
      # normalize the url
      url = URI.parse(url) unless url.is_a?(URI)

      # session key
      key = key_for(url)

      if sess = @sessions[key]
        @sessions.delete(key)
      end
    end

    # Clears the session cache
    def clear
      @sessions.clear
    end

    # Creates a session key based on the URL
    private def key_for(url)
      {url.scheme, url.host, url.port}
    end
  end
end
