#!/bin/bash

help()
{
cat <<EOF
lib_arrays.sh: lib_arrays.sh [OPTION]

    A library providing functions for reading, printing and piping
    arrays to and from some faux types for arrays: 

      FAUX-TYPE       STRING-FORMAT IS OUTPUT OF

      Array:          declare -p some_index_array

      Array-Ref:      the variable identifier String

      Array-String:   declare -p some_index_array | sed -e 's/^declare -a [^=]*=//'

      Key-Val:        declare -p some_associative_array

      Key-Val-Ref:    the variable identifier String

      Key-Val-String: declare -p somearray | sed -e 's/^declare -A [^=]*=//'

      Matrix-String:  not yet. Will be some vector type.
    
    Options:

      --presentation  Print some examples to stdout.

      --help          Show this help

      --source-only   Use this option when importing the functions of
                      this library from other bash-scripts.

EOF
}

####################
# Standard Arrays  #
####################
f_get_Lines_To_Array-String()
{   #  |-[String] -> Array-String
    #IFS='\n'
    local -a Arr=()
    # read each input and add it to Arr
        #    while read -r line ; do #  -r says to read every line as is, absolutely no modification of text.
	#  Left : insert statement to the left, the hash gets number of elements=last index+1, i.e. last place in the array.
	#  Right: * outer ' are for saying here's the element.
	#         * " around $line is to preserve all whitespaces etc when the var is expanded.
	#         * ' around "$line" says to read the expansion exactly as is.
	#         * Using additional " around '"$line"' creates actual quotes being part of the element.
	#         * The "is junk" text is simply part of the string element that's inside the outer '.
	#         * Use: arr[${#arr[@]}]='"'"$line"'" is junk'; if you want quotes around.
        #	
    while IFS= read -r line; do  Arr[${#Arr[@]}]="$line"; done < ${1:-/dev/stdin}
    # output the array as a string in filtered declare format, i.e. Array-String format.
    declare -p Arr | sed -e 's/^declare -a [^=]*=//'
}

f_get_Array-String_To_Lines()
{   #  Array-String -> [String]
    #IFS='\n'
    if [ -z "$1" ] ; then
	read -r arg1
	local -a Arr1=${arg1}  # is enough
    elif [ -n "$1" ] ; then
	local -a Arr1="${1}"  # is NOT enough
    else printf '%s\n' "f_get_Array-String_To_Lines was called with bad input" ; exit 1 ; fi
    for strings in "${Arr1[@]}" ; do
	printf '%s\n' "$strings"
    done
}
f_get_Array-String-Ref_To_Array-String()
{
    if [ -z "$1" ] ; then
	read -r arg1
	local -a Arr1="${arg1}"
    elif [ -n "$1" ] ; then
	local -n arg1="$1" && local -a Arr1="${arg1}"  # is enough, nameref declaration necessary.
    fi
    declare -p Arr1 | sed -e 's/^declare -a [^=]*=//'
}

    

######################
# Associative Arrays #
######################
#  Filters out the declare -p part from a piped string in declare -p Array format.
f_get_Key-Val_To_Key-Val-String()
{   #  String -> Key-Val-String
    #  It's still called what it is because you should know you can't
    #+ pass arrays directly.
    if [ -z "$1" ] ; then
	read -r pipe
	printf '%s\n' "$pipe" | sed -e 's/^declare -A [^=]*=//'
    elif [ -n "$1" ] ; then
	printf '%s\n' "$1" | sed -e 's/^declare -A [^=]*=//'
    else printf '%s\n' "f_Key-Val_To_Key-Val-String was called with bad input" ; exit 1 ; fi
    unset pipe
}

#  Passed variable or pipe-string must be a reference to an
#  array. Returns valid Array-String.
f_get_Key-Val-Ref_To_Key-Val-String()
{   #  Array-Ref -> Array-String
    if [ -z $1 ] ; then
	read -r pipe
	declare -p $pipe | f_get_Key-Val_To_Key-Val-String
	#local -A arr="$ref"
    elif [ -n $1 ] ; then
	declare -p $1 | f_get_Key-Val_To_Key-Val-String
    else printf '%s\n' "f_get_Key-Val_To_Key-Val-String() was called with bad argument" ; exit 1 ; fi
}

f_get_Key-Val-String-Values_To_Lines()
{   #  Key-Val-String -> [String]
    if [ -z "$1" ] ; then
	read -r arg1
	local -A Array="$arg1"
    elif [ -n "$1" ] ; then
	local -A Array="$arg1"
    else printf '%s\n' "f_get_Array-String_To_Lines was called with bad input" ; exit 1 ; fi
    for value in "${Array[@]}" ; do
	printf '%s\n' "$value"
    done
}

f_get_Present_Key-Val()
{   #  Key-Val-String ->
    if [ -z "$1" ] ; then
	read -r arg1
	local -A Arr="$arg1"
    elif [ -n "$1" ] ; then
	local -A Arr="$1"
    else printf '%s\n' "f_get_Print_Key-Val was called with bad argument" ; exit 1; fi
    for i in "${!Arr[@]}" ; do
	printf '%s\n' "key  : $i"
	printf '%s\n' "value: ${Arr[$i]}"
    done
}

################################################################################
#
#  If we want pointers between arbitrary strings instead of delimiters
#  such as blankspace etc, we must use arrays or fuck around with null.
#
#  Question: array containing arrays, or key-val arrays containing key-val arrays?
#
#  1. Arrays containing arrays, exploration.
#
#    Pros:
#
#      * indexed means they can be easily ordered and traversed.
#
#      * causes a natural and simple tree-structure.
#
#      * All elements are both a value and a potential name-reference to an array. If name-reference is empty then it's just an element.
#
#  Example: 
#
#    ???
#
#
#
#  Key-Val arrays containing Key-Val arrays, exploration.
#
#    Idea 1:
#
#    1.0 keys with empty values are just arrays, unordered.
#
#    2.0 keys with non-empty values, have a value that is:
#       2.1. if key!=value, then it's just a value.
#       2.2. if key=value, then it's a reference to the name of a child with the name of this key=value.
#         2.2.1 if values of the keys of this child-array are empty, then it's just an array and this child's keys represent together the multiple values of the key with the same name as this array in its parent.
#         2.2.2 if values are non-empty we ask question number 2.0 above.
#
#  Key1=array-name, Val1=Key-Val-String?
#
#    Idea 2:
#
#    use only Key-Val Arrays and let values, if they are of type Key-Val, always be on the format of the output of declare -p.
#
#    f_array.Insert() checks for declare -a and declare -A before inserting.
#
#    then implement a sort functions:
#
#      * f_array.SortKeys()
#      * f_array.SortValues()
#      * f_array.Find() which recursively searches a string-value by checking for declare -A strings in the values.




#
#
#  Example (old): 
#
#    Key-Val-Name: myhouse       Level: 0
#    Key1        : living room   Type: String
#    Val1        : clauset       Type: Array-Reference
#    Key2        : bedroom
#    Val2        : bed1-beddings

#    Key-Val-Name: living room
#    Key1        : clauset
#    Value1      : shelf1
#    Key2        : decorations
#    Value2      : bucket-flowers


# TO-DO
f_get_Array_Pipe()
{   #  String , String , |-String -> [String] / String
    #  Meanings (long forms are not valid options):
    #  
    #      -kvr  --key-value-reference
    #      -kv   --key-value
    #      -kvs  --key-value-string
    #      -kvvs --kev-value-values-strings
    #      -ar   --array-reference
    #      -a    --array
    #      -as   --array-string
    #      -asv  --array-string-values
    #  Valid options:
    #      -kvr   -kv
    #      -kv(r) -kvs
    #      -kv(r) -kvvs
    #      -kv(r) -kvks
    #      -kv(r) --print
    #      -ar    -a
    #      -a(r)    -as
    #      -
    if [ -z "$1" ] || [ -z "$2" ] ; then
	printf '%s\n' "f_get_Array_Format: need flags for from-format and to-format."
    elif [ "$1" == "-kv" ] ; then
	case $2 in
	    "-kvs" )
	 	f_get_Key-Val_To_Key-Val-String $2
		;;
	    "-" ) echo "blub"
	esac;
    elif [ $2 == "-" ] ; then
	printf '%s\n' "hej"
    elif [ "$1" == "-kvr" ] ; then
	printf '%s\n' "hej"
    fi
}


