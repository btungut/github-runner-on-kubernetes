#!/bin/bash

cat << EOF
MIT License

Copyright (c) Burak TUNGUT
https://github.com/btungut/github-runner-on-kubernetes

If you find this project useful, please give a star. Thank you!
This repository and its contents are published under MIT license and purpose of this repository is to provide a simple way to run GitHub Runner on Kubernetes.
Please ensure the stability of your environment before using this repository!
EOF

# https://github.com/actions/runner/blob/main/src/Runner.Listener/CommandSettings.cs
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
[[ -z "${GITHUB_URL}" ]] && {
    echo "GITHUB_URL is not set"
    exit 1
}
GITHUB_URL=$(echo "${GITHUB_URL}" | tr -d '"')
echo "GITHUB_URL=${GITHUB_URL}"

[[ -z "${GITHUB_ORG_NAME}" ]] && {
    echo "GITHUB_ORG_NAME is not set"
    exit 1
}
GITHUB_ORG_NAME=$(echo "${GITHUB_ORG_NAME}" | tr -d '"')
echo "GITHUB_ORG_NAME=${GITHUB_ORG_NAME}"

[[ -z "${GITHUB_PAT}" ]] && {
    echo "GITHUB_PAT is not set"
    exit 1
}
GITHUB_PAT=$(echo "${GITHUB_PAT}" | tr -d '"')
echo "GITHUB_PAT is set and hidden"

GITHUB_RUNNER_NAME="${GITHUB_RUNNER_NAME:="$(hostname)"}"
GITHUB_RUNNER_NAME=$(echo "${GITHUB_RUNNER_NAME}" | tr -d '"')
echo "GITHUB_RUNNER_NAME=${GITHUB_RUNNER_NAME}"

GITHUB_RUNNER_GROUP="${GITHUB_RUNNER_GROUP:="Default"}"
GITHUB_RUNNER_GROUP=$(echo "${GITHUB_RUNNER_GROUP}" | tr -d '"')
echo "GITHUB_RUNNER_GROUP=${GITHUB_RUNNER_GROUP}"

GITHUB_RUNNER_LABELS="${GITHUB_RUNNER_LABELS:="dockerized-runner"}"
GITHUB_RUNNER_LABELS=$(echo "${GITHUB_RUNNER_LABELS}" | tr -d '"')
echo "GITHUB_RUNNER_LABELS=${GITHUB_RUNNER_LABELS}"

function destroy() {
    echo "Runner is stopping..."
    set +e

    URL="https://api.github.com/orgs/${GITHUB_ORG_NAME}/actions/runners/remove-token"
    RSP=$(exec $SCRIPT_DIR/call-api-github.sh "$URL" "$GITHUB_PAT")
    [[ "$?" -ne 0 ]] && { echo -e "Failed to get remove token\n$RSP"; exit 1; }
    echo "RM-TOKEN = $RSP"

    ./config.sh remove --token "${RSP}"
    if [[ "$?" -ne 0 ]]; then
        echo "Runner is not removed. Please remove manually."
    else
        echo "Runner is stopped and removed successfully."
    fi

    exit 0
}

trap destroy SIGTERM
trap destroy SIGINT
trap destroy EXIT

set -uo pipefail
set +e

URL="https://api.github.com/orgs/${GITHUB_ORG_NAME}/actions/runners/registration-token"
RSP=$(exec $SCRIPT_DIR/call-api-github.sh "$URL" "$GITHUB_PAT")
[[ "$?" -ne 0 ]] && { echo -e "Failed to get registration token\n$RSP"; exit 1; }
echo "REG-TOKEN = $RSP"

./config.sh \
    --url "${GITHUB_URL}" \
    --token "${RSP}" \
    --runnergroup "${GITHUB_RUNNER_GROUP}" \
    --name "${GITHUB_RUNNER_NAME}" \
    --labels "${GITHUB_RUNNER_LABELS}" \
    --ephemeral \
    --unattended \
    --replace
echo "Configuration completed successfully"
echo "Starting runner..."

set +e
./run.sh & wait $!
echo "run.sh stopped!"
destroy
