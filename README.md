# Arachnid

Arachnid is a fast, soon to be multi-threading capable web crawler for Crystal. It recenty underwent a full rewrite for Crystal 0.35.1, so see the documentation below for updated usage instructions.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     arachnid:
       github: watzon/arachnid
   ```

2. Run `shards install`

## Usage

First, of course, you need to require arachnid in your project:

```crystal
require "arachnid"
```

### The Agent

`Agent` is the class that does all the heavy lifting and will be the main one you interact with. To create a new `Agent`, use `Agent.new`.

```crystal
agent = Arachnid::Agent.new
```

The initialize method takes a bunch of optional parameters:

#### `:client`

You can, if you wish, supply your own `HTTP::Client` instance to the `Agent`. This can be useful if you want to use a proxy, provided the proxy client extends `HTTP::Client`.

#### `:user_agent`

The user agent to be added to every request header. You can override this on a per-host basis with either `:host_headers` or `:default_headers`.

#### `:default_headers`

The default headers to be used in every request.

#### `:host_headers`

Headers to be applied on a per-host basis. This is a hash `String (host name) => HTTP::Headers`.

#### `:queue`

The `Arachnid::Queue` instance to use for storing links waiting to be processed. The default is a `MemoryQueue` (which is the only one for now), but you can easily implement your own `Queue` using whatever you want as a backend.

#### `:stop_on_empty`

Whether or not to stop running when the queue is empty. This is true by default. If it's made false, the loop will continue when the queue empties, so be sure you have a way to keep adding items to the queue.

#### `:follow_redirects`

Whether or not to follow redirects (add them to the queue).

### Starting the Agent

There are four ways to start your Agent once it's been created. Here are some examples:

#### `#start_at`

`#start_at` starts the Agent running on a particular URL. It adds a single URL to the queue and starts there.

```crystal
agent.start_at("https://crystal-lang.org") do
  # ...
end
```

#### `#site`

`#site` starts the agent running at the given URL and adds a rule that keeps the agent restricted to the given site. This allows the agent to scan the given domain and any subdomains. For instance:

```crystal
agent.site("https://crystal-lang.org") do
  # ...
end
```

The above will match `crystal-lang.org` and `forum.crystal-lang.org`, but not `github.com/crystal-lang` or any other site not within the `*.crystal-lang.org` space.

#### `#host`

`#host` is like site, but with the added restriction of just remaining on the current domain path. Subdomains are not included.

```crystal
agent.host("crystal-lang.org") do
  # ...
end
```

#### `#start`

Provided you already have URIs in the queue ready to be scanned, you can also just use `#start` to start the Agent running.

```crystal
agent.enqueue("https://crystal-lang.org")
agent.enqueue("https://kemalcr.com")
agent.start
```

### Filters

URI's can be filtered before being enqueued. There are two kinds of filters, accept and reject. Accept filters can be used to ensure that a URI matches before being enqueued. Reject filters do the opposite, keeping URIs from being enqueued if they _do_ match.

For instance:

```crystal
# This will filter out all sites where the host is not "crystal-lang.org"
agent.accept_filter { |uri| uri.host == "crystal-lang.org" }
```

If you want to ignore certain parts of the above filter:

```crystal
# This will ignore paths starting with "/api"
agent.reject_filter { |uri| uri.path.to_s.starts_with?("/api") }
```

The `#site` and `#host` methods add a default accept filter in order to keep things in the given site or host.

### Resources

All the above is useless if you can't do anything with the scanned resources, which is why we have the `Resource` class. Every scanned resource is converted into a `Resource` (or subclass) based on the content type. For instance, `text/html` becomes a `Resource::HTML` which is parsed using [kostya/myhtml](https://github.com/kostya/myhtml) for extra speed.

Each resource has an associated `Agent#on_` method so you can do something when one of those resources is scanned:

```crystal
agent.on_html do |page|
  puts typeof(page)
  # => Arachnid::Resource::HTML

  puts page.title
  # => The Title of the Page
end
```

Currently we have:

- `#on_html`
- `#on_image`
- `#on_script`
- `#on_stylesheet`
- `#on_xml`

There is also `#on_resource` which is called for every resource, including ones that don't match the above types. Resources all include, at minimum the URI at which the resource was found, and the response (`HTTP::Client::Response`) instance.

## Contributing

1. Fork it (<https://github.com/watzon/arachnid/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [your-name-here](https://github.com/watzon) - creator and maintainer
