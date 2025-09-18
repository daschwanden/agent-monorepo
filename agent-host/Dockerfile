FROM python:3.13-slim

RUN pip install --no-cache-dir google-adk[a2a]

WORKDIR /agent

COPY ./ .

EXPOSE 8001

CMD ["adk", "web", "--host", "0.0.0.0", "--port", "8000", ".", "--log_level", "debug"]