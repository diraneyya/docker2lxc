#!/usr/bin/env sh

if command -v bash >/dev/null 2>&1; then
    :
else
    if command -v apk >/dev/null 2>&1; then
        apk add bash >/dev/null 2>&1
    elif command -v apt >/dev/null 2>&1; then
        apt update >/dev/null 2>&1
        apt install -y bash >/dev/null 2>&1
    fi
fi

protopath=${1:-.}
protopath=${protopath%/}

$protopath/prototype
$protopath/prototype | tee
$protopath/prototype > $protopath/test.log && \
    cat $protopath/test.log && rm $protopath/test.log