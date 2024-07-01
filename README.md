# Overview
AI birdcam built off resources found in the original google birdcam project here: https://github.com/LetsOKdo/pi-coral-ai-birdcam
This project modernizes and customizes the older project, which now fails to run on newer versions of Raspberry Pi OS.

Takes pictures of birds every configurable amount of seconds (default is 60 seconds), and, if it is a bird, uploads it to
amazon s3.

The src directory of this project contains all the code and scripts used to run the project, while files outside that directory
are files copied to the operating system or other miscellaneous files. 

# Materials
Raspberry Pi 4b (you may be able to use other models, but other steps may be required) \
Raspberry Pi 4b-compatible power brick \
Micro HDMI to HDMI cable \
A screen of your liking (although you can probably go headless if you really wanted to) \
Mouse and keyboard \
microSD card (128 gb should be enough and are usually quite cheap for the price) \
https://www.amazon.com/SanDisk-Ultra-microSDHC-Memory-Adapter/dp/B0B7NTY2S6/ref=asc_df_B08GY9NYRM/?tag=hyprod-20&linkCode=df0&hvadid=693562313188&hvpos=&hvnetw=g&hvrand=14652162214080980121&hvpone=&hvptwo=&hvqmt=&hvdev=c&hvdvcmdl=&hvlocint=&hvlocphy=9051644&hvtargid=pla-1067844298997&mcid=782910132afc39cc971b60dc7595b486&gad_source=1&th=1
SD card reader (card reader adapter for microSD if necessary) \
Raspberry Pi Camera Module 3 (found here or your favorite site. Feel free to use the HQ camera with a telescopic lense
for higher quality zoom): \
https://www.adafruit.com/product/5657?gad_source=1&gclid=CjwKCAjwp4m0BhBAEiwAsdc4aFlACUN3Mn89NZQ4YGKHR50xyXH5SinT7-ZDjTG45wbNzG9NBoanbRoCO6UQAvD_BwE) \
Coral USB Accelerator (You may be able to get it cheaper elsewhere, but beware of long lead times): \
https://www.amazon.com/dp/B07S214S5Y \
Longer camera cable (again not necessary but quite helpful, the Camera Module 3 comes with a short one): \
https://www.amazon.com/dp/B088CQW11P/ref=twister_B09L13JRHD?_encoding=UTF8&th=1
Tripod (not necessary, you can potentially use your own): \
https://www.amazon.com/AmazonBasics-WT0352G-Lightweight-Mini-Tripod/dp/B00M78G2VO/ref=asc_df_B00M78G2VO/?tag=hyprod-20&linkCode=df0&hvadid=693416928164&hvpos=&hvnetw=g&hvrand=5846856766413096311&hvpone=&hvptwo=&hvqmt=&hvdev=c&hvdvcmdl=&hvlocint=&hvlocphy=9051644&hvtargid=pla-309497986922&mcid=8f066689339a30c49f9529edc96544a8&gad_source=1&th=1 \
Simple camera case (This was designed for the Camera Module 2 so the front won't snap on, mainly for tripod mounting, 
feel free to use something else): \
https://www.adafruit.com/product/3253 \
A Raspberry Pi 4b compatible case (Not necessary but it makes shorts less likely, and helps with cooling. If you get another
one make sure to get one with a hole for the camera cable): \
https://www.amazon.com/Vilros-Raspberry-Compatible-Built-Transparent/dp/B07VK9CN98/ref=asc_df_B07VK9CN98/?tag=hyprod-20&linkCode=df0&hvadid=693333921831&hvpos=&hvnetw=g&hvrand=15839572958934080318&hvpone=&hvptwo=&hvqmt=&hvdev=c&hvdvcmdl=&hvlocint=&hvlocphy=9051644&hvtargid=pla-816119968971&mcid=1b6c032ad8ff3a13822fc799b2af3daa&gad_source=1&th=1 \
An AWS account (if free tier, make sure to have alerts on to make sure you're not going over the s3 free usage limit)

# Installation
Using Raspberry Pi Imager (found here: https://www.raspberrypi.com/software/), image Raspberry Pi OS onto the SD card 
(although other Debian-based OS's should also work). \
Insert the microSD card into the slot on the RPi. \
Connect one side of the RPi camera cable to the RPi. \
Enclose the RPi with the case, plugging in the fan pins appropriately. Make sure to thread the camera cable through the hole. \
Plug in your peripherals, your monitor, and install the camera module on to the other end of the camera cable. \
Plug in the power brick and connect it to the RPi, the device should now boot up. The "Raibow Screen" is the first thing you should see. \
Go through the first boot process. \
Clone this repo: git clone https://github.com/shivapal/ai-birdcam.git \
Read the setup_bircam.sh script and edit the variables as necessary, then invoke it with: bash setup_birdcam.sh. Follow the directions as specified. \
In the classify_image.py, change the bucket_name variable to the name of your target s3 bucket \
Your bird camera is now functional, play with the zoom settings and other configurables to make sure you are getting
good pictures.