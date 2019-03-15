#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'

options = OpenStruct.new(
  base_dump: nil,
  dump_diff: nil,
  out_dump_name: nil,
  timestep: 0,
  info: false
)

optionparser = OptionParser.new do |opts|
  opts.banner = "Usage: relativizer.rb [options] <base dump> <dump diff> <out dump>"

  opts.on("-t", "--timestep FRAMES", Integer,
          "Step the dump FRAMES frames into the future.") do |frames|
    options.timestep = frames
  end

  opts.on("-i", "--info",
          "Print out information about the dump.") do |i|
    options.info = true
  end
end
optionparser.parse!

if ARGV.length != 3
  puts optionparser.banner
  exit
else
  options.base_dump = File.open ARGV[0], "rb"
  options.dump_diff = File.open ARGV[1], "r"
  options.out_dump_name = ARGV[2]
end

if options.info
  diff_len = 0
  diff_framecount = 0
  options.dump_diff.each_line do |d|
    diff_len += 1
    if d =~ /.+(?=:.+:.+)/
      diff_framecount = $~[0].to_i 16
    end
  end
  options.dump_diff.seek(0, IO::SEEK_SET)

  puts "Info about dump file #{options.base_dump.to_path}:"
  puts "    Size: " + ("%.2fKB" % (options.base_dump.size.to_f / 1024))
  puts "Info about dump diff file #{options.dump_diff.to_path}:"
  puts "    Number of entries: #{diff_len}"
  puts "    Final frame: #{diff_framecount}"
  puts "    Time recorded: #{(diff_framecount / 60 / 60).floor}min#{((diff_framecount / 60.0) % 60).truncate 2}sec"
end

if options.timestep != 0
  puts "Advancing dump #{options.base_dump.to_path} by #{options.timestep} frames..."
  dump_blob = options.base_dump.read.bytes
  curr_frame = 0
  curr_address = 0
  options.dump_diff.each_line do |d|
    if d =~ /(.+):(.+):(.+)/
      curr_frame = $~[1].to_i 16
      break if curr_frame > options.timestep 
      curr_address = $~[2].to_i 16
      dump_blob[curr_address] = $~[3].to_i 16
    elsif d =~ /(.+):(.+)/
      curr_address = $~[1].to_i 16
      dump_blob[curr_address] = $~[2].to_i 16
    elsif d =~ /(.+)/
      dump_blob[curr_address] = $~[1].to_i 16
    else
      puts "Malformed line in frame #{curr_frame}: #{d}"
      exit
    end
  end
  puts "Advanced dump #{curr_frame - 1} frames. Writing to #{options.out_dump_name}..." 
  out_dump = File.open options.out_dump_name, "wb"
  out_dump.write dump_blob.pack("C*")
  out_dump.close
else
  puts "No timestep advance requested, #{options.out_dump_name} not created/modified."
end



