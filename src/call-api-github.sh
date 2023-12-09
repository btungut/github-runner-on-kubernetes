#!/bin/bash
[[ -z "${1}" ]] && { echo "1st argument should be GitHub Restfull API"; exit 1; }
ARG_GITHUB_URL="${1}"
[[ "${ARG_GITHUB_URL}" != "https://api.github.com/"* ]] && { 
    echo "1st argument should start with https://api.github.com/";
    exit 1;
}

[[ -z "${2}" ]] && { echo "2nd argument should be GitHub PAT"; exit 1; }
ARG_GITHUB_PAT="${2}"

RSP=$(curl -LSs \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $ARG_GITHUB_PAT" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "$ARG_GITHUB_URL"
    )

if [[ "$?" -ne 0 ]]; then
    echo "Failed to call GitHub API"
    exit 1
fi

RSP_MESSAGE=$(echo "${RSP}" | jq -r '.message')
if [[ "${RSP_MESSAGE}" != "null" ]]; then
    echo "API call failed : ${RSP}"
    exit 1
fi

RSP_TOKEN=$(echo "${RSP}" | jq -r '.token')
if [[ "${RSP_TOKEN}" == "null" ]]; then
    echo "Failed to get token: ${RSP}"
    exit 1
fi

export RSP_TOKEN="${RSP_TOKEN}"
echo "$RSP_TOKEN"
exit 0