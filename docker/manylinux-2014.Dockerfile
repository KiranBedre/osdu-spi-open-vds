# Pinned to the last image that still ships CPython 3.8 (manylinux dropped 3.8 on
# 2026-05-07). Downstream CI assumes cp38 wheels exist, so we can't track latest.
FROM quay.io/pypa/manylinux2014_x86_64:2026.05.02-2

RUN curl -sSL  -o ninja.zip "https://github.com/ninja-build/ninja/releases/download/v1.10.2/ninja-linux.zip"
RUN unzip ninja.zip && mv ninja /usr/local/bin/ && rm -vf ninja* && ln -s /usr/local/bin/ninja /usr/local/bin/ninja-build

RUN yum install -y vim less gdb java-1.8.0-openjdk-devel ccache perl perl-IPC-Cmd

COPY python/requirements-dev-with-docs.txt /tmp/requirements-dev.txt

# Install the dev dependencies into each targeted CPython the image actually ships.
# manylinux drops EOL interpreters, so skip any that are absent rather than
# hardcoding paths that break when the base image updates.
# numpy is capped below 2.5: newer numpy no longer publishes manylinux2014 wheels
# and its source build requires GCC >= 10.3, while this image ships GCC 10.2.1
# (devtoolset-10), so pip would fail building it for cp312/cp313.
RUN set -eu; for v in cp38 cp39 cp310 cp311 cp312 cp313; do \
      py="/opt/python/$v-$v/bin/python"; \
      if [ -x "$py" ]; then \
        echo "=== installing dev requirements for $v ==="; \
        "$py" -m pip install -r /tmp/requirements-dev.txt "numpy<2.5"; \
      else \
        echo "=== $v not present in image, skipping ==="; \
      fi; \
    done

ENV CMAKE_BUILD_PARALLEL_LEVEL=2