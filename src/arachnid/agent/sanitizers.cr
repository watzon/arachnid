module Arachnid
  class Agent
    # Specifies whether the Agent will strip URI fragments
    property? strip_fragments : Bool = true

    # Specifies whether the Agent will strip URI queries
    property? strip_query : Bool = false

    # Sanitizes a URL based on filtering options
    def sanitize_url(url)
      # normalize the url
      url = URI.parse(url) unless url.is_a?(URI)

      url.path = "" if url.path == "/"
      url.fragment = nil if @strip_fragments
      url.query = nil if @strip_query

      url
    end
  end
end
