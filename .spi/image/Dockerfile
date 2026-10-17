ARG UBUNTU_IMAGE=ubuntu:22.04@sha256:5ec03bb3441e8b0bf3b4f9cd4629a1ae763010dc3035bb8da3ae6cf026486401

FROM ${UBUNTU_IMAGE} AS spi-build

ARG CMAKE_VERSION=3.26.4
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        git \
        libssl-dev \
        ninja-build \
    && rm -rf /var/lib/apt/lists/*

RUN case "$TARGETARCH" in \
      amd64) cmake_arch=x86_64; cmake_sha=ba1e0dcc710e2f92be6263f9617510b3660fa9dc409ad2fb8190299563f952a0 ;; \
      arm64) cmake_arch=aarch64; cmake_sha=1c9843c92f40bee1a16baa12871693d3e190c9a222259a89e406d4d9aae6cf74 ;; \
      *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 2 ;; \
    esac \
    && curl --fail --location --silent --show-error \
      --output /tmp/cmake.tar.gz \
      "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-${cmake_arch}.tar.gz" \
    && echo "${cmake_sha}  /tmp/cmake.tar.gz" | sha256sum --check --strict \
    && tar --extract --gzip --file /tmp/cmake.tar.gz \
      --directory /usr/local --strip-components=1 \
    && rm /tmp/cmake.tar.gz

WORKDIR /src
COPY . .

RUN cmake -S . -B /build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/opt/openvds \
        -DBUILD_DOCS=OFF \
        -DBUILD_EXAMPLES=OFF \
        -DBUILD_JAVA=OFF \
        -DBUILD_PYTHON=OFF \
        -DBUILD_TESTS=ON \
        -DDISABLE_AWS_IOMANAGER=ON \
        -DDISABLE_AZURE_IOMANAGER=ON \
        -DDISABLE_AZURE_PRESIGNED_IOMANAGER=ON \
        -DDISABLE_AZURESDKFORCPP_IOMANAGER=OFF \
        -DDISABLE_DMS_IOMANAGER=OFF \
        -DDISABLE_GCP_IOMANAGER=ON \
    && cmake --build /build --parallel 4

RUN mkdir -p /spi-test \
    && ctest --test-dir /build --parallel 4 --output-on-failure \
        --output-junit /spi-test/ctest.xml \
    && cmake --install /build \
    && test -x /opt/openvds/bin/SEGYImport \
    && library="$(find /opt/openvds -type f -name 'libopenvds.so*' -print -quit)" \
    && test -n "$library" \
    && strings "$library" | grep -F "FetchWorkloadIdentityToken: start"

FROM scratch AS spi-test
COPY --from=spi-build /spi-test/ctest.xml /ctest.xml

FROM ${UBUNTU_IMAGE} AS final

ARG build_date
ARG commit_id
ARG release_version

LABEL org.opencontainers.image.created="${build_date}" \
      org.opencontainers.image.revision="${commit_id}" \
      org.opencontainers.image.version="${release_version}" \
      org.opencontainers.image.title="OpenVDS Import/Export Tool" \
      org.opencontainers.image.licenses="Apache-2.0"

ENV CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        ca-certificates \
        libstdc++6 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /data /data_in /data_out \
    && chown -R 10001:10001 /data /data_in /data_out

COPY --from=spi-build /opt/openvds/ /usr/local/
COPY .spi/image/entrypoint.sh /usr/local/bin/openvds-entrypoint
RUN chmod 0755 /usr/local/bin/openvds-entrypoint

WORKDIR /data
USER 10001:10001
ENTRYPOINT ["/usr/local/bin/openvds-entrypoint"]
