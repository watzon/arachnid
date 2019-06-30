require "./action"
require "../arachnid"
require "termspinner"
require "json"

module Arachnid
  class Cli < Clim
    class Count < Cli::Action

      def run(opts, urls)
        spinner = Spinner::Spinner.new("Wait...")

        spider = Arachnid::Agent.new(limit: opts.limit)

        urls.each do |url|
          spider.visit_urls_like(Regex.new(url))
        end

        pages = 0
        internal_links = Hash(String, Array(String)).new
        external_links = Hash(String, Array(String)).new
        codes = Hash(Int32, Array(String)).new

        spinner.start("Crawling...")

        spider.every_resource do |page|
          pages += 1

          if opts.codes.includes?(page.code)
            codes[page.code] ||= [] of String
            codes[page.code] << page.url.to_s
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
        report = {} of String => Hash(String, Array(String)) | Hash(Int32, Array(String)) | Int32

        report["pages"] = pages
        report["internal_links"] = internal_links if internal_links
        report["external_links"] = external_links if external_links
        report["codes"] = codes if codes

        File.write(outfile, report.to_json, mode: "w+")
        puts "Report saved to #{outfile}"
      end
    end
  end
end
