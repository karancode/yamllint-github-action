FROM python:3.7-alpine

RUN apk add --update --no-cache bash ca-certificates curl git jq openssh

RUN pip install yamllint

RUN ["bin/sh", "-c", "mkdir -p /src"]

COPY ["src", "/src/"]

ENTRYPOINT ["/src/entrypoint.sh"]