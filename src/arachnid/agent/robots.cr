module Arachnid
  class Agent
    # @robots : Arachnid::Robots? = nil

    # Initializes the robots filter.
    def initialize_robots
      # @robots = Arachnid::Robots.new(@user_agent)
    end

    # Determines whether a URL is allowed by the robot policy.
    # def robot_allowed?(url)
    #   if robots = @robots
    #     return robots.allowed?(url)
    #   end
    #   true
    # end
  end
end
