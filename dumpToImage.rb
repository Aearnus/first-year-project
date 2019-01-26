require 'oily_png'

if ARGV.length < 1
  puts "usage: ruby dumpToImage.rb <blob files>"
  exit 0
end

ARGV.each do |blob_filename|
  puts "Converting #{blob_filename}..."
  blob = File.read(blob_filename)
  image_dim = (Math.sqrt blob.bytes.length).ceil
  puts "  Blob length: #{blob.length}"
  puts "  Size: #{image_dim}x#{image_dim}"
  image = ChunkyPNG::Image.new(image_dim, image_dim, ChunkyPNG::Color::BLACK)
  blob.each_byte.with_index do |b, index|
    image[index % image_dim, index.div(image_dim)] = ChunkyPNG::Color.grayscale(b)
  end
  image.save(File.basename(blob_filename, ".*") + ".png")
end

