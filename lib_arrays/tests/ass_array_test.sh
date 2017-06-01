#!/bin/bash



#  Add
people=("Anna" "Peter" "Tyler" "Snape")
f_array.AssocAppend() {
    local tag=$1 ; local value=$2 ; local personID=$3
if [ -n ${person[$personID]} ] ; then
    person[$personID]="${person[$personID]}$tag:$value"
else
    person[$personID]="$tag:$value"
fi
}
f_array.Append "number" "12345" "2"
f_array.Append "address" "garden avenue 123" "4"
declare -p person

echo "furst" "second" "and third"
printf '%s ' "furst" "second" "and third" "${person[@]}" 
: <<EOF




#  LibArray suggestions
#  Type checks
f_array.IsKeyValArray
f_array.IsIndexArray
f_array.IsArrayString
f_array.IsKeyValString


f_array.isSubset - http://wiki.bash-hackers.org/syntax/arrays
f_array.GetIndexOf
f_array.insert
f_array.Contains
f_array.Exist
f_array.Reverse
f_array.toAssoc
f_array.Rename - https://stackoverflow.com/questions/6660010/bash-how-to-assign-an-associative-array-to-another-variable-name-e-g-rename-t?noredirect=1&lq=1



Syntax Description

| Syntax                      | Description                                                                                 |
|-----------------------------+---------------------------------------------------------------------------------------------|
| Retrieval                   | Index-based values-retrieval                                                                |
|-----------------------------+---------------------------------------------------------------------------------------------|
| ${ARRAY[S]} and ${ARRAY[N]} | Expands to the value of the index S in the indexed or associative array ARRAY.              |
| ${ARRAY[-N]}                | Is treated as the offset from the maximum assigned index (can't be used for assignment) - 1 |
|-----------------------------+---------------------------------------------------------------------------------------------|
| Mass-Expansion              | Similar to mass-expanding positional parameters                                             |
|-----------------------------+---------------------------------------------------------------------------------------------|
| "${ARRAY[@]}"               | @ expands to all elements individually quoted                                               |
| "${ARRAY[*]}"               | * expands to all elements quoted as a whole.                                                |
| ${ARRAY[@]} and ${ARRAY[*]} | Expands to the same result                                                                  |
|-----------------------------+---------------------------------------------------------------------------------------------|
| Off-Set Expansion           | [[http://wiki.bash-hackers.org/syntax/pe#substring_expansion|Range-based values-retrieval]] |
|-----------------------------+---------------------------------------------------------------------------------------------|
| "${ARRAY[@]:N:M}"           | @ and * both expands as in Mass-Expansion                                                   |
| ${ARRAY[@]:N:M}             | N:M are integers representing Offset and Length respectively                                |
| "${ARRAY[*]:N:M}"           | if :M is omitted the expansion will be to the end of the string.			    |
| ${ARRAY[*]:N:M}             |                                                                                             |

| Parameter Expansion Syntax     | Outcome                 |
|--------------------------------+-------------------------|
| $*                             | $1 $2 $3 … ${N}         |
| $@                             | $1 $2 $3 … ${N}         |
| "$*"                           | "$1c$2c$3c…c${N}"       |
| "$@"                           | "$1" "$2" "$3" … "${N}" |
|--------------------------------+-------------------------|
| Range Of Positional Parameters |                         |
|--------------------------------+-------------------------|
| ${@:START:COUNT}               |                         |
| ${*:START:COUNT}               |                         |
| "${@:START:COUNT}"             |                         |
| "${*:START:COUNT}"             |                         |

''shift'' with no argument:
    $1 will be discarded
    $2 will become $1
    $3 will become $2
    …
    in general: $N will become $N-1
''shift 4'' shifts all arguments 4 "steps to the left", i.e. discards $1-$4 and $5 becomes $1, $6 becomes $2, $7 becomes $3, etc.

set "This is" my new "set of" positional parameters

# RESULTS IN
# $1: This is
# $2: my
# $3: new
# $4: set of
# $5: positional
# $6: parameters

Metadata
Syntax Description
${#ARRAY[N]} Expands to the length of an individual array member at index N (stringlength)
${#ARRAY[STRING]} Expands to the length of an individual associative array member at index STRING (stringlength)
${#ARRAY[@]}
${#ARRAY[*]}Expands to the number of elements in ARRAY
${!ARRAY[@]}
${!ARRAY[*]}Expands to the indexes in ARRAY since BASH 3.0

Syntax Description
unset -v ARRAY
unset -v ARRAY[@]
unset -v ARRAY[*] Destroys a complete array
unset -v ARRAY[N]Destroys the array element at index N
unset -v ARRAY[STRING]Destroys the array element of the associative array at index STRING

EOF
