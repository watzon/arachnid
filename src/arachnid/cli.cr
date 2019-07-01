require "clim"
require "../arachnid"
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
        desc "scan a site (or sites) and generate a JSON report"
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

        option "-l", "--ilinks",              type: Bool,           desc: "generate a map of pages to internal links"
        option "-L", "--elinks",              type: Bool,           desc: "generate a map of pages to external links"
        option "-c CODES", "--codes=CODES",   type: Array(Int32),   desc: "generate a map of status codes to pages \
                                                                            that responded with that code"
        option "-n", "--limit NUM",           type: Int32,          desc: "maximum number of pages to scan"
        option "-f", "--fibers NUM",          type: Int32,          desc: "maximum amount of fibers to spin up", default: 10
        option "-i", "--ignore PATTERNS",     type: Array(String),  desc: "url patterns to ignore (regex)"
        option "-o FILE", "--output=FILE",    type: String,         desc: "file to write the report to (if undefined \
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


        option "--xml",                     type: Bool,           desc: "generate the sitemap in XML format"
        option "--json",                    type: Bool,           desc: "generate the sitemap in JSON format"
        option "-o FILE", "--output=FILE",  type: String,         desc: "filename to write the report to. \
                                                                          default is the hostname + .json or .xml"
        option "-f", "--fibers NUM",        type: Int32,          desc: "maximum amount of fibers to spin up", default: 10
        option "-i", "--ignore PATTERNS",   type: Array(String),  desc: "url patterns to ignore (regex)"

        run do |opts, args|
          if args.size != 1
            raise "arachnid sitemap requires exactly one site to scan. you provided #{args.size}."
          elsif !opts.json && !opts.xml
            raise "you must select either xml or json"
          else
            sitemap = Arachnid::Cli::Sitemap.new
            sitemap.run(opts, args)
          end
        end
      end

      sub "imgd" do
        desc "scan a site and download all the images found"
        usage <<-USAGE
        arachnid imgd [url] [options]

          Examples:

            # Download all images from crystal-lang.org and save them to ./images
            arachnid imgd https://crystal-lang.org -o ./images

            # Download all images between 5000 and 10000 bytes
            arachnid imgd https://crystal-lang.org -m5000 -x10000
        USAGE

        option "-n", "--limit NUM",         type: Int32,          desc: "maximum number of pages to scan"
        option "-f", "--fibers NUM",        type: Int32,          desc: "maximum amount of fibers to spin up", default: 10
        option "-i", "--ignore PATTERNS",   type: Array(String),  desc: "url patterns to ignore (regex)"
        option "-o DIR", "--outdir=DIR",    type: String,         desc: "directory to save images to",         default: "./imgd-downloads"
        option "-m NUM", "--minsize=NUM",   type: Int32,          desc: "image minimum size (in bytes)"
        option "-x NUM", "--maxsize=NUM",   type: Int32,          desc: "image maximum size (in bytes)"

        run do |opts, args|
          if args.size != 1
            raise "arachnid imgd requires exactly one site to scan. you provided #{args.size}."
          else
            img = Arachnid::Cli::ImageDownloader.new
            img.run(opts, args)
          end
        end
      end

      help_template do |desc, usage, options, sub_commands|
        longest_option = options.reduce(0) do |acc, opt|
          option = opt[:names].join(", ")
          option.size > acc ? option.size : acc
        end

        options_help_lines = options.map do |option|
          option[:names].join(", ").ljust(longest_option + 5) + " - #{option[:desc]}" + ( option[:default] ? " (default: #{option[:default]})" : "" )
        end

        base = <<-BASE_HELP
          #{usage}

          #{desc}

          options:
            #{options_help_lines.join("\n    ")}

        BASE_HELP

        sub = <<-SUB_COMMAND_HELP

          sub commands:
            #{sub_commands.map { |command| command[:help_line].strip }.join("\n    ") }
        SUB_COMMAND_HELP

        sub_commands.empty? ? base : base + sub
      end
    end
  end
end

Arachnid::Cli.start(ARGV)
