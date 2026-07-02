FROM node:20-slim

WORKDIR /app

# Install curl + OpenClaw
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/* && npm install -g openclaw@latest

# Install lark-cli
RUN npm install -g @larksuite/cli@latest

# Create data directory
RUN mkdir -p /data/workspace

# Copy startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Expose ports
EXPOSE 18789 8081

CMD ["/app/start.sh"]
