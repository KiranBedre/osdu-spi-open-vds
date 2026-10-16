# OpenVDS companion image for Azure OSDU

[![Validate](https://github.com/KiranBedre/osdu-spi-open-vds/actions/workflows/validate.yml/badge.svg?branch=main)](https://github.com/KiranBedre/osdu-spi-open-vds/actions/workflows/validate.yml)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

This repository packages the OSDU community
[OpenVDS](https://community.opengroup.org/osdu/platform/domain-data-mgmt-services/seismic/open-vds)
tools as the companion image used by the SEG-Y to VDS Airflow workflow.

## Ownership

The community OpenVDS tree is synchronized unchanged in passthrough mode.
Fork-owned build and acceptance files live under `.spi/`.

| Path | Owner | Contents |
|---|---|---|
| `src/`, `tests/`, `tools/` | OSDU upstream | OpenVDS libraries, tests, and command-line tools |
| `.spi/image/` | This repository | Test-gated, non-root companion image |
| `.spi/acceptance/` | This repository | Workflow prerequisite check |
| `.spi/service.yaml` | This repository | SPI build and acceptance contract |

## Image contract

The image contains `SEGYImport`, `SEGYExport`, `VDSInfo`, and `VDSCopy`.
It keeps the DMS and Azure SDK backends, including native Workload Identity
token acquisition, and omits unrelated AWS, GCP, legacy Azure, and Azure
presigned backends.

The Dockerfile builds the complete C++ test inventory and runs CTest before it
installs the artifacts copied into the runtime image. CI extracts
`/ctest.xml` from the fixed `spi-test` target and rejects missing, failing, or
all-skipped evidence.

The runtime:

- uses a digest-pinned Ubuntu 22.04 base;
- runs as UID and GID `10001`;
- uses `/data` as its working directory so Kubernetes `command` overrides do
  not bypass the expected location; and
- contains no Azure credentials or client secrets.

## Build

CI is authoritative for the multi-stage build:

```bash
docker build --file .spi/image/Dockerfile --target spi-test .
docker build --file .spi/image/Dockerfile .
```

The trusted publication lane builds `linux/amd64` and `linux/arm64`. Pull
request native tests run on `linux/amd64`.

## Acceptance and certification

The source acceptance suite confirms that the
`segy-to-vds-conversion` workflow prerequisite is registered. End-to-end
certification is owned by the SPI Stack integration: trigger the workflow with
an approved small SEG-Y input, verify that the conversion pod uses Workload
Identity and this image digest, verify the resulting VDS metadata, then remove
the test records and storage.

## License

Copyright © Microsoft Corporation

Licensed under the [Apache License 2.0](LICENSE).
