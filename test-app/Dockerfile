FROM ubuntu:18.04

RUN apt-get update && apt-get install -y curl && apt-get install -y jq

COPY test-app.sh /

CMD ["bash", "/test-app.sh"]
