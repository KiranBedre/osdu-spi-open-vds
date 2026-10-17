#!/usr/bin/env bash

set -euo pipefail

case "${1:-}" in
  SEGYImport|import)
    shift
    exec SEGYImport "$@"
    ;;
  SEGYExport|export)
    shift
    exec SEGYExport "$@"
    ;;
  VDSInfo|info)
    shift
    exec VDSInfo "$@"
    ;;
  VDSCopy|copy)
    shift
    exec VDSCopy "$@"
    ;;
esac

echo "OpenVDS Import/Export image"
echo "Use import, export, info, or copy."
