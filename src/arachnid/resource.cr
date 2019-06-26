require "uri"
require "halite"

require "./resource/content_types"
require "./resource/cookies"
require "./resource/html"
require "./resource/status_codes"

require "./document/html"

module Arachnid
  # Represents a resource requested from a website
  class Resource
    include Resource::ContentTypes
    include Resource::Cookies
    include Resource::HTML
    include Resource::StatusCodes

    # URL of the resource
    getter url : URI

    # HTTP response
    getter response : Halite::Response

    # Headers returned with the body
    getter headers : HTTP::Headers

    @doc : (Document::HTML | XML::Node)?

    delegate xpath, xpath_node, xpath_nodes, xpath_bool, xpath_float, xpath_string,
      root, at_tag, where_tag, where_class, at_id, css, at_css, to: @doc

    # forward_missing_to @headers

    # Creates a new `Resource` object.
    def initialize(url : URI, response : Halite::Response)
      @url = url
      @response = response
      @headers = response.headers
    end

    # The body of the response
    def body
      @response.body || ""
    end

    # Returns a parsed document for HTML, XML, RSS, and Atom resources.
    def doc
      unless body.empty?
        doc_class = if html?
          Document::HTML
        elsif rss? || atom? || xml? || xsl?
          XML
        end

        if doc_class
          begin
            @doc ||= doc_class.parse(body)
          rescue
          end
        end
      end
    end

    # Searches the document for XPath or CSS paths
    def search(path)
      if document = doc
        document.xpath_nodes(path)
      else
        [] of XML::Node
      end
    end

    # Searches for the first occurrence of an XPath or CSS path
    def at(path)
      if document = doc
        document.xpath_node(path)
      end
    end

    # Alias for `#search`
    def /(path)
      search(path)
    end

    # Alias for `#at`
    def %(path)
      at(path)
    end

    # Get the size of the body in bytes (useful for binaries)
    def size
      @response.body.bytesize
    end

    def to_s
      body
    end
  end
end
