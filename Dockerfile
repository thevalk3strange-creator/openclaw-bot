FROM nousresearch/hermes-agent:latest
USER root
RUN npm install -g @larksuite/cli@latest
COPY start-hermes.sh /usr/local/bin/start-hermes.sh
RUN chmod +x /usr/local/bin/start-hermes.sh
CMD ["/usr/local/bin/start-hermes.sh"]
