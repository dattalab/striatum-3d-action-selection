#!/bin/bash
# hunts down and convert all avi files to mp4
find $1 -type f -name "*.avi" -mtime +30s -execdir sh -c 'ffmpeg -i $0 -vcodec libx264 -crf 18 -preset veryfast -an `basename "$0" .avi`.mp4; rm $0' {} \;
