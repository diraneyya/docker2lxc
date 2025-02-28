# THIS FILE IS NOT EXECUTED DIRECTLY BUT PARSED BY THE TESTS RUNNER SCRIPT
# ------------------------------------------------------------------------------
# Each one of the comments preceding a command below must follow this exact,
# and rigid format to simplify the implementation:
# - One hash sign character '#' at the very beginning of the line
# - A single white space character following the initial '#' character
# - A POSIX regex afterwards, which is matched against the command's output
# - Everything until the end of the line, including any trailing whites spaces,
#   becomes a part of the regular expression.
# - All commands following the comment, with no other comments in between, will
#   have the regex in the comment matched against their output.
# - These comments here are no different, and are parsed accordingly, however,
#   since they are not the last to precede the first command in this file, they 
#   are "overridden" or superseded by the value of the last comment before the
#   command, and hence cause no harm.
# 
# Finally, please be aware that there MUST be a new line character "\n" at the 
# end of this file, or otherwise, the last test command will not be used.
# ------------------------------------------------------------------------------
# ENV variables:
# - "$unit_executable": this is the executable we are testing in these specs.
# ------------------------------------------------------------------------------
#
# entrypoint ().*INVOKE=1 entrypoint
$unit_executable | tee
# interactively-invoked
$unit_executable
eval $($unit_executable)
# non-interactively-invoked
eval $($unit_executable) | tee
eval $($unit_executable) > /tmp/dummy && cat /tmp/dummy
