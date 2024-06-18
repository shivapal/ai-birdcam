#!/bin/bash

HOME_DIR="/home/birdcam/"
PROJECT_DIR="$HOME_DIR""BirdcamCustom/"
DATE_TIME="$(date +"%m-%d-%Y_%H-%M-%S")"
#FILE_NAME="$HOME_DIR""Pictures/""$DATE_TIME""_pic.jpg"
FILE_NAME="$HOME_DIR""Pictures/""bird_pic.jpg"
echo $DATE_TIME
echo $FILE_NAME

{ while(true); do rpicam-still -o "$FILE_NAME"; sleep 6; done } &
#rpicam-still -o "$FILE_NAME"
python3  "$PROJECT_DIR""classify_image.py"   --model "$PROJECT_DIR""mobilenet_v2_1.0_224_inat_bird_quant_edgetpu.tflite"    --labels "$PROJECT_DIR""inat_bird_labels.txt"   --input "$FILE_NAME" --threshold 0.5 &

