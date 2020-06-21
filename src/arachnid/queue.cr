module Arachnid
  # Abstract base class for URL queues. Within Arachnid itself `Queue` implementations
  # strive to be thread safe, and custom implementations should as well.
  abstract class Queue
    # Add a new URL to the queue.
    abstract def enqueue(uri : URI)

    # Remove a URL from the queue.
    abstract def dequeue : URI

    # Check if the queue is empty.
    abstract def empty? : Bool

    # Check if a URL has been enqueued.
    abstract def includes?(uri : URI) : Bool

    # Clear the queue, removing all items.
    abstract def clear
  end
end

require "./queue/*"
