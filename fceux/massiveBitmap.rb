#!/usr/bin/env ruby

require 'rounding'

# Number to Bytes
def n2b(num, len)
  out = []
  while num > 0
    num, rem = num.divmod(256)
    out << rem
  end
  out.length.upto len-1 do
    out << 0
  end
  if out.length != len
    puts "improper"
    exit
  end
  out
end

def bmp_Header(width, height)
  [
  # BMP HEADER
    [0x42, 0x4d], # "BM"
    n2b(56 + (width*height*3).ceil_to(8), 4), # Length of BMP file
    [0, 0, 0, 0], # Application specific
    n2b(55, 4), # Pixel array offset
  # DIP HEADER
    n2b(40, 4), # Length of DIP header
    n2b(width, 4),
    n2b(height, 4),
    n2b(1, 2), # One color plane
    n2b(24, 2), # 24 bits per pixel
    [0, 0, 0, 0], # No pixel array compression, raw RGB
    #n2b((width*height*3).ceil_to(8), 4), # Size of raw bitmap data
    n2b(0, 4), # Size of raw bitmap data
    #n2b(118110, 4), # 3000 DPI horizontally
    #n2b(118110, 4), # 3000 DPI vertically
    n2b(0, 4), # 3000 DPI horizontally
    n2b(0, 4), # 3000 DPI vertically
    [0, 0, 0, 0], # No color palette
    [0, 0, 0, 0] # No important colors in color palette
  ].flatten
end
    

if ARGV.length == 0
  puts "Usage: ./massiveBitmap.rb <dump files>"
  exit
end

image_width = 65537
image_height = ARGV.length

File.open("out.bmp", "wb") do |img|
  img.write(bmp_Header(image_width, image_height).pack("C*"))
  ARGV.each do |dump_name|
    dump = File.read(dump_name)
    img.write(0)
    dump.bytes.each.with_index do |b, i|
      bmp_tribbles = [b, b, b]
      img.write(bmp_tribbles.pack("C*"))
      if i == image_width - 2
        img.write([0,0,0].pack("C*"))
        puts "padding"
      end
    end
  end
end
