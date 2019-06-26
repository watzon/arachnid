require "../page"

module Arachnid
  class Agent
    @every_url_blocks = [] of Proc(URI, Nil)

    @every_failed_url_blocks = [] of Proc(URI, Nil)

    @every_url_like_blocks = Hash(String | Regex, Array(Proc(URI, Nil))).new do |hash, key|
      hash[key] = [] of Proc(URI, Nil)
    end

    @every_page_blocks = [] of Proc(Page, Nil)

    @every_link_blocks = [] of Proc(URI, URI, Nil)

    # Pass each URL from each page visited to the given block.
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
      every_page { |page| headers << page.headers }
      headers.each { |header| yield headers }
    end

    # Pass every page that the agent visits to a given block.
    def every_page(&block : Page ->)
      @every_page_blocks << block
      self
    end

    # Pass every OK page that the agent visits to a given block.
    def every_ok_page(&block : Page ->)
      pages = [] of Page
      every_page { |page| (pages << page) if page.ok? }
      pages.each { |page| yield page }
    end

    # Pass every Redirect page that the agent visits to a given block.
    def every_redirect_page(&block : Page ->)
      pages = [] of Page
      every_page { |page| (pages << page) if page.redirect? }
      pages.each { |page| yield page }
    end

    # Pass every Timeout page that the agent visits to a given block.
    def every_timedout_page(&block : Page ->)
      pages = [] of Page
      every_page { |page| (pages << page) if page.timeout? }
      pages.each { |page| yield page }
    end

    # Pass every Bad Request page that the agent visits to a given block.
    def every_bad_request_page(&block : Page ->)
      pages = [] of Page
      every_page { |page| (pages << page) if page.bad_request? }
      pages.each { |page| yield page }
    end

    # Pass every Unauthorized page that the agent visits to a given block.
    def every_unauthorized_page(&block : Page ->)
      pages = [] of Page
      every_page { |page| (pages << page) if page.unauthorized? }
      pages.each { |page| yield page }
    end

    # Pass every Forbidden page that the agent visits to a given block.
    def every_forbidden_page(&block : Page ->)
      pages = [] of Page
      every_page { |page| (pages << page) if page.forbidden? }
      pages.each { |page| yield page }
    end

    # Pass every Missing page that the agent visits to a given block.
    def every_missing_page(&block : Page ->)
      pages = [] of Page
      every_page { |page| (pages << page) if page.missing? }
      pages.each { |page| yield page }
    end

    # Pass every Internal Server Error page that the agent visits to a
    # given block.
    def every_internal_server_error_page(&block : Page ->)
      pages = [] of Page
      every_page { |page| (pages << page) if page.had_internal_server_error? }
      pages.each { |page| yield page }
    end

    # Pass every Plain Text page that the agent visits to a given block.
    def every_txt_page(&block : Page ->)
      pages = [] of Page
      every_page { |page| (pages << page) if page.txt? }
      pages.each { |page| yield page }
    end

    # Pass every HTML page that the agent visits to a given block.
    def every_html_page(&block : Page ->)
      pages = [] of Page
      every_page { |page| (pages << page) if page.html? }
      pages.each { |page| yield page }
    end

    # Pass every XML page that the agent visits to a given block.
    def every_xml_page(&block : Page ->)
      pages = [] of Page
      every_page { |page| (pages << page) if page.xml? }
      pages.each { |page| yield page }
    end

    # Pass every XML Stylesheet (XSL) page that the agent visits to a
    # given block.
    def every_xsl_page(&block : Page ->)
      pages = [] of Page
      every_page { |page| (pages << page) if page.xsl? }
      pages.each { |page| yield page }
    end

    # Pass every HTML or XML document that the agent parses to a given
    # block.
    def every_doc(&block : Document::HTML | XML::Node ->)
      docs = [] of Document::HTML || XML::Node
      every_page { |page| docs << page.doc.not_nil! if page.doc }
      docs.each { |doc| yield doc }
    end

    # Pass every HTML document that the agent parses to a given block.
    def every_html_doc(&block : Document::HTML | XML::Node ->)
      docs = [] of Document::HTML
      every_page { |page| docs << page.doc.not_nil! if page.html? }
      docs.each { |doc| yield doc }
    end

    # Pass every XML document that the agent parses to a given block.
    def every_xml_doc(&block : XML::Node ->)
      docs = [] of XML::Node
      every_page { |page| docs << page.doc.not_nil! if page.xml? }
      docs.each { |doc| yield doc }
    end

    # Pass every XML Stylesheet (XSL) that the agent parses to a given
    # block.
    def every_xsl_doc(&block : XML::Node ->)
      docs = [] of XML::Node
      every_page { |page| docs << page.doc.not_nil! if page.xsl? }
      docs.each { |doc| yield doc }
    end

    # Pass every RSS document that the agent parses to a given block.
    def every_rss_doc(&block : XML::Node ->)
      docs = [] of XML::Node
      every_page { |page| docs << page.doc.not_nil! if page.rss? }
      docs.each { |doc| yield doc }
    end

    # Pass every Atom document that the agent parses to a given block.
    def every_atom_doc(&block : XML::Node ->)
      docs = [] of XML::Node
      every_page { |page| docs << page.doc.not_nil! if page.atom? }
      docs.each { |doc| yield doc }
    end

    # Pass every JavaScript page that the agent visits to a given block.
    def every_javascript_page(&block : Page ->)
      pages = [] of Page
      every_page { |page| (pages << page) if page.javascript? }
      pages.each { |page| yield page }
    end

    # Pass every CSS page that the agent visits to a given block.
    def every_css_page(&block : Page ->)
      pages = [] of Page
      every_page { |page| (pages << page) if page.css? }
      pages.each { |page| yield page }
    end

    # Pass every RSS feed that the agent visits to a given block.
    def every_rss_page(&block : Page ->)
      pages = [] of Page
      every_page { |page| (pages << page) if page.rss? }
      pages.each { |page| yield page }
    end

    # Pass every Atom feed that the agent visits to a given block.
    def every_atom_page(&block : Page ->)
      pages = [] of Page
      every_page { |page| (pages << page) if page.atom? }
      pages.each { |page| yield page }
    end

    # Pass every MS Word page that the agent visits to a given block.
    def every_ms_word_page(&block : Page ->)
      pages = [] of Page
      every_page { |page| (pages << page) if page.ms_word? }
      pages.each { |page| yield page }
    end

    # Pass every PDF page that the agent visits to a given block.
    def every_pdf_page(&block : Page ->)
      pages = [] of Page
      every_page { |page| (pages << page) if page.pdf? }
      pages.each { |page| yield page }
    end

    # Pass every ZIP page that the agent visits to a given block.
    def every_zip_page(&block : Page ->)
      pages = [] of Page
      every_page { |page| (pages << page) if page.zip? }
      pages.each { |page| yield page }
    end

    # Passes every image URI to the given blocks.
    def every_image(&block : Page ->)
      pages = [] of Page
      every_page { |page| (pages << page) if page.image? }
      pages.each { |page| yield page }
    end

    # Passes every origin and destination URI of each link to a given
    # block.
    def every_link(&block : URI, URI ->)
      @every_link_blocks << block
      self
    end
  end
end
