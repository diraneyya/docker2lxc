#!/usr/bin/env bash

# Test orchestrator/runner paths and configuration
host_path=.
container_path=/app
container_path=${container_path%/}

test_specs_file=$host_path/test-specs.sh
# this ENV variables will be used to compile the unit test command into a
# line that can be passed to the entrypoint script inside the container.
export unit_executable=$container_path/prototype

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

# keep track of failed test suites
failed_test_suites=0

for (( i=0; i<array_length; i++ )); do
    printf "\e[34;1m%s\e[0m\n" "Testing under ${docker_images[i]}..."
    
    # count the failing tests inside of each suite
    failed_tests=0
    passed_tests=0

    while IFS= read -r line
    do
        if [[ "$line" =~ ^'#' ]]; then
            if [[ "$line" =~ ^'# ' ]]; then
                expected_output=${line#'# '}
            fi 

            continue
        fi

        # do not mistake empty lines for commands that need testing
        if [[ -z "${line//[[:space:]]/}" ]]; then continue; fi

        parsed_line="$(echo -n "$line" | envsubst)"
        # execute the parsed line using the entrypoint which is copied along
        # with the unit executable into the container (check .dockerignore)
        docker run --rm -t -v .:$container_path \
            --entrypoint $container_path/test-entrypoint.sh \
            "$image:$tag" "$parsed_line" > $host_path/test.log

        # I certainly need to improve my bash skills because this looks FUGLY!
        command_output=$(cat $host_path/test.log | \
            tr "\t\v\r\n" "    " | sed 's/  */ /g') && rm $host_path/test.log

        # show each command first
        printf "\e[34;2m- command: '\e[4m%s\e[24m'\e[0m\n" "$command_output"

        # followed by either the success or the failure with the matching
        if [[ $command_output =~ $expected_output ]]; then
            printf "\e[32;2m  + [\e[4m%s\e[24m] %s (given) == %s (expected)\e[0m\n" \
                "PASSED" "$command_output" "$expected_output"
            ((passed_tests++))
        else
            printf "\e[31;1m  + [\e[4m%s\e[24m] %s (given) == %s (expected)\e[0m\n" \
                "FAILED" "$command_output" "$expected_output"
            ((failed_tests++))
        fi
        
    done < "$test_specs_file"
    
    if [[ $failed_tests -eq 0 ]]; then
        printf "\e[32;2m%s (\e[4m%s\e[24m)\e[0m\n" "TEST SUITE PASSED" \
            "$passed_tests tests"
    else
        printf "\e[31;1m%s (\e[4m%s\e[24m)\e[0m\n" "TEST SUITE FAILED" \
            "$passed_tests/$(($passed_tests + $failed_tests)) tests passed"
        ((failed_tests++))
    fi
done

if [[ $failed_test_suites -eq 0 ]]; then
    printf "\n\e[32;1m%s\e[0m\n" \
        ">> ALL TESTS WERE PASSED SUCCESSFULLY <<"
    exit 0
fi

exit 1