###########################################
#                                         #
#            Zip functions                #
#                                         #
###########################################


#  Alternating Key-Value as lines in text is a way to store associative arrays.
f_get_Zip_Alt_Lines_To_Key_Val()
{   # Text Text -> Array-String
    local -i i=0
    local -n Arr1=$1
    local -n Arr2=$2
    while IFS= read -r $3 ; do # no need to restore IFS.
	if [ i=0 ] ; then
	    line=$REPLY
	    i=1
	elif [ i=1 ] ; then
	    line=$REPLY
	    i=0
	fi
    done ;
}

f_get_Zip_Files_To_Key_Val()
{   # Text , Text -> Key-Val-String
    printf '%s\n' "f_get_Zip_Files_To_Key_Val() is not yet implemented"
    exit 1
}


############################################
#                                          #
#    Matrices & Multidimensional Arrays    #
#                                          #
############################################

#  Problem to solve: One item have properties which in turn have properties.
#
#    Key has a value. All values are in turn keys with a value. The end of the recursion is an empty value.
#
#  Subproblems:
#
#      Putting a Key-Val-String as value in a Key-Val (Associative array)
#      
#      Should probably start writing with arguments being flags or options and then reading from actual 
#      
#      


#  (bad) idea: add a way to insert "another" value to a key, and to define the preferred operator.

