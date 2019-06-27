require "./agent/sanitizers"
require "./agent/filters"
require "./agent/events"
require "./agent/actions"
require "./agent/robots"
require "./resource"
require "./session_cache"
require "./cookie_jar"
require "./auth_store"

module Arachnid
  class Agent

    getter? running : Bool

    # Set to limit to a single host.
    property host : String?

    # User agent to use.
    property user_agent : String

    # HTTP Host Header to use.
    property host_header : String?

    # HTTP Host Headers to use for specific hosts.
    property host_headers : Hash(String | Regex, String)

    # HTTP Headers to use for every request.
    property default_headers : Hash(String, String)

    # HTTP Authentication credentials.
    property authorized : AuthStore

    # Referer to use.
    property referer : String?

    # Delay in between fetching resources.
    property fetch_delay : Time::Span | Int32

    # History containing visited URLs.
    getter history : Set(URI)

    # List of unreachable URIs.
    getter failures : Set(URI)

    # Queue of URLs to visit.
    getter queue : Hash(String, URI)

    # The session cache.
    property sessions : SessionCache

    # Cached cookies.
    property cookies : CookieJar

    # Maximum number of resources to visit.
    property limit : Int32?

    # Maximum depth.
    property max_depth : Int32?

    # The visited URLs and their depth within a site.
    property levels : Hash(URI, Int32)

    # Creates a new `Agent` object.
    def initialize(
      host : String? = nil,
      read_timeout : Int32? = nil,
      connect_timeout : Int32? = nil,
      max_redirects : Int32? = nil,
      do_not_track : Bool? = nil,
      default_headers : Hash(String, String)? = nil,
      host_header : String? = nil,
      host_headers : Hash(String | Regex, String)? = nil,
      user_agent : String? = nil,
      referer : String? = nil,
      fetch_delay : (Int32 | Time::Span)? = nil,
      queue : Hash(String, URI)? = nil,
      history : Set(URI)? = nil,
      limit : Int32? = nil,
      max_depth : Int32? = nil,
      robots : Bool? = nil,
      filter_options = nil
    )
      @host = host

      @host_header = host_header
      @host_headers = host_headers || {} of (Regex | String) => String
      @default_headers = default_headers || {} of String => String

      @user_agent = user_agent || Arachnid.user_agent
      @referer = referer

      @running = false
      @fetch_delay = fetch_delay || 0
      @history = history || Set(URI).new
      @failures = Set(URI).new
      @queue = queue || {} of String => URI

      @limit = limit
      @levels = {} of URI => Int32
      @max_depth = max_depth

      @sessions = SessionCache.new(
        read_timeout,
        connect_timeout,
        max_redirects,
        do_not_track
      )

      @cookies = CookieJar.new
      @authorized = AuthStore.new

      if filter_options
        initialize_filters(**filter_options)
      else
        initialize_filters
      end

      initialize_robots if robots || Arachnid.robots?
    end

    # Create a new scoped `Agent` in a block.
    def self.new(**options, &block : Agent ->)
      _new = new(**options)
      with _new yield _new
      _new
    end

    # Creates a new `Agent` and begins spidering at the given URL.
    def self.start_at(url, **options, &block : Agent ->)
      agent = new(**options, &block)
      agent.start_at(url, force: true)
    end

    # Creates a new `Agent` and spiders the web site located
    # at the given URL.
    def self.site(url, **options, &block : Agent ->)
      url = url.is_a?(URI) ? url : URI.parse(url)
      url_regex = Regex.new(url.host.to_s)

      agent = new(**options, &block)
      agent.visit_hosts_like(url_regex)

      agent.start_at(url, force: true)
    end

    # Creates a new `Agent` and spiders the given host.
    def self.host(url, **options, &block : Agent ->)
      url = url.is_a?(URI) ? url : URI.parse(url)

      options = options.merge(host: url.host)
      agent = new(**options, &block)

      agent.start_at(url, force: true)
    end

    # Clears the history of the `Agent`.
    def clear
      @queue.clear
      @history.clear
      @failures.clear
      self
    end

    # Start spidering at a given URL.
    # def start_at(url, &block : Resource ->)
    #   enqueue(url)
    #   run(&block)
    # end

    # Start spidering at a given URL.
    def start_at(url, force = false)
      enqueue(url, force: force)
      return run
    end

    # Start spidering until the queue becomes empty or the
    # agent is paused.
    # def run(&block : Resource ->)
    #   @running = true

    #   until @queue.empty? || paused? || limit_reached?
    #     begin
    #       visit_resource(dequeue, &block)
    #     rescue Actions::Paused
    #       return self
    #     rescue Actions::Action
    #     end
    #   end

    #   @running = false
    #   @sessions.clear
    #   self
    # end

    # Start spidering until the queue becomes empty or the
    # agent is paused.
    def run
      @running = true

      until @queue.empty? || paused? || limit_reached? || !running?
        begin
          visit_resource(dequeue)
        rescue Actions::Paused
          return self
        rescue Actions::Action
        end
      end

      @running = false
      @sessions.clear
      self
    end

    # Sets the history of URLs that were previously visited.
    def history=(new_history)
      @history.clear

      new_history.each do |url|
        @history << url.is_a?(URI) ? url : URI.parse(url)
      end

      @history
    end

    # Specifies the links which have been visited.
    def visited_links
      @history.map(&.to_s)
    end

    # Specifies the hosts which have been visited.
    def visited_hosts
      history.map(&.host)
    end

    # Determines whether a URL was visited or not.
    def visited?(url)
      url = url.is_a?(URI) ? url : URI.parse(url)
      @history.includes?(url)
    end

    # Sets the list of failed URLs.
    def failures=(new_failures)
      @failures.clear

      new_failures.each do |url|
        @failures << url.is_a?(URI) ? url : URI.parse(url)
      end

      @failures
    end

    # Determines whether a given URL could not be visited.
    def failed?(url)
      url = url.is_a?(URI) ? url : URI.parse(url)
      @failures.includes?(url)
    end

    # Sets the queue of URLs to visit.
    # Sets the list of failed URLs.
    def queue=(new_queue)
      @queue.clear

      new_queue.each do |url|
        @queue[queue_key(url)] = url
      end

      @queue
    end

    # Determines whether the given URL has been queued for visiting.
    def queued?(key)
      @queue.has_key?(key)
    end

    # Enqueues a given URL for visiting, only if it passes all
    # of the agent's rules for visiting a given URL.
    def enqueue(url, level = 0, force = false)
      url = sanitize_url(url)

      if (!queued?(url) && visit?(url)) || force
        link = url.to_s

        return if url.host.to_s.empty?

        begin
          @every_url_blocks.each { |url_block| url_block.call(url) }

          @every_url_like_blocks.each do |pattern, url_blocks|
            match = case pattern
                    when Regex
                      link =~ pattern
                    else
                      (pattern == link) || (pattern == url)
                    end

            if match
              url_blocks.each { |url_block| url_block.call(url) }
            end
          end
        rescue action : Actions::Paused
          raise(action)
        rescue Actions::SkipLink
          return false
        rescue Actions::Action
        end

        @queue[queue_key(url)] = url
        @levels[url] = level
        true
      end
    end

    # Gets and creates a new `Resource` object from a given URL,
    # yielding the newly created resource.
    def get_resource(url, &block)
      url = url.is_a?(URI) ? url : URI.parse(url)

      prepare_request(url) do |session, path, handlers|
        new_resource = Resource.new(url, session.get(path, headers: handlers))

        # save any new cookies
        @cookies.from_resource(new_resource)

        yield new_resource
        return new_resource
      end
    end

    # Gets and creates a new `Resource` object from a given URL.
    def get_resource(url)
      url = url.is_a?(URI) ? url : URI.parse(url)

      prepare_request(url) do |session, path, handlers|
        new_resource = Resource.new(url, session.get(path, handlers))

        # save any new cookies
        @cookies.from_resource(new_resource)

        return new_resource
      end
    end

    # Posts supplied form data and creates a new Resource from a given URL,
    # yielding the newly created resource.
    def post_resource(url, post_data = "", &block)
      url = url.is_a?(URI) ? url : URI.parse(url)

      prepare_request(url) do |session, path, handlers|
        new_resource = Resource.new(url, session.post(path, post_data, handlers))

        # save any new cookies
        @cookies.from_resource(new_resource)

        yield new_resource
        return new_resource
      end
    end

    # Posts supplied form data and creates a new Resource from a given URL.
    def post_resource(url, post_data = "")
      url = url.is_a?(URI) ? url : URI.parse(url)

      prepare_request(url) do |session, path, handlers|
        new_resource = Resource.new(url, session.post(path, post_data, handlers))

        # save any new cookies
        @cookies.from_resource(new_resource)

        return new_resource
      end
    end

    # Visits a given URL and enqueues the links recovered
    # from the resource to be visited later.
    # def visit_resource(url, &block : Resource ->)
    #   url = sanitize_url(url)

    #   get_resource(url) do |resource|
    #     @history << resource.url

    #     begin
    #       @every_resource_blocks.each { |resource_block| resource_block.call(resource) }
    #       yield resource
    #     rescue action : Actions::Paused
    #       raise(action)
    #     rescue Actions::SkipResource
    #       return Nil
    #     rescue Actions::Action
    #     end

    #     resource.each_url do |next_url|
    #       begin
    #         @every_link_blocks.each do |link_block|
    #           link_block.call(resource.url, next_url)
    #         end
    #       rescue action : Actions::Paused
    #         raise(action)
    #       rescue Actions::SkipLink
    #         next
    #       rescue Actions::Action
    #       end

    #       if @max_depth.nil? || @max_depth.not_nil! > (@levels[url]? || 0)
    #         @levels[url] ||= 0
    #         enqueue(next_url, @levels[url] + 1)
    #       end
    #     end
    #   end
    # end

    # Visits a given URL and enqueues the links recovered
    # from the resource to be visited later.
    def visit_resource(url)
      url = sanitize_url(url)

      get_resource(url) do |resource|
        @history << resource.url

        begin
          @every_resource_blocks.each { |resource_block| resource_block.call(resource) }
        rescue action : Actions::Paused
          raise(action)
        rescue Actions::SkipResource
          return nil
        rescue Actions::Action
        end

        resource.each_url do |next_url|
          begin
            @every_link_blocks.each do |link_block|
              link_block.call(resource.url, next_url)
            end
          rescue action : Actions::Paused
            raise(action)
          rescue Actions::SkipLink
            next
          rescue Actions::Action
          end

          if @max_depth.nil? || @max_depth.not_nil! > (@levels[url]? || 0)
            @levels[url] ||= 0
            enqueue(next_url, @levels[url] + 1)
          end
        end
      end
    end

    # Converts the agent into a hash.
    def to_h
      {"history" => @history, "queue" => @queue}
    end

    # Prepares request headers for a given URL.
    protected def prepare_request_headers(url)
      # set any additional HTTP headers
      headers = @default_headers.dup

      unless @host_headers.empty?
        @host_headers.each do |name, header|
          if url.host =~ name
            headers["Host"] = header
            break
          end
        end
      end

      headers["Host"] ||= @host_header.to_s if @host_header
      headers["User-Agent"] ||= @user_agent.to_s
      headers["Referer"] ||= @referer.to_s if @referer

      if authorization = @authorized.for_url(url.host.to_s)
        headers["Authorization"] = "Basic #{authorization}"
      end

      if header_cookies = @cookies.for_host(url.host.to_s)
        headers["Cookie"] = header_cookies.to_cookie_header
      end

      headers
    end

    # Normalizes the request path and grabs a session to handle
    # resource get and post requests.
    def prepare_request(url, &block)
      path = if url.path.empty?
               "/"
             else
               url.path
             end

      # append the URL query to the path
      path += "?#{url.query}" if url.query

      headers = prepare_request_headers(url)

      begin
        sleep(@fetch_delay) if @fetch_delay.to_i > 0

        yield @sessions[url], path, headers
      rescue Halite::Exception::Error | IO::Error | Socket::Error | OpenSSL::SSL::Error
        @sessions.kill!(url)
        return nil
      end
    end

    # Dequeues a URL that will later be visited.
    def dequeue
      @queue.shift[1]
    end

    # Determines if the maximum limit has been reached.
    def limit_reached?
      if limit = @limit
        return @history.size >= limit
      end
      false
    end

    # Determines if a given URL should be visited.
    def visit?(url)
      !visited?(url) &&
        visit_scheme?(url.scheme.to_s) &&
        visit_host?(url.host.to_s) &&
        visit_port?(url.port || -1) &&
        visit_link?(url.to_s) &&
        visit_url?(url) &&
        visit_ext?(url.path)
        # robot_allowed?(url.to_s)
    end

    # Adds a given URL to the failures list.
    def failed(url)
      @failures << url
      @every_failed_url_blocks.each { |fail_block| fail_block.call(url) }
      true
    end

    private def queue_key(url)
      "#{url.host}:#{url.port}"
    end
  end
end
