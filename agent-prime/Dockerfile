FROM python:3.13-slim

RUN pip install --no-cache-dir google-adk[a2a]

WORKDIR /agent

COPY ./ .

EXPOSE 8001

CMD ["adk", "api_server", "--a2a", "--host", "0.0.0.0", "--port", "8001", ".", "--log_level", "debug"]
