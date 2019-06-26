require "./arachnid/version"
require "./arachnid/arachnid"

# To make things interesting, this time let's download
# every image we find.
Arachnid.start_at("https://crystal-lang.org") do |spider|
  # Set a base path to store all the images at
  base_image_dir = File.expand_path("~/Pictures/arachnid")
  Dir.mkdir_p(base_image_dir)

  spider.every_page do |page|
    puts "Scanning #{page.url.to_s}"

    if page.image?
      # Since we're going to be saving a lot of images
      # let's spawn a new fiber for each one. This
      # makes things so much faster.
      spawn do
        # Output directory for images for this host
        directory = File.join(base_image_dir, page.url.host.to_s)
        Dir.mkdir_p(directory)

        # The name of the image
        filename = File.basename(page.url.path)

        # Save the image using the body of the page
        puts "Saving #{filename} to #{directory}"
        File.write(File.join(directory, filename), page.body)
      end
    end
  end
end
