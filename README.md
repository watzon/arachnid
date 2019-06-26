# Arachnid

Arachnid is a fast and powerful web scraping framework for Crystal. It provides an easy to use DSL for scraping webpages and processing all of the things you might come across.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     arachnid:
       github: watzon/arachnid
   ```

2. Run `shards install`

## Usage

Arachnid provides an easy to use, powerful DSL for scraping websites.

```crystal
require "arachnid"
require "json"

# Let's build a sitemap of crystal-lang.org
# Links will be a hash of url to resource title
links = {} of String => String

# Visit a particular host, in this case `crystal-lang.org`. This will
# not match on subdomains.
Arachnid.host("https://crystal-lang.org") do |spider|
  # Ignore the API secion. It's a little big.
  spider.ignore_urls_like(/\/(api)\//)

  spider.every_html_page do |page|
    puts "Visiting #{page.url.to_s}"

    # Ignore redirects for our sitemap
    unless page.redirect?
      # Add the url of every visited page to our sitemap
      links[page.url.to_s] = page.title.to_s.strip
    end
  end
end

File.write("crystal-lang.org-sitemap.json", links.to_pretty_json)
```

Want to scan external links as well?

```crystal
# To make things interesting, this time let's download
# every image we find.
Arachnid.start_at("https://crystal-lang.org") do |spider|
  # Set a base path to store all the images at
  base_image_dir = File.expand_path("~/Pictures/arachnid")
  Dir.mkdir_p(base_image_dir)

  # You could also use `every_image`. This allows us to
  # track the crawler though.
  spider.every_resource do |resource|
    puts "Scanning #{resource.url.to_s}"

    if resource.image?
      # Since we're going to be saving a lot of images
      # let's spawn a new fiber for each one. This
      # makes things so much faster.
      spawn do
        # Output directory for images for this host
        directory = File.join(base_image_dir, resource.url.host.to_s)
        Dir.mkdir_p(directory)

        # The name of the image
        filename = File.basename(resource.url.path)

        # Save the image using the body of the resource
        puts "Saving #{filename} to #{directory}"
        File.write(File.join(directory, filename), resource.body)
      end
    end
  end
end
```

More documentation will be coming soon!

## Contributing

1. Fork it (<https://github.com/watzon/arachnid/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Chris Watson](https://github.com/watzon) - creator and maintainer
