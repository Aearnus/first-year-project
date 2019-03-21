#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'

DEFAULT_GAME = {
  title: "",
  checksum: "",
  controller: 0x4016
}

GAMES = {
  smb3: DEFAULT_GAME.dup.tap { |g|
    g[:title] = "Super Mario Bros. 3 (USA)"
    g[:checksum] = "base64:t2+XitMHbqZ/KwrKc5nJ6Q=="
    g[:controller] = 0x17
  }
}

def fm2_Header(game)
  # This is ONLY compatible with version 2.2.3 debug!
  %{version 3
emuVersion 22020
palFlag 0
fourscore 0
microphone 0
port0 1
port1 1
port2 0
romFilename #{game[:title]}
romChecksum #{game[:checksum]}
guid 41A335DD-7344-C740-95DE-1BAAA0107B85
comment author Converted by dumpToFM2.rb
comment author 2018 Tyler Limkemann}
end

def fm2_Line(r,l,d,u,t,s,b,a)
  q = ->(b) { b ? "T" : "." }
  "|0|#{[r,l,d,u,t,s,b,a].map{|_| q[_]}.join}|........||"
end

options = OpenStruct.new(
  game: nil,
  base_dump: nil,
  dump_diff: nil,
  out_fm2: nil,
)

if ARGV.length != 4
  puts "Usage: dumpToFM2.rb <game name> <base dump> <dump diff> <out FM2>"
  exit
elsif !GAMES.keys.include? ARGV[0].to_sym
  puts "Usage: dumpToFM2.rb <game name> <base dump> <dump diff> <out FM2>"
  puts "Unknown game identifier."
  puts "Valid game identifiers:"
  GAMES.keys.each do |game|
    puts "    #{game}: #{GAMES[game][:title]}"
  end 
else
  options.game = GAMES[ARGV[0].to_sym]
  options.base_dump = File.open ARGV[1], "rb"
  options.dump_diff = File.open ARGV[2], "r"
  options.out_fm2 = File.open ARGV[3], "wb"
end

options.out_fm2.puts(fm2_Header options.game)

dump_blob = options.base_dump.read.bytes
curr_frame = 0
curr_address = 0
curr_value = 0
#              r,l,d,u,t,s,b,a
controller1 = [0,0,0,0,0,0,0,0].map{|d| d == 1}

puts "Converting dump #{options.base_dump.to_path} to #{options.out_fm2.to_path}..."
# Account for the first frame in the dump, which gets skipped
options.out_fm2.puts(fm2_Line *controller1)
options.dump_diff.each_line do |d|
  if d =~ /(.+):(.+):(.+)/
    # before we update curr_frame, we write the last frame's controller data
    options.out_fm2.puts(fm2_Line *controller1)
    curr_frame = $~[1].to_i 16
    curr_address = $~[2].to_i 16
    curr_value = $~[3].to_i 16
  elsif d =~ /(.+):(.+)/
    curr_address = $~[1].to_i 16
    curr_value = $~[2].to_i 16
  elsif d =~ /(.+)/
    curr_value = $~[1].to_i 16
  else
    puts "Malformed line in frame #{curr_frame}: #{d}"
    exit
  end
  if curr_address == options.game[:controller] then
    controller1 = curr_value.chr.unpack("b*")[0].split("").map{|_| _ == "1"}
    #if curr_value != 0
    #  pp controller1
    #end
  end
end

options.out_fm2.close
