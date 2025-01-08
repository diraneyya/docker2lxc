function docker2lxc {
  if ps -o comm= $PPID | grep -q sshd; then SSH=1; fi
  if [ -z "$1" ]; then
    printf >&2 "\e[34;1mUsage:\e[22m %s \e[2;33;4m<image>\e[24m \e[4m<template.tar.gz>\e[0m\n" $0
    return 0
  fi
  # test -z "$SSH" && \
  echo >&2 -e "\e[33m-> Pulling Docker container '$1'...\e[0m"
  docker pull $1 >&2
  if [[ $? -ne 0 ]]; then 
    echo >&2 "\e[31m  Container '$1' not found, aborting\e[0m"
    return 1
  fi
  docker_container=$(docker run --rm --entrypoint sh -id $1)
  if [[ $? -ne 0 ]]; then 
    echo >&2 "\e[31m  Incompatible container '$1' detected, aborting\e[0m"
    return 2
  fi
  docker_container=${docker_container:0:12}
  if [ -z "$SSH" ]; then
    output_file=${2:-template}
    output_file=${output_file%.tar.gz}.tar.gz
  fi
  # test -z "$SSH" && \
  echo >&2 -e "\e[33m-> Exporting root filesystem to '${output_file:-stdout}'...\e[0m"
  if [ -z "$output_file" ]; then
    docker export $docker_container | gzip >&1
  else 
    docker export $docker_container | gzip > $output_file
  fi
  # test -z "$SSH" && \
  echo >&2 -e "\e[33m-> Killing running container...\e[0m"
  docker kill $docker_container >/dev/null
  # test -z "$SSH" && \
  echo >&2 -e "\e[32;1mDone\e[0m"
}
