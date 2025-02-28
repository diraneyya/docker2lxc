#!/usr/bin/env sh

if command -v bash &>/dev/null; then
    :
else
    if command -v apk &>/dev/null; then
        apk add bash &>/dev/null
    elif command -v apt &>/dev/null; then
        apt update &>/dev/null
        apt install -y bash &>/dev/null
    fi
fi

/app/prototype
/app/prototype | tee
/app/prototype >> /app/test.log