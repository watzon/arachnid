require "./arachnid/version"
require "./arachnid/resource"
require "./arachnid/agent"

require "strange"
require "strange/formatter/color_formatter"

module Arachnid
  extend self

  @@logger : Strange?

  # Specifies whether robots.txt should be honored globally
  class_property? robots : Bool = false

  # Maximum amount of redirects to follow
  class_property max_redirects : Int32 = 5

  # Connect timeout.
  class_property connect_timeout : Int32 = 10

  # Read timeout.
  class_property read_timeout : Int32 = 10

  # The User-Agent string used by all Agent objects by default.
  class_property user_agent : String = "Arachnid #{Arachnid::VERSION}"

  # Logger for Arachnid
  def self.logger
    @@logger ||= Strange.new(
      level: Strange::DEBUG,
      transports: [
        Strange::ConsoleTransport.new(
          formatter: ArachnidFormatter.new
        ).as(Strange::Transport)
      ]
    )
  end

  # See `Agent.start_at`
  def start_at(url, **options, &block : Agent ->)
    Agent.start_at(url, **options, &block)
  end

  # See `Agent.host`
  def host(name, **options, &block : Agent ->)
    Agent.host(name, **options, &block)
  end

  # See `Agent.site`
  def site(url, **options, &block : Agent ->)
    Agent.site(url, **options, &block)
  end

  class ArachnidFormatter < Strange::ColorFormatter
    def format(text : String, level : Strange::Level)
      message = "#{"%-7.7s" % level.to_s} #{text}"
      color_message(message, level)
    end
  end
end

require "json"

# Let's build a sitemap of crystal-lang.org
# Links will be a hash of url to resource title
links = {} of String => String

marionette = Marionette.launch(headless: false, extended: true)

# Visit a particular host, in this case `crystal-lang.org`. This will
# not match on subdomains.
Arachnid.host("https://www.neuralegion.com", browser: marionette) do |spider|
  spider.every_html_page do |page|
    puts "Visiting #{page.url.to_s}"

    # Ignore redirects for our sitemap
    unless page.redirect?
      # Add the url of every visited page to our sitemap
      links[page.url.to_s] = page.title.to_s.strip
    end
  end
end

File.write("neuralegion-sitemap.json", links.to_pretty_json)
