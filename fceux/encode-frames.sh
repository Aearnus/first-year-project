ffmpeg -start_number 0 -framerate 60 -i out.dump%06d.png -vcodec libx264 -b:v 1M -b:a 0 out.mp4
