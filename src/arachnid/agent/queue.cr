module Arachnid
  class Agent
    # An asynchronous data queue using a pool of
    # `Concurrent::Future` to allow for async
    # fetching of multiple pages at once.
    class Queue(T)

      @queue : Array(T)

      @max_pool_size : Int32

      @pool : Array(Concurrent::Future(Nil))

      @paused : Bool

      @block : Proc(T, Void)?

      delegate :clear, :empty?, to: @queue

      # Create a new Queue
      def initialize(queue : Array(T)? = nil, max_pool_size : Int32? = nil)
        @queue = queue || [] of T
        @max_pool_size = max_pool_size || 10
        @pool = [] of Concurrent::Future(Nil)
        @paused = false
        @block = nil
      end

      # Add an item to the queue
      def enqueue(item)
        @queue << item
      end

      private def dequeue
        @queue.shift
      end

      # See if an item is currently queued
      def queued?(url)
        @queue.includes?(url)
      end

      def pause!
        @paused = true
      end

      def paused?
        @paused
      end

      def resume!
        @paused = false
        run(@block)
      end

      # Run the queue, calling `block` for every item.
      # Returns when the queue is empty.
      def run(&block : T ->)
        # Keep a reference to the block so we can resume
        # after pausing.
        @block = block
        @paused = false

        loop do
          fut = future { block.call(dequeue) }

          if @pool.size < @max_pool_size
            @pool << fut
          else
            @pool.shift.get
          end

          break if @paused
          if @queue.empty?
            sleep(1)
            break if @queue.empty?
          end
        end
      end
    end
  end
end
