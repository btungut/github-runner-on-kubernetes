#!/bin/bash

# https://github.com/actions/runner/blob/main/src/Runner.Listener/CommandSettings.cs

[[ -z "${GITHUB_URL}" ]] && {
    echo "GITHUB_URL is not set"
    exit 1
}
GITHUB_URL=$(echo "${GITHUB_URL}" | tr -d '"')
echo "GITHUB_URL=${GITHUB_URL}"

[[ -z "${GITHUB_TOKEN}" ]] && {
    echo "GITHUB_TOKEN is not set"
    exit 1
}
GITHUB_TOKEN=$(echo "${GITHUB_TOKEN}" | tr -d '"')
echo "GITHUB_TOKEN is set and hidden"

GITHUB_RUNNER_NAME="${GITHUB_RUNNER_NAME:="$(hostname)"}"
GITHUB_RUNNER_NAME=$(echo "${GITHUB_RUNNER_NAME}" | tr -d '"')
echo "GITHUB_RUNNER_NAME=${GITHUB_RUNNER_NAME}"

GITHUB_RUNNER_GROUP="${GITHUB_RUNNER_GROUP:="Default"}"
GITHUB_RUNNER_GROUP=$(echo "${GITHUB_RUNNER_GROUP}" | tr -d '"')
echo "GITHUB_RUNNER_GROUP=${GITHUB_RUNNER_GROUP}"

GITHUB_RUNNER_LABELS="${GITHUB_RUNNER_LABELS:="dockerized-runner"}"
GITHUB_RUNNER_LABELS=$(echo "${GITHUB_RUNNER_LABELS}" | tr -d '"')
echo "GITHUB_RUNNER_LABELS=${GITHUB_RUNNER_LABELS}"

set -euo pipefail

./config.sh \
    --url "${GITHUB_URL}" \
    --token "${GITHUB_TOKEN}" \
    --runnergroup "${GITHUB_RUNNER_GROUP}" \
    --name "${GITHUB_RUNNER_NAME}" \
    --labels "${GITHUB_RUNNER_LABELS}" \
    --ephemeral \
    --unattended \
    --replace
echo "Configuration completed successfully"
echo "Starting runner..."

cat << EOF
MIT License

Copyright (c) Burak TUNGUT
https://github.com/btungut/github-runner-on-kubernetes

If you find this project useful, please give a star. Thank you!
This repository and its contents are published under MIT license and purpose of this repository is to provide a simple way to run GitHub Runner on Kubernetes.
Please ensure the stability of your environment before using this repository!
EOF

set +e
./run.sh
set -e

echo "Runner is stopping..."
./config.sh remove --unattended --token "${GITHUB_TOKEN}"
echo "Runner is stopped"
