from io import BytesIO

import numpy as np
import onnxruntime as ort
import requests
from PIL import Image

labels = [
    "dress",
    "hat",
    "longsleeve",
    "outwear",
    "pants",
    "shirt",
    "shoes",
    "shorts",
    "skirt",
    "t-shirt",
]


def download_image(image_url):
    response = requests.get(image_url)
    response.raise_for_status()

    img_data = BytesIO(response.content)
    img = Image.open(img_data).convert("RGB")
    return img

print("hello world")

crop_size = 224
resize_size = 256
mean = [0.485, 0.456, 0.406]
std = [0.229, 0.224, 0.225]


def preprocess(image_url):
    img = download_image(image_url)
    img = img.resize((resize_size, resize_size))
    w, h = img.size
    left = (w - crop_size) // 2
    right = left + crop_size
    top = (h - crop_size) // 2
    bottom = top + crop_size
    img = img.crop((left, top, right, bottom))
    img_arr = np.array(img).astype(float)
    img_arr = img_arr / 255
    img_arr = (img_arr - mean) / std
    img_arr = img_arr.transpose(2, 0, 1)
    return img_arr[None, :]


def get_prediction(image_url):
    input = preprocess(image_url).astype("float32")
    session = ort.InferenceSession("model.onnx")
    output = session.run(None, {"input": input})
    return output[0][0].tolist()


def lambda_handler(event, context):
    url = event["url"]
    prediction = get_prediction(url)
    return dict(zip(labels, prediction))
