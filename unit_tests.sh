# NOTE: Each comment preceding a command should follow this format exactly:
# - One hash sign '#'
# - One white space
# - POSIX regular expression to be matched against the command's output
# - Everything on the line beside the initial '# ', including trailing white
#   spaces, becomes a part of the regular expression.
# - If two commands are mentioned after a single such comment, the expected
#   value pattern described by the comment is used for both commands.
# - These comments are no different, but since they are followed with a comment
#   that precedes the first actual command in the file, they the are overridden
#   and hence cause no harm.
# 
# There also must be a new line character at the end of the file, or otherwise,
# the last command will not be read.
  
# entrypoint ().*INVOKE=1 entrypoint
$prototype_binary | tee
# interactively-invoked
$prototype_binary
eval $($prototype_binary)
# non-interactively-invoked
eval $($prototype_binary) | tee
eval $($prototype_binary) > $dummy_file_path && cat $dummy_file_path
