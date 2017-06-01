# Print array definition to use with assignments, for loops, etc.
#   varname: the name of an array variable.
use_array() { # 
    local r=$( declare -p $1 )
    r=${r#declare\ -a\ *=}
    # Strip keys so printed definition will be a simple list (like when using
    # "${array[@]}").  One side effect of having keys in the definition is
    # that when appending arrays (i.e. `a1+=$( use_array a2 )`), values at
    # matching indices merge instead of pushing all items onto array.
    echo ${r//\[[0-9]\]=}
}
# Same as use_array() but preserves keys.
use_array_assoc() { # VAR=([String,String]) -> IO
    local r=$( declare -p $1 )
    echo ${r#declare\ -a\ *=}
}

#Then, other functions can return an array using catchable output or indirect arguments.

# catchable output
return_array_by_printing() {
    local returnme=( "one" "two" "two and a half" )
    use_array $1
}
#declare -a myarray=([monday]=jam [tuesday]=potatoes [wednesday]=beans)
myarray=("myone" "mytwo" "my two and a half")
eval test1=$( return_array_by_printing myarray)

# indirect argument
return_array_to_referenced_variable() {
    local returnme=( "one" "two" "two and a half" )
    eval $1=$( use_array returnme )
}
return_array_to_referenced_variable test2

# Now both test1 and test2 are arrays with three elements

echo "test1 array, element 0: ${test1[0]}"
echo "test1 array, element 1: ${test1[1]}"
echo "test1 array, element 2: ${test1[2]}"

echo "test2 array, element 0: ${test2[0]}"
echo "test2 array, element 1: ${test2[1]}"
echo "test2 array, element 2: ${test2[2]}"
echo "==================================="
echo "${test1[@]}"
echo "${test2[@]}"
echo "${myarray[@]}"
echo "==================================="

#  Reads each two consecutive lines as key and value and 
f_Index_To_Associative() { # Array , Array -> [Line]
    local -n arr1=$1
    local -n arr2=$2
    echo "arr1: ${arr1[@]}"
    echo "arr2: ${arr2[@]}"
}

f_Associative_To_Index() {
    #for elem in $1
    echo ""
}

f_Index_To_Associative "test1" "test2"

f_get_New_Array() {
    foods=("beans" "Tofu" "sauce" "pie" "icecream")
    echo $foods
}

#  Faux Type Declarations:
#  Int
#  Char
#  String
#  [String]
#  Text
#  Bool

    
