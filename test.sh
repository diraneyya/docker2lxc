#!/usr/bin/env bash

# is docker installed? then test using docker, otherwise
# test on the local host. you can also pass '--local'
if command -v docker &>/dev/null && [[ $1 =~ ^'-'{1,2}'l' ]]; then

# Define an array of docker images for testing
declare -a docker_images
docker_images=( $(docker search --filter is-official=true --filter stars=3 --format="{{.Name}}" "operating systems") )
# Exclude busybox, as a side effect of this nice syntax, we are also un-
# intentionally dropping any images whose name starts with "busybox".
docker_images=( ${docker_images[@]##busybox*} ) 
declare -a docker_image_ids

# Get the length of the array
array_length=${#docker_images[@]}

# A function to filter tags from the ones found locally
function retrieve_tag() (
    if [[ " $* " =~ 'latest' ]]; then
        echo -n 'latest'
        return 0
    fi

    shopt -s extglob
    usable_tags=( ${@##@(unstable|preview|dev|night)*} )
    
    echo -n "${usable_tags[0]:-latest}"
    test -n "${usable_tags[0]}"
    return $?
)

# Loop through the array using index
for (( i=0; i<array_length; i++ )); do
    image=${docker_images[$i]}
    available_tags=( $( docker image ls --format "{{.Tag}}" $image ) )
    # remove unstable, preview, nightly and dev images
    tag=$( retrieve_tag ${available_tags[@]} )

    if [[ $? -ne 0 ]]; then
        echo "$i: Pulling test image '$image:$tag'..."
        if ! docker pull --quiet "$image:$tag"; then
            printf "\e[33;1m%s\e[0m\n" "Puling failed, skipping image..."
            docker_images=( "${docker_images[@]:0:i}" "${docker_images[@]:i+1}" )
            ((i--))
            ((array_length--))
            continue
        fi
    else
        echo "$i: Test image '$image:$tag' found locally..."
    fi

    docker_image_ids+=( $( docker image ls --format "{{.ID}}" "$image:$tag" ) )
done

# is docker not available?
else
LOCAL_TESTING=1
array_length=1
fi

failed_tests=0

for (( i=0; i<array_length; i++ )); do

    if [ -n "$LOCAL_TESTING" ]; then 
        target="the local system"
    else
        target="${docker_images[i]}"
    fi 

    printf "\e[34;1m%s\e[0m\n" "Testing under $target..."
    declare -a test_results

    if [ -n "$LOCAL_TESTING" ]; then 
        test_results=( $(./unit_test.sh))
    else
        test_results=( $(docker run -it --rm -v .:/app --entrypoint \
            "/app/unit_test.sh" ${docker_image_ids[i]} /app | tr "\r\n" "  ") )
    fi
    printf "\e[0m"

    test_matches=$(echo {'interactive ',}"non-interactive")
    
    if [[ " ${test_results[*]} " =~ $test_matches ]]; then
        printf "\e[32;2m%s (\e[4m%s\e[24m)\e[0m\n" "  PASSED" \
            "$test_matches"
    else
        printf "\e[31;1m%s (\e[4m%s\e[24m)\e[0m\n" "  FAILED" \
            "${test_results[*]}"
        ((failed_tests++))
    fi
done

if [[ $failed_tests -eq 0 ]]; then
    printf "\n\e[32;1m%s\e[0m\n" \
        ">> ALL ${LOCAL_TESTING:+LOCAL }TESTS WERE PASSED SUCCESSFULLY <<"
    exit 0
fi

exit 1