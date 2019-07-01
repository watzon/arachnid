require "./action"
require "termspinner"
require "mime"

module Arachnid
  class Cli < Clim
    class ImageDownloader < Cli::Action

      def run(opts, args)
        url = URI.parse(args[0])
        spinner = Spinner::Spinner.new("Wait...")

        count = 0
        outdir = File.expand_path(opts.outdir, __DIR__)

        spider = Arachnid::Agent.new(limit: opts.limit, fibers: opts.fibers)
        spider.visit_urls_like(Regex.new(url.to_s))

        opts.ignore.each do |pattern|
          pattern = Regex.new(pattern)
          spider.ignore_urls_like(pattern)
        end

        spider.every_image do |res|
          next if opts.minsize && res.body.bytesize < opts.minsize.not_nil!
          next if opts.maxsize && res.body.bytesize > opts.maxsize.not_nil!
          # name = opts.format ? format_filename(opts.format, res.url.path) || res.url.path
          name = format_filename(nil, res, count)
          outfile = File.join(outdir, name)

          count += 1
          spinner.message = "Saved #{outfile}"
          File.write(outfile, res.body.to_slice, mode: "a")
        end

        # Create the target directory
        Dir.mkdir_p(outdir)

        spinner.start("Crawling...")
        spider.start_at(url)
        spinner.stop("Finished! #{count} images saved to #{outdir}\n")
      end

      def format_filename(format, res, index)
        filename = res.url.path
        ext = File.extname(filename)
        basename = File.basename(filename, ext)

        # If the ext is empty create one from the MIME type
        if ext.empty?
          extensions = MIME.extensions(res.content_type)
          ext = extensions.first? || ".unknown"
        end

        filename = basename + ext
      end
    end
  end
end
