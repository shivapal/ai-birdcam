#!/bin/bash

source library_functions.sh

PROJECT_DIR="$HOME/BirdcamCustom"
FILE_NAME="$HOME/Pictures/bird_pic.jpg"
RUN_MODE=$(read_property "$PROJECT_DIR/birdcam.properties" run-mode)

if [ "$RUN_MODE" = "oneshot" ]; then
  rpicam-still -o "$FILE_NAME"
else
  { while(true); do rpicam-still -o "$FILE_NAME"; sleep 6; done } &
fi

python3 "$PROJECT_DIR/classify_image.py" \
--model "$PROJECT_DIR/mobilenet_v2_1.0_224_inat_bird_quant_edgetpu.tflite" \
--labels "$PROJECT_DIR/inat_bird_labels.txt" \
--input "$FILE_NAME" \
--threshold 0.5 \
--run_mode "$RUN_MODE" &
