require "clim"
require "./version"
require "./cli/**"

module Arachnid
  class Cli < Clim
    main do
      desc "Arachnid CLI - Simple utilities for scanning the web."
      usage "arachnid [options] [subcommand] [arguments] ..."
      version Arachnid::VERSION

      run do |opts, args|
        puts opts.help_string # => help string.
      end

      sub "summarize" do
        desc "Scan a site (or sites) and generate a JSON report"
        usage <<-USAGE
        arachnid summarize [sites] [options]

          Examples:

            # Scan a site and count the number of pages, outputting the result to STDOUT
            arachnid summarize https://crystal-lang.org

            # Scan a site and count the number of internal links, outputting the result to STDOUT
            arachnid summarize https://crystal-lang.org -l

            # Scan a site and count the number of internal and external links, saving the result to a file
            arachnid summarize https://crystal-lang.org -l -L -o report.json

            # Scan a site and list all pages that returned a 404 or 500 status code
            arachnid summarize https://crystal-lang.org -c 404 500
        USAGE

        option "-l", "--ilinks",              type: Bool,         desc: "generate a map of pages to internal links"
        option "-L", "--elinks",              type: Bool,         desc: "generate a map of pages to external links"
        option "-c CODES", "--codes=CODES",   type: Array(Int32), desc: "generate a map of status codes to pages \
                                                                          that responded with that code"
        option "-n", "--limit NUM",           type: Int32,        desc: "maximum number of pages to scan"
        option "-f", "--fibers NUM",          type: Int32,        desc: "maximum amount of fibers to spin up", default: 10
        option "-o FILE", "--output=FILE",    type: String,       desc: "file to write the report to (if undefined \
                                                                          output will be printed to STDOUT"

        run do |opts, args|
          if args.empty?
            STDERR.puts "At least one site is required"
          else
            summarize = Arachnid::Cli::Summarize.new
            summarize.run(opts, args)
          end
        end
      end

      sub "sitemap" do
        desc "generate a sitemap for a site in XML or JSON format"
        usage <<-USAGE
        arachnid sitemap [url] [--xml | --json] [options]

          Examples:

            # Generate a XML sitemap for crystal-lang.org
            arachnid sitemap https://crystal-lang.org --xml

            # Generate a XML sitemap with a custom filename
            arachnid sitemap https://crystal-lang.org --xml -o ~/Desktop/crystal-lang.org.xml

            # Generate a JSON sitemap instead (not really useful as an actual sitemap)
            arachnid sitemap https://crystal-lang.org --json
        USAGE


        option "--xml",                     type: Bool, desc: "generate the sitemap in XML format"
        option "--json",                    type: Bool, desc: "generate the sitemap in JSON format"
        option "-o FILE", "--output=FILE",  type: String, desc: "filename to write the report to. \
                                                                default is the hostname + .json or .xml"
        option "-f", "--fibers NUM",          type: Int32,        desc: "maximum amount of fibers to spin up", default: 10

        run do |opts, args|
          if args.size != 1
            raise "arachnid sitemap requires exactly one site to scan. you provided #{args.size}"
          elsif !opts.json && !opts.xml
            raise "you must select either xml or json"
          else
            sitemap = Arachnid::Cli::Sitemap.new
            sitemap.run(opts, args)
          end
        end
      end
    end
  end
end

Arachnid::Cli.start(ARGV)
