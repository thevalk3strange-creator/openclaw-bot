FROM node:22-slim
WORKDIR /app
COPY gamvoc-bot.js /app/gamvoc-bot.js
COPY start-bot.sh /app/start-bot.sh
RUN chmod +x /app/start-bot.sh
CMD ["/app/start-bot.sh"]
