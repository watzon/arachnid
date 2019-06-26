require "../rules"

module Arachnid
  class Agent
    # List of acceptable URL schemes to follow
    getter schemes : Array(String) = [] of String

    @host_rules = Rules(String).new
    @port_rules = Rules(Int32).new
    @link_rules = Rules(String).new
    @url_rules = Rules(URI).new
    @ext_rules = Rules(String).new

    # Sets the list of acceptable URL schemes to visit.
    def schemes=(new_schemes)
      @schemes = new_schemes.map(&.to_s)
    end

    # Specifies the patterns that match host-names to visit.
    def visit_hosts
      @host_rules.accept
    end

    # Adds a given pattern to the `#visit_hosts`.
    def visit_hosts_like(pattern)
      visit_hosts << pattern
      self
    end

    def visit_hosts_like(&block)
      visit_hosts << block
      self
    end

    # Specifies the patterns that match host-names to not visit.
    def ignore_hosts
      @host_rules.reject
    end

    # Adds a given pattern to the `#ignore_hosts`.
    def ignore_hosts_like(pattern)
      ignore_hosts << pattern
      self
    end

    def ignore_hosts_like(&block)
      ignore_hosts << block
      self
    end

    # Specifies the patterns that match the ports to visit.
    def visit_ports
      @port_rules.accept
    end

    # Adds a given pattern to the `#visit_ports`.
    def visit_ports_like(pattern)
      visit_ports << pattern
      self
    end

    def visit_ports_like(&block : Int32 -> Bool)
      visit_ports << block
      self
    end

    # Specifies the patterns that match ports to not visit.
    def ignore_ports
      @port_rules.reject
    end

    # Adds a given pattern to the `#ignore_ports`.
    def ignore_ports_like(pattern)
      ignore_ports << pattern
      self
    end

    def ignore_ports_like(&block : Int32 -> Bool)
      ignore_ports << block
      self
    end

    # Specifies the patterns that match the links to visit.
    def visit_links
      @link_rules.accept
    end

    # Adds a given pattern to the `#visit_links`
    def visit_links_like(pattern)
      visit_links << pattern
      self
    end

    def visit_links_like(&block : String -> Bool)
      visit_links << block
      self
    end

    # Specifies the patterns that match links to not visit.
    def ignore_links
      @link_rules.reject
    end

    # Adds a given pattern to the `#ignore_links`.
    def ignore_links_like(pattern)
      ignore_links << pattern
      self
    end

    def ignore_links_like(&block : String -> Bool)
      ignore_links << block
      self
    end

    # Specifies the patterns that match the URLs to visit.
    def visit_urls
      @url_rules.accept
    end

    # Adds a given pattern to the `#visit_urls`
    def visit_urls_like(&block : URI -> Bool)
      visit_urls << block
      self
    end

    def visit_urls_like(pattern)
      visit_urls << pattern
      self
    end

    # Specifies the patterns that match URLs to not visit.
    def ignore_urls
      @url_rules.reject
    end

    # Adds a given pattern to the `#ignore_urls`.
    def ignore_urls_like(&block : URI -> Bool)
      ignore_urls << block
      self
    end

    def ignore_urls_like(pattern)
      ignore_urls << pattern
      self
    end

    # Specifies the patterns that match the URI path extensions to visit.
    def visit_exts
      @ext_rules.accept
    end

    # Adds a given pattern to the `#visit_exts`.
    def visit_exts_like(&block : String -> Bool)
      visit_exts << block
      self
    end

    def visit_exts_like(pattern)
      visit_exts << pattern
      self
    end

    # Specifies the patterns that match URI path extensions to not visit.
    def ignore_exts
      @ext_rules.reject
    end

    # Adds a given pattern to the `#ignore_exts`.
    def ignore_exts_like(&block : String -> Bool)
      ignore_exts << block
      self
    end

    def ignore_exts_like(pattern)
      ignore_exts << pattern
      self
    end

    # Initializes filtering rules.
    protected def initialize_filters(
      schemes = nil,
      hosts = nil,
      ignore_hosts = nil,
      ports = nil,
      ignore_ports = nil,
      links = nil,
      ignore_links = nil,
      urls = nil,
      ignore_urls = nil,
      exts = nil,
      ignore_exts = nil
    )

      if schemes
        self.schemes = schemes
      else
        @schemes << "http"
        @schemes << "https"
      end

      @host_rules.accept = hosts
      @host_rules.reject = ignore_hosts

      @port_rules.accept = ports
      @port_rules.reject = ignore_ports

      @link_rules.accept = links
      @link_rules.reject = ignore_links

      @url_rules.accept = urls
      @url_rules.reject = ignore_urls

      @ext_rules.accept = exts
      @ext_rules.reject = ignore_exts

      if host
        visit_hosts_like(host.to_s)
      end
    end

    # Determines if a given URI scheme should be visited.
    protected def visit_scheme?(scheme)
      if scheme
        @schemes.includes?(scheme)
      else
        true
      end
    end

    # Determines if a given host-name should be visited.
    protected def visit_host?(host)
      @host_rules.accept?(host)
    end

    # Determines if a given port should be visited.
    protected def visit_port?(port)
      @port_rules.accept?(port)
    end

    # Determines if a given link should be visited.
    protected def visit_link?(link)
      @link_rules.accept?(link)
    end

    # Determines if a given URL should be visited.
    protected def visit_url?(link)
      @url_rules.accept?(link)
    end

    # Determines if a given URI path extension should be visited.
    protected def visit_ext?(path)
      ext = File.extname(path)
      @ext_rules.accept?(ext)
    end
  end
end
