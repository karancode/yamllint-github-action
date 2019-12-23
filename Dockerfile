FROM python:3.7-alpine

RUN pip install yamllint

RUN ["bin/sh", "-c", "mkdir -p /src"]

COPY ["src", "/src/"]

ENTRYPOINT ["/src/entrypoint.sh"]