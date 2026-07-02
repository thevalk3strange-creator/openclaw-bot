FROM nousresearch/hermes-agent:latest
USER root

# Install lark-cli
RUN npm install -g @larksuite/cli@latest

# Copy tools and startup script
COPY lark-lookup.js /usr/local/bin/lark-lookup
COPY gamvoc.sh /usr/local/bin/gamvoc
COPY start-hermes.sh /usr/local/bin/start-hermes.sh
RUN chmod +x /usr/local/bin/lark-lookup /usr/local/bin/gamvoc /usr/local/bin/start-hermes.sh

CMD ["/usr/local/bin/start-hermes.sh"]
