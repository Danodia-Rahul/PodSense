import time
from io import BytesIO

import numpy as np
import onnxruntime as ort
import requests
from fastapi import FastAPI, File, HTTPException, Request, UploadFile
from fastapi.responses import Response
from PIL import Image
from prometheus_client import (CONTENT_TYPE_LATEST, Counter, Gauge, Histogram,
                               generate_latest)
from pydantic import BaseModel
from starlette.responses import Response

request_counter = Counter(
    "http_requests_total", "Total HTTP requests", ["method", "path", "status"]
)

request_latency = Histogram(
    "http_request_duration_second",
    "HTTP request latency",
    ["method", "path"],
    buckets=(0.05, 0.1, 0.2, 0.5, 1, 2, 5),
)

in_flight_request = Gauge("http_request_in_flight", "Current in-flight HTTP requests")


class URLReqeust(BaseModel):
    url: str


app = FastAPI()


@app.middleware("http")
async def prometheus_middleware(request: Request, call_next):
    in_flight_request.inc()
    start_time = time.time()

    try:
        response = await call_next(request)
        return response
    finally:
        duration = time.time() - start_time
        in_flight_request.dec()

        request_latency.labels(method=request.method, path=request.url.path).observe(
            duration
        )

        request_counter.labels(
            method=request.method, path=request.url.path, status=response.status_code
        ).inc()


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.get("/health")
def health():
    return {"status": "ok"}


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


try:
    session = ort.InferenceSession("model.onxx")
    model_ready = True
except Exception as e:
    model_ready = False
    model_error = str(e)
    session = None


@app.get("/ready")
def ready():
    if model_ready and session is not None:
        return {"status": "ok"}
    else:
        raise HTTPException(status_code=400, detail=model_error)


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
    return dict(sorted(zip(labels, prediction), key=lambda x: -x[1]))


@app.post("/predict/url")
async def prefict_from_url(image_url: URLReqeust):
    try:
        image = image_from_url(image_url.url)
        input_tensor = preprocess(image)
        predictions = get_prediction(input_tensor)
        return {"Response": predictions}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/predict/file")
async def prefict_from_file(file: UploadFile | None = File(None)):
    try:
        if file is None:
            raise HTTPException(status_code=400, detail="Upload a file")
        else:
            image_bytes = await file.read()
            image = Image.open(BytesIO(image_bytes)).convert("RGB")
            input_tensor = preprocess(image)
            predictions = get_prediction(input_tensor)
            return {"Response": predictions}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
