FROM python:3.10-slim

# Sem buffer, os prints chegam ao Cloud Logging assim que acontecem.
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Dependências antes do código: quando só o app.py muda, o build reaproveita
# a camada do pip.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# O Cloud Run informa a porta em $PORT. Com --timeout 0 o gunicorn não mata
# workers por tempo e quem controla o limite da requisição é o Cloud Run.
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 app:app
