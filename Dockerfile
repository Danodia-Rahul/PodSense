FROM python:3.13-slim

WORKDIR /app

COPY model.onnx /app/
COPY get_response.py /app/
COPY requirements.txt /app/
COPY ui.py /app/

RUN pip install -r requirements.txt

ENTRYPOINT ["streamlit", "run", "ui.py", "--server.port=8501", "--server.address=0.0.0.0"]
