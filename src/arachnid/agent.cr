require "./resource"

module Arachnid
  class Agent
    DEFAULT_USER_AGENT = "Arachnid #{Arachnid::VERSION} for Crystal #{Crystal::VERSION}"

    getter request_handler : RequestHandler

    getter accept_filters : Array(Proc(URI, Bool))

    getter reject_filters : Array(Proc(URI, Bool))

    getter? running : Bool

    property queue : Queue

    property default_headers : HTTP::Headers

    property host_headers : Hash(String, HTTP::Headers)

    property? stop_on_empty : Bool

    property? follow_redirects : Bool

    def initialize(client : (HTTP::Client.class)? = nil,
                   user_agent = DEFAULT_USER_AGENT,
                   default_headers = HTTP::Headers.new,
                   host_headers = {} of String => HTTP::Headers,
                   queue = Queue::Memory.new,
                   stop_on_empty = true,
                   follow_redirects = true)
      client ||= HTTP::Client
      @request_handler = RequestHandler.new(client)
      @queue = queue.is_a?(Array) ? Queue::Memory.new : queue

      @user_agent = user_agent
      @default_headers = default_headers
      @host_headers = host_headers
      @stop_on_empty = stop_on_empty
      @follow_redirects = follow_redirects

      @accept_filters = [] of Proc(URI, Bool)
      @reject_filters = [] of Proc(URI, Bool)

      @running = false
    end

    def start_at(uri, &block)
      uri = ensure_scheme(uri)
      enqueue(uri, force: true)
      with self yield self
      start
    end

    def site(site, &block)
      uri = ensure_scheme(site)
      enqueue(uri, force: true)
      accept_filter { |u| u.host.to_s.ends_with?(uri.host.to_s) }
      with self yield self
      start
    end

    def host(host, &block)
      uri = ensure_scheme(host)
      enqueue(uri, force: true)
      accept_filter { |u| u.host == uri.host }
      with self yield self
      start
    end

    def stop
      @running = false
    end

    def start
      @running = true

      while @running
        break if stop_on_empty? && @queue.empty?
        unless @queue.empty?
          next_uri = @queue.dequeue

          Log.debug { "Scanning #{next_uri.to_s}" }

          headers = build_headers_for(next_uri)
          response = @request_handler.request(:get, next_uri, headers: headers)
          resource = Resource.from_content_type(next_uri, response)

          @resource_handlers.each do |handler|
            handler.call(resource)
          end

          # Call the registered handlers for this resource
          {% begin %}
          case resource
          {% for subclass in Arachnid::Resource.subclasses %}
          {% resname = subclass.name.split("::").last.downcase.underscore.id %}
          when {{ subclass.id }}
            @{{ resname }}_handlers.each do |handler|
              handler.call(resource)
            end
          {% end %}
          end
          {% end %}

          # If the resource has an each_uel method let's pull out
          # it's urls and enqueue all of them.
          if resource.responds_to?(:each_url)
            resource.each_url do |uri|
              enqueue(uri)
            end
          end

          # Check for redirects
          if (300..399).includes?(response.status_code)
            if location = response.headers["Location"]?
              uri = URI.parse(location)
              @queue.enqueue(uri)
            end
          end
        end
      end
    end

    def enqueue(uri, force = false)
      uri = ensure_scheme(uri)
      if force
        @queue.enqueue(uri)
      elsif !@queue.includes?(uri) && filter(uri)
        @queue.enqueue(uri)
      end
    end

    def accept_filter(&block : URI -> Bool)
      @accept_filters << block
    end

    def reject_filter(&block : URI -> Bool)
      @reject_filters << block
    end

    @resource_handlers = [] of Proc(Resource, Nil)
    def on_resource(&block : Resource ->)
      @resource_handlers << block
    end

    {% for subclass in Arachnid::Resource.subclasses %}
      {% resname = subclass.name.split("::").last.downcase.underscore.id %}
      @{{ resname }}_handlers = [] of Proc({{ subclass.id }}, Nil)

      # Create a handler for when a {{ subclass.id }} resource is found. The
      # resource will be passed to the block.
      def on_{{ resname }}(&block : {{ subclass.id }} ->)
        @{{ resname }}_handlers << block
      end
    {% end %}

    private def build_headers_for(uri)
      headers = @default_headers.dup
      headers["User-Agent"] ||= @user_agent

      if host_headers = @host_headers[uri.host.to_s]?
        headers.merge!(host_headers)
      end

      # TODO: Authorization and Cookies

      headers
    end

    private def filter(uri)
      return true if @accept_filters.empty? && @reject_filters.empty?
      return false unless !@reject_filters.empty? && !@reject_filters.any?(&.call(uri))
      return false unless @accept_filters.empty? || @accept_filters.any?(&.call(uri))
      true
    end

    private def ensure_scheme(uri : URI | String)
      if uri.is_a?(URI)
        if uri.scheme.nil? || uri.scheme.to_s.empty?
          uri.scheme = "http"
        end
      else
        if !uri.starts_with?("http")
          uri = "http://#{uri}"
        end
        uri = URI.parse(uri)
      end

      uri.as(URI)
    end
  end
end
