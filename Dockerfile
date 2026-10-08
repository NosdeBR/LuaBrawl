FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    lua5.4 \
    lua-socket \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY server.lua /app/

EXPOSE 10000
CMD ["lua5.4", "server.lua"]