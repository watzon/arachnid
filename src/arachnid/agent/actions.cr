module Arachnid
  class Agent
    module Actions

      # A Runtime Error
      class RuntimeError < Exception; end

      # The base `Actions` exceptions class
      class Action < RuntimeError; end

      # Exception used to pause a running `Agent`
      class Paused < Action; end

      # Exception which causes a running `Agent` to skip a link.
      class SkipLink < Action; end

      # Exception which caises a running `Agent` to skip a resource.
      class SkipResource < Action; end
    end

    # Continue spidering
    def continue!
      @paused = false
      @queue.resume
    end

    # Sets the pause state of the agent.
    def pause=(state)
      @paused = state
    end

    # Pauses the agent, causing spidering to temporarily stop.
    def pause!
      @paused = true
      raise Actions::Paused.new
    end

    # Determines whether the agent is paused.
    def paused?
      @paused == true
    end

    # Causes the agent to skip the link being enqueued.
    def skip_link!
      raise Actions::SkipLink.new
    end

    # Causes the agent to skip the resource being visited.
    def skip_resource!
      raise Actions::SkipResource
    end
  end
end
