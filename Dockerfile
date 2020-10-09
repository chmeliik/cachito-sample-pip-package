FROM fedora:32

RUN dnf -y install python-pip
# gcc is needed to compile python dependencies written in C/C++
RUN dnf -y install git gcc
# when compiling, development headers are also often needed
RUN dnf -y group install "Development Libraries"
# needed to compile psycopg2
RUN dnf -y install libpq-devel
# needed to compile marisa-trie
RUN dnf -y install gcc-c++
# needed to compile pillow
RUN dnf -y install libjpeg-devel zlib-devel

# You don't need to do this if you use OSBS vvv ##########################################
RUN dnf -y install jq

ARG CACHITO_API_URL="http://localhost:8080/api/v1"
ARG CACHITO_REQUEST_ID="8"

WORKDIR /bundle
RUN curl "$CACHITO_API_URL/requests/$CACHITO_REQUEST_ID/download" > bundle.tar.gz
RUN tar xf bundle.tar.gz

WORKDIR /bundle/app

RUN curl "$CACHITO_API_URL/requests/$CACHITO_REQUEST_ID/configuration-files" \
    | jq -r '.[] | select(.path == "app/requirements.txt") | .content' \
    | base64 --decode > requirements.txt

RUN curl "$CACHITO_API_URL/requests/$CACHITO_REQUEST_ID/configuration-files" \
    | jq -r '.[] | select(.path == "app/requirements-build.txt") | .content' \
    | base64 --decode > requirements-build.txt

RUN curl "$CACHITO_API_URL/requests/$CACHITO_REQUEST_ID/configuration-files" \
    | jq -r \
        '.[] | select(.path == "app/requierements-build-conflicting.txt") | .content' \
    | base64 --decode > requirements-build-conflicting.txt

RUN curl "$CACHITO_API_URL/requests/$CACHITO_REQUEST_ID/configuration-files" \
    | jq -r '.[] | select(.path == "app/requirements-pip.txt") | .content' \
    | base64 --decode > requirements-pip.txt

RUN curl "$CACHITO_API_URL/requests/$CACHITO_REQUEST_ID/configuration-files" \
    | jq -r '.[] | select(.path == "app/package-index-ca.pem") | .content' \
    | base64 --decode > package-index-ca.pem

RUN curl "$CACHITO_API_URL/requests/$CACHITO_REQUEST_ID" \
    | jq -r '.environment_variables.PIP_INDEX_URL' > /bundle/app/pip-index-url.txt

RUN sed 's/nexus:8081/localhost:8082/' /bundle/app/pip-index-url.txt --in-place
RUN sed 's/nexus:8081/localhost:8082/' /bundle/app/requirements.txt --in-place
RUN sed 's/nexus:8081/localhost:8082/' /bundle/app/requirements-pip.txt --in-place
RUN sed 's/nexus:8081/localhost:8082/' /bundle/app/requirements-build.txt --in-place
RUN sed 's/nexus:8081/localhost:8082/' /bundle/app/requirements-build-conflicting.txt \
    --in-place
# You don't need to do this if you use OSBS ^^^ ##########################################

# You don't need to export env vars manually if you use OSBS
RUN export PIP_CERT=/bundle/app/package-index-ca.pem && \
    export PIP_INDEX_URL=$(cat /bundle/app/pip-index-url.txt) && \
    python3 -m pip install -U pip setuptools wheel && \
    python3 -m pip install -r requirements-build.txt && \
    python3 -m pip install -r requirements.txt
