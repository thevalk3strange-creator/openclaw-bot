FROM node:22-slim

WORKDIR /app

# Install curl + OpenClaw
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/* && npm install -g openclaw@latest

# Install lark-cli
RUN npm install -g @larksuite/cli@latest

# Create data directory + skills
RUN mkdir -p /data/workspace/skills/lark-base

# Copy skills
COPY skills/lark-base/SKILL.md /data/workspace/skills/lark-base/SKILL.md

# Copy startup script + lark lookup
COPY start.sh /app/start.sh
COPY lark-lookup.js /usr/local/bin/lark-lookup
RUN chmod +x /app/start.sh /usr/local/bin/lark-lookup

# Expose ports
EXPOSE 18789 8081

CMD ["/app/start.sh"]
