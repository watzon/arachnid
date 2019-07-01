require "./action"
require "termspinner"
require "json"

module Arachnid
  class Cli < Clim
    class Summarize < Cli::Action

      def run(opts, urls)
        spinner = Spinner::Spinner.new("Wait...")

        spider = Arachnid::Agent.new(limit: opts.limit, fibers: opts.fibers)

        urls.each do |url|
          spider.visit_urls_like(Regex.new(url))
        end

        opts.ignore.each do |pattern|
          pattern = Regex.new(pattern)
          spider.ignore_urls_like(pattern)
        end

        pages = 0
        internal_links = Hash(String, Array(String)).new
        external_links = Hash(String, Array(String)).new
        codes = Hash(Int32, Hash(String, Array(String))).new

        spinner.start("Crawling...")

        spider.every_resource do |page|
          pages += 1

          if opts.codes.includes?(page.code)
            referrer = page.headers["Referer"]? || "unknown"
            codes[page.code] ||= {} of String => Array(String)
            codes[page.code][referrer] ||= [] of String
            codes[page.code][referrer] << page.url.to_s
          end

          spinner.message = "Scanning #{page.url.to_s}"
        end

        spider.every_link do |orig, dest|
          if dest.to_s.includes?(orig.to_s) || dest.relative?
            internal_links[orig.to_s] ||= [] of String
            internal_links[orig.to_s] << dest.to_s
          else
            external_links[orig.to_s] ||= [] of String
            external_links[orig.to_s] << dest.to_s
          end
        end

        spider.start_at(urls[0])
        spinner.stop("Finished scanning!\n")

        generate_report(
          opts.output,
          pages,
          opts.ilinks ? internal_links : nil,
          opts.elinks ? external_links : nil,
          opts.codes.empty? ? nil : codes
        )
      end

      def generate_report(outfile, pages, internal_links, external_links, codes)
        report = {} of String => Hash(String, Array(String)) | Hash(Int32, Hash(String, Array(String))) | Int32

        report["pages"] = pages
        report["internal_links"] = internal_links if internal_links
        report["external_links"] = external_links if external_links
        report["codes"] = codes if codes

        if outfile
          File.write(File.expand_path(outfile.to_s, __DIR__), report.to_json, mode: "w+")
          puts "Report saved to #{outfile}"
        else
          pp report
        end
      end
    end
  end
end
