# Arachnid

Arachnid is a fast and powerful web scraping framework for Crystal. It provides an easy to use DSL for scraping webpages and processing all of the things you might come across.

- [Arachnid](#Arachnid)
  - [Installation](#Installation)
  - [The CLI](#The-CLI)
    - [Summarize](#Summarize)
    - [Sitemap](#Sitemap)
  - [Examples](#Examples)
  - [Usage](#Usage)
    - [Configuration](#Configuration)
    - [Crawling](#Crawling)
      - [`Arachnid#start_at(url, **options, &block : Agent ->)`](#Arachnidstartaturl-options-block--Agent)
      - [`Arachnid#site(url, **options, &block : Agent ->)`](#Arachnidsiteurl-options-block--Agent)
      - [`Arachnid#host(name, **options, &block : Agent ->)`](#Arachnidhostname-options-block--Agent)
    - [Crawling Rules](#Crawling-Rules)
    - [Events](#Events)
      - [`every_url(&block : URI ->)`](#everyurlblock--URI)
      - [`every_failed_url(&block : URI ->)`](#everyfailedurlblock--URI)
      - [`every_url_like(pattern, &block : URI ->)`](#everyurllikepattern-block--URI)
      - [`urls_like(pattern, &block : URI ->)`](#urlslikepattern-block--URI)
      - [`all_headers(&block : HTTP::Headers)`](#allheadersblock--HTTPHeaders)
      - [`every_resource(&block : Resource ->)`](#everyresourceblock--Resource)
      - [`every_ok_page(&block : Resource ->)`](#everyokpageblock--Resource)
      - [`every_redirect_page(&block : Resource ->)`](#everyredirectpageblock--Resource)
      - [`every_timedout_page(&block : Resource ->)`](#everytimedoutpageblock--Resource)
      - [`every_bad_request_page(&block : Resource ->)`](#everybadrequestpageblock--Resource)
      - [`def every_unauthorized_page(&block : Resource ->)`](#def-everyunauthorizedpageblock--Resource)
      - [`every_forbidden_page(&block : Resource ->)`](#everyforbiddenpageblock--Resource)
      - [`every_missing_page(&block : Resource ->)`](#everymissingpageblock--Resource)
      - [`every_internal_server_error_page(&block : Resource ->)`](#everyinternalservererrorpageblock--Resource)
      - [`every_txt_page(&block : Resource ->)`](#everytxtpageblock--Resource)
      - [`every_html_page(&block : Resource ->)`](#everyhtmlpageblock--Resource)
      - [`every_xml_page(&block : Resource ->)`](#everyxmlpageblock--Resource)
      - [`every_xsl_page(&block : Resource ->)`](#everyxslpageblock--Resource)
      - [`every_doc(&block : Document::HTML | XML::Node ->)`](#everydocblock--DocumentHTML--XMLNode)
      - [`every_html_doc(&block : Document::HTML | XML::Node ->)`](#everyhtmldocblock--DocumentHTML--XMLNode)
      - [`every_xml_doc(&block : XML::Node ->)`](#everyxmldocblock--XMLNode)
      - [`every_xsl_doc(&block : XML::Node ->)`](#everyxsldocblock--XMLNode)
      - [`every_rss_doc(&block : XML::Node ->)`](#everyrssdocblock--XMLNode)
      - [`every_atom_doc(&block : XML::Node ->)`](#everyatomdocblock--XMLNode)
      - [`every_javascript(&block : Resource ->)`](#everyjavascriptblock--Resource)
      - [`every_css(&block : Resource ->)`](#everycssblock--Resource)
      - [`every_rss(&block : Resource ->)`](#everyrssblock--Resource)
      - [`every_atom(&block : Resource ->)`](#everyatomblock--Resource)
      - [`every_ms_word(&block : Resource ->)`](#everymswordblock--Resource)
      - [`every_pdf(&block : Resource ->)`](#everypdfblock--Resource)
      - [`every_zip(&block : Resource ->)`](#everyzipblock--Resource)
      - [`every_image(&block : Resource ->)`](#everyimageblock--Resource)
      - [`every_content_type(content_type : String | Regex, &block : Resource ->)`](#everycontenttypecontenttype--String--Regex-block--Resource)
      - [`every_link(&block : URI, URI ->)`](#everylinkblock--URI-URI)
    - [Content Types](#Content-Types)
    - [Parsing HTML](#Parsing-HTML)
  - [Contributing](#Contributing)
  - [Contributors](#Contributors)

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     arachnid:
       github: watzon/arachnid
       version: ~> 0.1.0
   ```

2. Run `shards install`

To build the CLI

1. Run `shards build --release`

2. Add the `./bin` directory to your path or symlink `./bin/arachnid` with `sudo ln -s /home/path/to/arachnid /usr/local/bin`

## The CLI

Arachnid provides a CLI for basic scanning tasks, here is what you can do with it so far:

### Summarize

The `summarize` subcommand allows you to generate a report for a website. It can give you the number of pages, the internal and external links for every page, and a list of pages and their status codes (helpful for finding broken pages).

You can use it like this:

```
arachnid summarize https://crystal-lang.org --ilinks --elinks -c 404 503
```

This will generate a report for crystal-lang.org which will include every page and it's internal and external links, and a list of every page that returned a 404 or 503 status. For complete help use `arachnid summarize --help`

### Sitemap

Arachnid can also generate a XML or JSON sitemap for a website by scanning the entire site, following internal links. To do so just use the `arachnid sitemap` subcommand.

```
# XML sitemap
arachnid sitemap https://crystal-lang.org --xml

# JSON sitemap
arachnid sitemap https://crystal-lang.org --json

# Custom output file
arachnid sitemap https://crystal-lang.org --xml -o ~/Desktop/crystal-lang.org-sitemap.xml
```

Full help is available with `arachnid sitemap --help`

## Examples

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

## Usage

### Configuration

Arachnid has a ton of configration options which can be passed to the mehthods listed below in [Crawling](#crawling) and to the constructor for `Arachnid::Agent`. They are as follows:

- **read_timeout** - Read timeout
- **connect_timeout** - Connect timeout
- **max_redirects** - Maximum amount of redirects to follow
- **do_not_track** - Sets the DNT header
- **default_headers** - Default HTTP headers to use for all hosts
- **host_header** - HTTP host header to use
- **host_headers** - HTTP headers to use for specific hosts
- **user_agent** - sets the user agent for the crawler
- **referer** - Referer to use
- **fetch_delay** - Delay in between fetching resources
- **queue** - Preload the queue with urls
- **history** - Links that should not be visited
- **limit** - Maximum number of resources to visit
- **max_depth** - Maximum crawl depth

There are also a few class properties on `Arachnid` itself which are used as the defaults, unless overrided.

- **do_not_track**
- **max_redirects**
- **connect_timeout**
- **read_timeout**
- **user_agent**

### Crawling

Arachnid provides 3 interfaces to use for crawling:

#### `Arachnid#start_at(url, **options, &block : Agent ->)`

`start_at` is what you want to use if you're going to be doing a full crawl of multiple sites. It doesn't filter any urls by default and will scan every link it encounters.

#### `Arachnid#site(url, **options, &block : Agent ->)`

`site` constrains the crawl to a specific site. "site" in this case is defined as all paths within a domain and it's subdomains.

#### `Arachnid#host(name, **options, &block : Agent ->)`

`host` is similar to site, but stays within the domain, not crawling subdomains.

*Maybe `site` and `host` should be swapped? I don't know what is more intuitive.*

### Crawling Rules

Arachnid has the concept of **filters** for the purpose of filtering urls before visiting them. They are as follows:

- **hosts**
  - [visit_hosts_like(pattern : String | Regex)](https://watzon.github.io/arachnid/Arachnid/Agent.html#visit_hosts_like%28pattern%29-instance-method)
  - [ignore_hosts_like(pattern : String | Regex)](https://watzon.github.io/arachnid/Arachnid/Agent.html#ignore_hosts_like%28pattern%29-instance-method)
- **ports**
  - [visit_ports_like(pattern : String | Regex)](https://watzon.github.io/arachnid/Arachnid/Agent.html#visit_ports-instance-method)
  - [ignore_ports_like(pattern : String | Regex)](https://watzon.github.io/arachnid/Arachnid/Agent.html#ignore_ports-instance-method)
- **ports**
  - [visit_ports_like(pattern : String | Regex)](https://watzon.github.io/arachnid/Arachnid/Agent.html#visit_ports_like%28pattern%29-instance-method)
  - [ignore_ports_like(pattern : String | Regex)](https://watzon.github.io/arachnid/Arachnid/Agent.html#ignore_ports_like%28pattern%29-instance-method)
- **links**
  - [visit_links_like(pattern : String | Regex)](https://watzon.github.io/arachnid/Arachnid/Agent.html#visit_links_like(pattern)-instance-method)
  - [ignore_links_like(pattern : String | Regex)](https://watzon.github.io/arachnid/Arachnid/Agent.html#ignore_links_like(pattern)-instance-method)
- **urls**
  - [visit_urls_like(pattern : String | Regex)](https://watzon.github.io/arachnid/Arachnid/Agent.html#visit_urls_like%28pattern%29-instance-method)
  - [ignore_urls_like(pattern : String | Regex)](https://watzon.github.io/arachnid/Arachnid/Agent.html#ignore_urls_like%28pattern%29-instance-method)
- **exts**
  - [visit_exts_like(pattern : String | Regex)](https://watzon.github.io/arachnid/Arachnid/Agent.html#visit_exts_like%28pattern%29-instance-method)
  - [ignore_exts_like(pattern : String | Regex)](https://watzon.github.io/arachnid/Arachnid/Agent.html#ignore_exts_like%28pattern%29-instance-method)

All of these methods have the ability to also take a block instead of a pattern, where the block returns true or false. The only difference between `links` and `urls` in this case is with the block argument. `links` receives a `String` and `urls` a `URI`. Honestly I'll probably get rid of `links` soon and just make it `urls`.

`exts` looks at the extension, if it exists, and fiters base on that.

### Events

Every crawled "page" is referred to as a resource, since sometimes they will be html/xml, sometimes javascript or css, and sometimes images, videos, zip files, etc. Every time a resource is scanned one of several events is called. They are:

#### `every_url(&block : URI ->)`
Pass each URL from each resource visited to the given block.

#### `every_failed_url(&block : URI ->)`
Pass each URL that could not be requested to the given block.

#### `every_url_like(pattern, &block : URI ->)`
Pass every URL that the agent visits, and matches a given pattern, to a given block.

#### `urls_like(pattern, &block : URI ->)`
Same as `every_url_like`

#### `all_headers(&block : HTTP::Headers)`
Pass the headers from every response the agent receives to a given block.

#### `every_resource(&block : Resource ->)`
Pass every resource that the agent visits to a given block.

#### `every_ok_page(&block : Resource ->)`
Pass every OK resource that the agent visits to a given block.

#### `every_redirect_page(&block : Resource ->)`
Pass every Redirect resource that the agent visits to a given block.

#### `every_timedout_page(&block : Resource ->)`
Pass every Timeout resource that the agent visits to a given block.

#### `every_bad_request_page(&block : Resource ->)`
Pass every Bad Request resource that the agent visits to a given block.

#### `def every_unauthorized_page(&block : Resource ->)`
Pass every Unauthorized resource that the agent visits to a given block.

#### `every_forbidden_page(&block : Resource ->)`
Pass every Forbidden resource that the agent visits to a given block.

#### `every_missing_page(&block : Resource ->)`
Pass every Missing resource that the agent visits to a given block.

#### `every_internal_server_error_page(&block : Resource ->)`
Pass every Internal Server Error resource that the agent visits to a given block.

#### `every_txt_page(&block : Resource ->)`
Pass every Plain Text resource that the agent visits to a given block.

#### `every_html_page(&block : Resource ->)`
Pass every HTML resource that the agent visits to a given block.

#### `every_xml_page(&block : Resource ->)`
Pass every XML resource that the agent visits to a given block.

#### `every_xsl_page(&block : Resource ->)`
Pass every XML Stylesheet (XSL) resource that the agent visits to a given block.

#### `every_doc(&block : Document::HTML | XML::Node ->)`
Pass every HTML or XML document that the agent parses to a given block.

#### `every_html_doc(&block : Document::HTML | XML::Node ->)`
Pass every HTML document that the agent parses to a given block.

#### `every_xml_doc(&block : XML::Node ->)`
Pass every XML document that the agent parses to a given block.

#### `every_xsl_doc(&block : XML::Node ->)`
Pass every XML Stylesheet (XSL) that the agent parses to a given block.

#### `every_rss_doc(&block : XML::Node ->)`
Pass every RSS document that the agent parses to a given block.

#### `every_atom_doc(&block : XML::Node ->)`
Pass every Atom document that the agent parses to a given block.

#### `every_javascript(&block : Resource ->)`
Pass every JavaScript resource that the agent visits to a given block.

#### `every_css(&block : Resource ->)`
Pass every CSS resource that the agent visits to a given block.

#### `every_rss(&block : Resource ->)`
Pass every RSS feed that the agent visits to a given block.

#### `every_atom(&block : Resource ->)`
Pass every Atom feed that the agent visits to a given block.

#### `every_ms_word(&block : Resource ->)`
Pass every MS Word resource that the agent visits to a given block.

#### `every_pdf(&block : Resource ->)`
Pass every PDF resource that the agent visits to a given block.

#### `every_zip(&block : Resource ->)`
Pass every ZIP resource that the agent visits to a given block.

#### `every_image(&block : Resource ->)`
Passes every image resource to the given block.

#### `every_content_type(content_type : String | Regex, &block : Resource ->)`
Passes every resource with a matching content type to the given block.

#### `every_link(&block : URI, URI ->)`
Passes every origin and destination URI of each link to a given block.

### Content Types

Every resource has an associated content type and the `Resource` class itself provides several easy methods to check it. You can find all of them [here](https://watzon.github.io/arachnid/Arachnid/Resource/ContentTypes.html).

### Parsing HTML

Every HTML/XML resource has full access to the suite of methods provided by [Crystagiri](https://github.com/madeindjs/Crystagiri/) allowing you to more easily search by css selector.

## Contributing

1. Fork it (<https://github.com/watzon/arachnid/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Chris Watson](https://github.com/watzon) - creator and maintainer
