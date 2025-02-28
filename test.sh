#!/usr/bin/env bash

# Define an array of docker images for testing
declare -a docker_images
docker_images=( $(docker search --filter is-official=true --filter stars=3 --format="{{.Name}}" "operating systems") )

# Get the length of the array
array_length=${#docker_images[@]}

DOCKER_API_ENDPOINT=https://registry.hub.docker.com/v2/repositories/library
JSON_TAG_QUERY=".results[] | select(.images | map(.architecture) | contains([\"$(arch)\"])) | .name"

# Loop through the array using index
for (( i=0; i<array_length; i++ )); do
    image=${docker_images[$i]}
    tag=$(curl -s -S "$DOCKER_API_ENDPOINT/$image/tags/" \
        | jq --raw-output "$JSON_TAG_QUERY" | head -n 1)

    if ! docker image inspect "$image:$tag" &>/dev/null; then
        echo "$i: Pulling test image '$image:$tag'..."
        if ! docker pull --quiet "$image:$tag"; then
            printf "\e[31;1m%s\e[0m\n" "Puling failed, aborting..."
            exit 1
        fi
    else
        echo "$i: Test image '$image:$tag' found..."
    fi
done
