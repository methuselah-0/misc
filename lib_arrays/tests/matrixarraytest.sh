#!/bin/bash
#  Source: https://stackoverflow.com/questions/26634978/how-to-use-readarray-in-bash-to-read-lines-from-a-file
#  Represent the following table in an associative array:
#  1 2 3
#  4 5 6
#  7 8 9

source lib_arrays.sh --source-only

f_get_Matrix_Array()
{
    declare -A matrix
    declare -a a=( $2 )
    # For as long as c is less than the length of the array.
    for (( c=0; c < ${#a[@]}; c++ ))
#    for (( c=0; c < "${#a[@]"; c++ ))
    do
	#  Insert at [
	matrix[$1,$c]=${a[$c]}
    done
    declare -p matrix
}
#  C=callback c=quantum sets number of lines per callback.
#  \n delimits rows starting from row 0.
#  ' ' delimits columns starting from column 0.

readarray -C f_get_Matrix_Array -c 1 <<< $'1 2 3\n4 5 6\n7 8 9' 

f_get_Build_Matrix_Array 3 3
	    
