#!/usr/bin/env bash

# this one will be combined with the original orchestrator soon, but for now
# let us mock the first part using an $image and a $tag

image=ubuntu
tag=latest

host_path=${1:-.}
host_path=${host_path%/}
container_path=/app
container_path=${container_path%/}

test_specs_file=$host_path/test-specs.sh
# the ENV variables which will be used to cast the unit test command into a
# line that can be passed to the entrypoint script inside the container.
export unit_executable=$container_path/prototype

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
        tr "\t\v\r\n" "    " | sed 's/  */ /g')

    echo "line: ${parsed_line@Q}"
    echo "- outcome: $command_output"
    echo "- expected: $expected_output"
    if [[ $command_output =~ $expected_output ]]; then
        echo "PASS"
    else
        echo "FAIL"
    fi
done < "$test_specs_file"