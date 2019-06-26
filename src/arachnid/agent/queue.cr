require "uri"
require "./actions"
require "benchmark"

module Arachnid
  class Agent
    class Queue

      @queue : Array(URI)

      @pool_size : Int32

      @exceptions : Array(Exception)

      property mutex : Mutex

      def self.new(array = nil, pool_size = nil)
        array     ||= [] of URI
        pool_size ||= 10
        new(array, pool_size, nil)
      end

      private def initialize(@queue : Array(URI), @pool_size : Int32, dummy)
        @mutex = Mutex.new
        @exceptions = [] of Exception
      end

      def enqueue(item)
        @queue << item
      end

      def clear
        @queue.clear
      end

      def queued?(url)
        @queue.includes?(url)
      end

      private def worker(item : URI, &block : URI ->)
        signal_channel = Channel::Unbuffered(Actions::Action).new

        spawn do
          begin
            block.call(item)
          rescue ex
            signal_channel.send(Actions::SkipLink.new)
          else
            signal_channel.send(Actions::Action.new)
          end
        end

        signal_channel.receive_select_action
      end

      def run(&block : URI ->)
        pool_counter = 0
        worker_channels = [] of Channel::ReceiveAction(Channel::Unbuffered(Actions::Action))
        queue = @queue.each
        more_pools = true

        loop do
          break if !more_pools && worker_channels.empty?

          while pool_counter < @pool_size && more_pools
            item = queue.next

            if item.is_a?(Iterator::Stop::INSTANCE)
              more_pools = false
              break
            end

            pool_counter += 1
            worker_channels << worker(item.as(URI), &block)
          end

          index, signal_exception = Channel.select(worker_channels)
          worker_channels.delete_at(index)
          pool_counter -= 1

          @exceptions << signal_exception if signal_exception && signal_exception.is_a?(Actions::SkipLink)
        end
      end
    end
  end
end
