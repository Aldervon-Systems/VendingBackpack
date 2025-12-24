FROM python:3.11-slim
WORKDIR /app

# copy demo DB and app files from build context (v1/mock_server)
COPY demo_db.json ./demo_db.json
COPY app.py ./app.py
COPY requirements.txt ./requirements.txt

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8000
ENV FLASK_ENV=production

CMD ["python", "app.py"]
