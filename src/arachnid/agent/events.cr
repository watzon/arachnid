require "../resource"

module Arachnid
  class Agent
    @every_url_blocks = [] of Proc(URI, Nil)

    @every_failed_url_blocks = [] of Proc(URI, Nil)

    @every_url_like_blocks = Hash(String | Regex, Array(Proc(URI, Nil))).new do |hash, key|
      hash[key] = [] of Proc(URI, Nil)
    end

    @every_resource_blocks = [] of Proc(Resource, Nil)

    @every_link_blocks = [] of Proc(URI, URI, Nil)

    # Pass each URL from each resource visited to the given block.
    def every_url(&block : URI ->)
      @every_url_blocks << block
      self
    end

    # Pass each URL that could not be requested to the given block.
    def every_failed_url(&block : URI ->)
      @every_failed_url_blocks << block
      self
    end

    # Pass every URL that the agent visits, and matches a given pattern,
    # to a given block.
    def every_url_like(pattern, &block : URI ->)
      @every_url_like_blocks[pattern] << block
      self
    end

    # Ssee `#every_url_like`
    def urls_like(pattern, &block : URI ->)
      every_url_like(pattern, &block)
    end

    # Pass the headers from every response the agent receives to a given
    # block.
    def all_headers(&block)
      headers = [] of HTTP::Headers
      every_resource { |resource| headers << resource.headers }
      headers.each { |header| yield headers }
    end

    # Pass every resource that the agent visits to a given block.
    def every_resource(&block : Resource ->)
      @every_resource_blocks << block
      self
    end

    # Pass every OK resource that the agent visits to a given block.
    def every_ok_page(&block : Resource ->)
      resources = [] of Resource
      every_resource { |resource| (resources << resource) if resource.ok? }
      resources.each { |resource| yield resource }
    end

    # Pass every Redirect resource that the agent visits to a given block.
    def every_redirect_page(&block : Resource ->)
      resources = [] of Resource
      every_resource { |resource| (resources << resource) if resource.redirect? }
      resources.each { |resource| yield resource }
    end

    # Pass every Timeout resource that the agent visits to a given block.
    def every_timedout_page(&block : Resource ->)
      resources = [] of Resource
      every_resource { |resource| (resources << resource) if resource.timeout? }
      resources.each { |resource| yield resource }
    end

    # Pass every Bad Request resource that the agent visits to a given block.
    def every_bad_request_page(&block : Resource ->)
      resources = [] of Resource
      every_resource { |resource| (resources << resource) if resource.bad_request? }
      resources.each { |resource| yield resource }
    end

    # Pass every Unauthorized resource that the agent visits to a given block.
    def every_unauthorized_page(&block : Resource ->)
      resources = [] of Resource
      every_resource { |resource| (resources << resource) if resource.unauthorized? }
      resources.each { |resource| yield resource }
    end

    # Pass every Forbidden resource that the agent visits to a given block.
    def every_forbidden_page(&block : Resource ->)
      resources = [] of Resource
      every_resource { |resource| (resources << resource) if resource.forbidden? }
      resources.each { |resource| yield resource }
    end

    # Pass every Missing resource that the agent visits to a given block.
    def every_missing_page(&block : Resource ->)
      resources = [] of Resource
      every_resource { |resource| (resources << resource) if resource.missing? }
      resources.each { |resource| yield resource }
    end

    # Pass every Internal Server Error resource that the agent visits to a
    # given block.
    def every_internal_server_error_page(&block : Resource ->)
      resources = [] of Resource
      every_resource { |resource| (resources << resource) if resource.had_internal_server_error? }
      resources.each { |resource| yield resource }
    end

    # Pass every Plain Text resource that the agent visits to a given block.
    def every_txt_page(&block : Resource ->)
      resources = [] of Resource
      every_resource { |resource| (resources << resource) if resource.txt? }
      resources.each { |resource| yield resource }
    end

    # Pass every HTML resource that the agent visits to a given block.
    def every_html_page(&block : Resource ->)
      @every_resource_blocks << ->(resource : Resource) {
        block.call(resource) if resource.html?
      }
    end

    # Pass every XML resource that the agent visits to a given block.
    def every_xml_page(&block : Resource ->)
      @every_resource_blocks << ->(resource : Resource) {
        block.call(resource) if resource.xml?
      }
    end

    # Pass every XML Stylesheet (XSL) resource that the agent visits to a
    # given block.
    def every_xsl_page(&block : Resource ->)
      @every_resource_blocks << ->(resource : Resource) {
        block.call(resource) if resource.xsl?
      }
    end

    # Pass every HTML or XML document that the agent parses to a given
    # block.
    def every_doc(&block : Document::HTML | XML::Node ->)
      @every_resource_blocks << ->(doc : Resource) {
        block.call(resource.doc.not_nil!) if resource.doc
      }
    end

    # Pass every HTML document that the agent parses to a given block.
    def every_html_doc(&block : Document::HTML | XML::Node ->)
      @every_resource_blocks << ->(doc : Resource) {
        block.call(resource.doc.not_nil!) if resource.html?
      }
    end

    # Pass every XML document that the agent parses to a given block.
    def every_xml_doc(&block : XML::Node ->)
      @every_resource_blocks << ->(doc : Resource) {
        block.call(resource.doc.not_nil!) if resource.xml?
      }
    end

    # Pass every XML Stylesheet (XSL) that the agent parses to a given
    # block.
    def every_xsl_doc(&block : XML::Node ->)
      @every_resource_blocks << ->(doc : Resource) {
        block.call(resource.doc.not_nil!) if resource.xsl?
      }
    end

    # Pass every RSS document that the agent parses to a given block.
    def every_rss_doc(&block : XML::Node ->)
      @every_resource_blocks << ->(resource : Resource) {
        block.call(resource) if resource.rss?
      }
    end

    # Pass every Atom document that the agent parses to a given block.
    def every_atom_doc(&block : XML::Node ->)
      @every_resource_blocks << ->(resource : Resource) {
        block.call(resource) if resource.atom?
      }
    end

    # Pass every JavaScript resource that the agent visits to a given blocevery_javascript_resource(&block : Resource ->)
    def every_javascript(&block : Resource ->)
      @every_resource_blocks << ->(resource : Resource) {
        block.call(resource) if resource.javascript?
      }
    end

    # Pass every CSS resource that the agent visits to a given block.
    def every_css(&block : Resource ->)
      @every_resource_blocks << ->(resource : Resource) {
        block.call(resource) if resource.css?
      }
    end

    # Pass every RSS feed that the agent visits to a given block.
    def every_rss(&block : Resource ->)
      @every_resource_blocks << ->(resource : Resource) {
        block.call(resource) if resource.rss?
      }
    end

    # Pass every Atom feed that the agent visits to a given block.
    def every_atom(&block : Resource ->)
      @every_resource_blocks << ->(resource : Resource) {
        block.call(resource) if resource.atom?
      }
    end

    # Pass every MS Word resource that the agent visits to a given block.
    def every_ms_word(&block : Resource ->)
      @every_resource_blocks << ->(resource : Resource) {
        block.call(resource) if resource.ms_word?
      }
    end

    # Pass every PDF resource that the agent visits to a given block.
    def every_pdf(&block : Resource ->)
      @every_resource_blocks << ->(resource : Resource) {
        block.call(resource) if resource.pdf?
      }
    end

    # Pass every ZIP resource that the agent visits to a given block.
    def every_zip(&block : Resource ->)
      @every_resource_blocks << ->(resource : Resource) {
        block.call(resource) if resource.zip?
      }
    end

    # Passes every image resource to the given block.
    def every_image(&block : Resource ->)
      @every_resource_blocks << ->(resource : Resource) {
        block.call(resource) if resource.image?
      }
    end

    # Passes every resource with a matching content type to the given block.
    def every_content_type(content_type : String | Regex, &block : Resource ->)
      @every_resource_blocks << ->(resource : Resource) {
        block.call(resource) if resource.is_content_type?(content_type)
      }
    end

    # Passes every origin and destination URI of each link to a given
    # block.
    def every_link(&block : URI, URI ->)
      @every_link_blocks << block
      self
    end
  end
end