#  Put "Array-String" as value in an array, since it is properly formatted.

#  A multi-dimensional array with arbitrary values can be created with a key-val-array where the key is simply a base index and the value is a regular indexed array.

#  Idea is to recursively traverse arrays for a given array and print
#  them in a tree structure similar to "tree -L $X"
#  show_array()


#  Dunno about keeping this one.
#  
f_get_Empty_Matrix()
{   #  Int , Int -> Matrix
    local -A matrix
    num_rows=$1
    num_columns=$2

    #  Build the matrix array
    for ((i=1;i<=num_rows;i++)) ; do
	for ((j=1;j<=num_columns;j++)) ; do
	    matrix[$i,$j]=$RANDOM
	done
    done

    #  Some flashy printing. Source: https://stackoverflow.com/questions/16487258/how-to-declare-2d-array-in-bash/16487733#16487733
    #  Don't know the %s stuff.
    f1="%$((${#num_rows}+1))s"
    f2=" %9s"  # What is this?
    printf "$f1" ''
    
    for ((i=1;i<=num_rows;i++)) ; do
	printf "$f2" $i
    done
    printf '%s\n'
    
    for ((j=1;j<=num_columns;j++)) ; do
	printf "$f1" $j
	for ((i=1;i<=num_rows;i++)) ; do
	    printf "$f2" ${matrix[$i,$j]}
	done
	printf '%s\n'
    done
}

f_get_Build_Matrix_Array()
{   #  Int , Int -> Key-Val-String
    local -A matrix 
    num_rows=$1 # or set to lines in $1 txt file
    num_columns=$2 # or set to lines in $2 txt file
    for ((i=0;i<num_rows;i++)) ; do
	for ((j=0;j<num_columns;j++)) ; do
	    matrix[$i,$j]=''
	done
    done
    declare -p matrix | sed -e 's/^declare -A [^=]*=//'
}


#eval "declare -a returned_array=${array_string}" # eval is superflous    
#returned_array=${array_string} # is not enough

if [ "${1}" == "--source-only" ] ; then
    return 0 ;
elif [ "$1" == "--help" ] ; then
    help

#  This presentation should be updated with some select-options.
elif [ "$1" == "--presentation" ] ; then
    ./lib_arrays_test.sh
else printf '%s\n' "run with --help to see a list of options." ; exit 1 ; fi
    
# Problem: how to pass array around arrays - a string format? namereferences?
    # 1. for NUL-delimited streams etc. http://mywiki.wooledge.org/BashFAQ/005#Reading_NUL-delimited_streams
    # 2. Since Bash 4.3-alpha, read skips any NUL (ASCII code 0) characters in input. http://wiki.bash-hackers.org/commands/builtin/read
    # 3. printf -v http://mywiki.wooledge.org/BashFAQ/006
    # 4. Array formats can perhaps be read with declare -p ouput. Considerdeclare -a and declare -p something for passing around "array-formatted" strings. Would like to pipe it. 

#arr=('my' 'array')
#declare -A arr2; arr2=(["key1"]="val1" ["key2"]="val2")
#declare -p $arr
#declare -p $arr2

#  Consider: Always use export statement for array variable immediately prior to calling an array function which then uses "local -n arr=$1"

#makeArray()
#{   #  Array-Name Array-String -> Var-Set
#    local -n arr=$1
#    eval "arr=${!$2}"
#}
