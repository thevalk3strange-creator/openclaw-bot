FROM node:20-slim

WORKDIR /app

# Install OpenClaw globally
RUN npm install -g openclaw@latest

# Install lark-cli globally
RUN npm install -g @larksuite/cli@latest

# Create data directory
RUN mkdir -p /data/workspace

# Copy startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Expose ports
EXPOSE 18789 8081

CMD ["/app/start.sh"]
