#!/bin/bash
# this script will get the md5sum for each course file
# then compare the new md5sum file with the file downloaded with the course
# this script should be run from the directory you downloaded all files into 
md5sum *.7z.??? > md5sums && diff md5sums *.7z.md5*
# 
