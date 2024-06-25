# Lint as: python3
# Credit to google PyCoral examples, licensed under Apache license Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
r"""Example using PyCoral to classify a given image using an Edge TPU.

To run this code, you must attach an Edge TPU attached to the host and
install the Edge TPU runtime (`libedgetpu.so`) and `tflite_runtime`. For
device setup instructions, see coral.ai/docs/setup.

Example usage:
```
bash examples/install_requirements.sh classify_image.py

python3 examples/classify_image.py \
  --model test_data/mobilenet_v2_1.0_224_inat_bird_quant_edgetpu.tflite  \
  --labels test_data/inat_bird_labels.txt \
  --input test_data/parrot.jpg
```
"""

import argparse
import os
import sys
# import logging
# import threading
import time
import sched
import boto3
import datetime

import numpy as np
from PIL import Image
from pycoral.adapters import classify
from pycoral.adapters import common
from pycoral.utils.dataset import read_label_file
from pycoral.utils.edgetpu import make_interpreter


# import sys

# replace with your own bucket
bucket_name = 'shivamainbucket'

def main():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument(
        '-m', '--model', required=True, help='File path of .tflite file.')
    parser.add_argument(
        '-i', '--input', required=True, help='Image to be classified.')
    parser.add_argument(
        '-l', '--labels', help='File path of labels file.')
    parser.add_argument(
        '-k', '--top_k', type=int, default=1,
        help='Max number of classification results')
    parser.add_argument(
        '-t', '--threshold', type=float, default=0.0,
        help='Classification score threshold')
    parser.add_argument(
        '-c', '--count', type=int, default=5,
        help='Number of times to run inference')
    parser.add_argument(
        '-a', '--input_mean', type=float, default=128.0,
        help='Mean value for input normalization')
    parser.add_argument(
        '-s', '--input_std', type=float, default=128.0,
        help='STD value for input normalization')
    parser.add_argument(
        '-r', '--run_mode', default='oneshot',
        help='oneshot or autostart')
    # TODO: incorporate these args

    # parser.add_argument('--training', action='store_true',
    #                     help='Training mode for image collection')
    # parser.add_argument('--visit_interval', action='store', type=int, default=2,
    #                     help='Minimum interval between bird visits')
    args = parser.parse_args()

    # TODO: make logging work

    # logging.basicConfig(filename='%s/results.log' % storage_dir,
    #                     format='%(asctime)s-%(message)s',
    #                     level=logging.DEBUG)
    s3 = boto3.resource('s3')
    labels = read_label_file(args.labels) if args.labels else {}

    interpreter = make_interpreter(*args.model.split('@'))
    interpreter.allocate_tensors()

    # Model must be uint8 quantized
    if common.input_details(interpreter, 'dtype') != np.uint8:
        raise ValueError('Only support uint8 input type.')

    size = common.input_size(interpreter)

    my_scheduler = sched.scheduler(time.time, time.sleep)
    my_scheduler.enter(10, 1, classify_image, (my_scheduler, args, size, interpreter, labels, s3,))
    my_scheduler.run()

    # TODO: add back code for unique visits

    # last_time = time.monotonic()
    # last_results = [('label', 0)]
    # visitors = []
    #
    # DURATION = args.visit_interval
    # timer = False
    #
    # def timed_event():
    #     nonlocal timer
    #     timer = True
    #     threading.Timer(DURATION, timed_event).start()
    #
    # timed_event()


def classify_image(scheduler, args, size, interpreter, labels, s3):
    if args.run_mode == 'autostart':
        scheduler.enter(10, 1, classify_image, (scheduler, args, size, interpreter, labels, s3,))

    image = Image.open(args.input).convert('RGB').resize(size, Image.LANCZOS)

    # Image data must go through two transforms before running inference:
    # 1. normalization: f = (input - mean) / std
    # 2. quantization: q = f / scale + zero_point
    # The following code combines the two steps as such:
    # q = (input - mean) / (std * scale) + zero_point
    # However, if std * scale equals 1, and mean - zero_point equals 0, the input
    # does not need any preprocessing (but in practice, even if the results are
    # very close to 1 and 0, it is probably okay to skip preprocessing for better
    # efficiency; we use 1e-5 below instead of absolute zero).
    params = common.input_details(interpreter, 'quantization_parameters')
    scale = params['scales']
    zero_point = params['zero_points']
    mean = args.input_mean
    std = args.input_std
    if abs(scale * std - 1) < 1e-5 and abs(mean - zero_point) < 1e-5:
        # Input data does not require preprocessing.
        common.set_input(interpreter, image)
    else:
        # Input data requires preprocessing
        normalized_input = (np.asarray(image) - mean) / (std * scale) + zero_point
        np.clip(normalized_input, 0, 255, out=normalized_input)
        common.set_input(interpreter, normalized_input.astype(np.uint8))

    # Run inference
    print('----INFERENCE TIME----')
    print('Note: The first inference on Edge TPU is slow because it includes',
          'loading the model into Edge TPU memory.')
    for _ in range(args.count):
        start = time.perf_counter()
        interpreter.invoke()
        inference_time = time.perf_counter() - start
        classes = classify.get_classes(interpreter, args.top_k, args.threshold)
        print('%.1fms' % (inference_time * 1000))

    print('-------RESULTS--------')
    for c in classes:
        print('%s: %.5f' % (labels.get(c.id, c.id), c.score))

    if len(classes) >= 1:
        if labels.get(classes[0].id, classes[0].id) != 'background':
            with open(args.input, 'rb') as data:
                upload_file = 'birdPics/' + datetime.datetime.now().strftime("%H_%M_%S-%m_%d_%y") + 'bird_pic.jpg'
                s3.Bucket(bucket_name).put_object(Key=upload_file, Body=data)

    if args.run_mode == 'oneshot':
        sys.exit(0)


if __name__ == '__main__':
    main()
