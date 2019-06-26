require "./resource"
require "./agent"

module Arachnid
  extend self

  # Specifies whether robots.txt should be honored globally
  class_property? robots : Bool = false

  # Should we set the DNT (Do Not Track) header?
  class_property? do_not_track : Bool = false

  # Maximum amount of redirects to follow
  class_property max_redirects : Int32 = 5

  # Connect timeout.
  class_property connect_timeout : Int32 = 10

  # Read timeout.
  class_property read_timeout : Int32 = 10

  # The User-Agent string used by all Agent objects by default.
  class_property user_agent : String = "Arachnid #{Arachnid::VERSION}"

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
end
