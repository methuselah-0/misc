#!/bin/bash
declare -A array
array[foo]=fooval
array[bar]=barval

declare_Array()
{
    local -A days; days=([monday]=eggs [tuesday]=bread [sunday]=jam)
    printa "days"
}
printa ()
{   
    #"${!array[@]}"
    local -n arr=$1
    #local idx=$2
    #echo "${arr[$idx]}"
    for i in "${!arr[@]}" ; do
	printf '%s\n' "key  : $i"
	printf '%s\n' "value: ${arr[$i]}"
    done
}

#printa "days"
declare_Array
#printa "array"


printvar() {
    A1="ZZZ"
    V1="A"
    V2="1"
    VARNAME="$V1$V2"
    echo ${!VARNAME}
}

printvar2() {
    A1="ZZZ"
    V1="A"
    V2="1"
    VARNAME="$V1$V2"
    eval VALUE=\$$VARNAME
    echo $VALUE
}
echo "====================="
printvar
echo "====================="
printvar2
echo "====================="
#if `source arrayparser.sh --source-only` ; then echo "sourced true" ; exit 0 ; fi
