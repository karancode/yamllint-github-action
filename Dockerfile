FROM python:3.11-alpine

# hadolint ignore=DL3018
RUN apk add --update --no-cache bash ca-certificates curl git jq openssh

# hadolint ignore=DL3013
RUN pip install 'pyyaml==5.3.1' && \
    pip install wheel && \
    pip install yamllint

RUN ["bin/sh", "-c", "mkdir -p /src"]

COPY ["src", "/src/"]

ENTRYPOINT ["/src/entrypoint.sh"]
