module Arachnid
  abstract class Queue
    # A basic, thread safe, queue implementation that stores all URLs in memory.
    class Memory < Queue
      @queue : Deque(URI)
      @history : Set(String)
      @mutex : Mutex

      def initialize(queue = Deque(URI).new)
        @queue = queue.is_a?(Deque) ? queue : Deque.new(queue.to_a)
        @history = Set(String).new
        @mutex = Mutex.new
      end

      def enqueue(uri : URI)
        @mutex.synchronize do
          @history << "#{uri.host}#{uri.path}"
          @queue << uri
        end
      end

      def dequeue : URI
        @mutex.synchronize do
          @queue.shift
        end
      end

      def empty? : Bool
        @mutex.synchronize do
          @queue.empty?
        end
      end

      def includes?(uri : URI) : Bool
        @mutex.synchronize do
          @history.includes?("#{uri.host}#{uri.path}")
        end
      end

      def clear
        @mutex.synchronize do
          @queue.clear
          @history.clear
        end
      end
    end
  end
end
