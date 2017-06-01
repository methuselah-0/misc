FP='/tmp/source.sh'     # path to file to be created for `source`ing
cat <<EOF
 'EOF' > "${FP}"  # suppress interpretation of variables in heredoc
function make_junk {
   echo 'this is junk'
   echo '#more junk and "b@d" characters!'
   echo '!#$^%^&(*)_^&% ^$#@:"<>?/.,\\"'"'"
}

### Use 'readarray' (aka 'mapfile', bash built-in) to read lines into an array.
### Handles blank lines, whitespace and even nastier characters.
function lines_to_array_representation {
    local -a arr=()    
    readarray -t arr
    # output array as string using 'declare's representation (minus header)
    declare -p arr | sed -e 's/^declare -a [^=]*=//'
}
EOF

FP1='/tmp/junk1.sh'      # path to script to run
cat <<EOF
 'EOF' > "${FP1}"  # suppress interpretation of variables in heredoc
#!/usr/bin/env bash

source '/tmp/source.sh'  # to reuse its functions

returned_string="$(make_junk | lines_to_array_representation)"
eval "declare -a returned_array=${returned_string}"
for elem in "${returned_array[@]}" ; do
    echo "${elem}"
done
EOF
chmod u+x "${FP1}"
# newline here ... just hit Enter ...
EOF
EOF
