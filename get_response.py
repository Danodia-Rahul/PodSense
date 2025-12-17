from io import BytesIO

import numpy as np
import onnxruntime as ort
import requests
from PIL import Image

def image_from_url(url):
    response = requests.get(url)
    response.raise_for_status()

    img_data = BytesIO(response.content)
    img = Image.open(img_data).convert("RGB")
    return img


def preprocess(image):
    crop_size = 224
    resize_size = 256
    mean = [0.485, 0.456, 0.406]
    std = [0.229, 0.224, 0.225]

    img = image.resize((resize_size, resize_size))
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
    return img_arr[None, :].astype("float32")


def get_prediction(input):
    session = ort.InferenceSession("model.onnx")
    output = session.run(None, {"input": input})
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

    prediction = output[0][0].tolist()
    return dict(zip(labels, prediction))

def get_response(input_data):
    try:
        if isinstance(input_data, str):
            image = image_from_url(input_data)
        else:
            image = Image.open(input_data).convert("RGB")

        input_tensor = preprocess(image)
        predictions = get_prediction(input_tensor)
        return predictions

    except Exception as e:
        print(e)

