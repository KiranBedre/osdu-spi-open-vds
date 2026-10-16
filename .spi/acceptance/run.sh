#!/usr/bin/env bash

set -euo pipefail

exec node acceptance/workflow-smoke.mjs "$@"
