
# Use the official lightweight Python image.
# https://hub.docker.com/_/python
FROM python:3.9-slim

# Allow statements and log messages to immediately appear in the Knative logs
ENV PYTHONUNBUFFERED True

# Copy local code to the container image.
ENV APP_HOME /app
WORKDIR $APP_HOME
COPY . ./

RUN pip install Flask gunicorn google.cloud.bigquery

# Run the web service on container startup
CMD exec gunicorn --bind :8080 --workers 1 --threads 8 --timeout 0 main:app
