#!/usr/bin/env sh

if command -v bash 1>/dev/null 2>&1; then
    # bash is already installed and available inside the container
    :
else
    # we must install 'bash' which is the shell used by the unit under
    # test, which in the case here, is the prototype executable.
    if command -v apk 1>/dev/null 2>&1; then
        apk add bash 1>/dev/null 2>&1
    elif command -v apt 1>/dev/null 2>&1; then
        apt update 1>/dev/null 2>&1
        apt install -y bash 1>/dev/null 2>&1
    fi
fi

# after changing the architecture of this tester, the orchestrator is
# no longer copied into the container, instead, we delegate the task
# of running a single test command to the entrypoint script (this one)
# by passing the desired command as an argument. Note that the desired
# command will be able to reference the prototype executable, which is
# copied into the container by the the same orchestrator (now living 
# outside of the docker container) as the one passing the argument $*
echo "#!/usr/bin/env sh" > /tmp/test_command.sh
echo "$*" >> /tmp/test_command.sh
chmod +x /tmp/test_command.sh
. /tmp/test_command.sh

# one thing to keep in mind is that in this case, the test command is
# is stored in memory whereas the prototype might be copied elsewhere
# this is not important and functionality should not be affected