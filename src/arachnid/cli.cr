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
        usage "arachnid summarize [sites] [options] ..."

        option "-l", "--ilinks",              type: Bool,         desc: "generate a map of pages to internal links"
        option "-L", "--elinks",              type: Bool,         desc: "generate a map of pages to external links"
        option "-c CODES", "--codes=CODES",   type: Array(Int32), desc: "generate a map of status codes to pages \
                                                                          that responded with that code"
        option "-n", "--limit NUM",           type: Int32,        desc: "maximum number of pages to scan"
        option "-o FILE", "--output=FILE",    type: String,       desc: "file to write the report to", default: "arachnid.json"

        run do |opts, args|
          count = Arachnid::Cli::Count.new
          if args.empty?
            STDERR.puts "At least one site is required"
          else
            count.run(opts, args)
          end
        end
      end
    end
  end
end

Arachnid::Cli.start(ARGV)
