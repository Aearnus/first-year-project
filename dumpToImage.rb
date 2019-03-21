#!/usr/bin/env ruby

require 'oily_png'

if ARGV.length < 1
  puts "usage: ruby dumpToImage.rb <blob files>"
  exit 0
end

def prune_and_format_chunks(blob)
  # if any 256kb chunks are entirely 0, prune them
  # this removed unused portions of the heap and stack
  out = []
  chunks = blob.bytes.each_slice(1024*256).to_a
  chunks.each do |chunk|
    if chunk.sum != 0
      out += chunk
    else
      out << -1
    end
  end
  return out
end

ARGV.each do |blob_filename|
  puts "Converting #{blob_filename}..."
  blob = File.read(blob_filename)
  # DON'T PRUNE THE NES IMAGES
  #pruned = prune_and_format_chunks(blob)
  pruned = blob.bytes
  image_dim = (Math.sqrt pruned.length).ceil
  #puts "  Blob length: #{blob.length}"
  #puts "  Pruned blob length: #{pruned.length}"
  puts "  Size: #{image_dim}x#{image_dim}"
  image = ChunkyPNG::Image.new(image_dim, image_dim, ChunkyPNG::Color::BLACK)
  pruned.each.with_index do |b, index|
    if b != -1
      image[index % image_dim, index.div(image_dim)] = ChunkyPNG::Color.grayscale(b)
    else
      image[index % image_dim, index.div(image_dim)] = ChunkyPNG::Color.rgb(255,0,0)
    end
  end
  image.save(File.basename(blob_filename, ".*") + File.extname(blob_filename) + ".png")
end

