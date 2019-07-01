require "./action"
require "../arachnid"
require "termspinner"
require "json"

module Arachnid
  class Cli < Clim
    class Sitemap < Cli::Action

      alias LastMod = NamedTuple(year: String, month: String, day: String)
      alias PageMap = NamedTuple(url: String, page: String, changefreq: String, priority: String, lastmod: LastMod)

      def run(opts, args)
        url = URI.parse(args[0])
        date = Time.now
        spinner = Spinner::Spinner.new("Wait...")

        spider = Arachnid::Agent.new(fibers: opts.fibers)
        spider.visit_urls_like(Regex.new(Regex.escape(url.to_s)))

        map = {
          domain: url.to_s,
          lastmod: {
            year: date.year.to_s, month: date.month.to_s, day: date.day.to_s
          },
          filetype: "html",

          pages: [] of PageMap
        }

        spinner.start("Crawling...")

        spider.every_html_page do |page|
          spinner.message = "Crawling... Current page #{page.url.to_s}"
          last_mod = page.headers["Last-Modified"]?
          last_mod = last_mod ? Time.parse_utc(last_mod, "%a, %d %b %Y %H:%M:%S GMT") : Time.now

          item = {
            url: page.url.to_s,
            page: page.title.to_s,
            changefreq: "never",
            priority: "0.5",
            lastmod: {
              year: last_mod.year.to_s,
              month: last_mod.month.to_s.rjust(2, '0'),
              day: last_mod.day.to_s.rjust(2, '0')
            }
          }

          map[:pages] << item
        end

        spider.start_at(url)
        spinner.stop("Finished scanning!\n")

        if opts.xml
          filename = (opts.output ? opts.output.to_s : url.hostname.to_s + ".xml")
          sitemap = gen_xml_sitemap(map)
        else
          filename = (opts.output ? opts.output.to_s : url.hostname.to_s + ".json")
          sitemap = gen_json_sitemap(map)
        end

        File.write(File.expand_path(filename, __DIR__), sitemap.to_s, mode: "w+")
        puts "Wrote sitemap to #{filename}"
      end

      def gen_xml_sitemap(map)
        XML.build(indent: "    ", encoding: "UTF-8") do |xml|
          xml.element("urlset", xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
            map[:pages].each do |page|
              xml.element("url") do
                lastmod = page[:lastmod]

                xml.element("loc") { xml.text page[:url] }
                xml.element("lastmod") { xml.text "#{lastmod[:year]}-#{lastmod[:month]}-#{lastmod[:day]}" }
                xml.element("changefreq") { xml.text page[:changefreq] }
                xml.element("priority") { xml.text page[:priority] }
              end
            end
          end
        end
      end

      def gen_json_sitemap(map)
        map.to_pretty_json
      end
    end
  end
end
