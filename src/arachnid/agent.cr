module Arachnid
  class Agent
    DEFAULT_USER_AGENT = "Arachnid #{Arachnid::VERSION} for Crystal #{Crystal::VERSION}"

    getter request_handler : RequestHandler

    def initialize(client : (HTTP::Client.class)? = nil,
                   request_headers = HTTP::Headers.new,
                   user_agent = DEFAULT_USER_AGENT)
      client ||= HTTP::Client
      request_headers["User-Agent"] ||= user_agent
      @request_handler = RequestHandler.new(client, request_headers)
    end
  end
end
