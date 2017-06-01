#!/bin/bash

source lib_arrays.sh --source-only

array_test()
{   #
    printf '%s\n' "running array_test"
    local -A First;
    local -A Second=([key1]='one' [key2]='two' [key3]='three')
    Second_String=`declare -p Second | f_get_Key-Val_To_Key-Val-String`
    First=([something]=0)
    First+=([second_string]=$Second_String)
    declare -p First
}

f_do_Working_Examples()
{   #  -> IO , [String] 
    array_string="$( f_get_Junk_Lines | f_get_Lines_To_Array-String )"
    printf '%s\n' "=================="
    printf '%s\n' "Things which work"

    printf '%s\n' "== An array_string: =="
    printf '%s\n' "$array_string"

    printf '%s\n' "=================="

    printf '%s\n' "== f_get_Array-String-Ref_To_Array-String \$array_string =="
    f_get_Array-String-Ref_To_Array-String "array_string"

    printf '%s\n' "=================="

    printf '%s\n' "== cat text.txt =="
    cat text.txt

    printf '%s\n' "=================="

    printf '%s\n' "== var=\`cat text | f_get_Lines_To_Array-String\` =="
    var=`cat text.txt | f_get_Lines_To_Array-String`

    printf '%s\n' "== printf '%s\n' \"\$var\" =="
    printf '%s\n' "var: $var"

    printf '%s\n' "=================="

    printf '%s\n' "== f_get_Array-String_To_Lines \$var: =="
    f_get_Array-String_To_Lines "$var"

    printf '%s\n' "=================="

    printf '%s\n' "== \$( cat text.txt | f_get_Lines_To_Array-String ) | f_get_Array-String_To_Lines =="
    f_get_Array-String_To_Lines "$(cat text.txt | f_get_Lines_To_Array-String)"

    printf '%s\n' "=================="

    printf '%s\n' "== f_get_Array-String_To_Lines \"\$var\" > text2.txt =="
    f_get_Array-String_To_Lines "$var" > text2.txt

    printf '%s\n' "== \`diff -s text.txt text2.txt\` =="    
    printf '%s\n' "`diff -s text.txt text2.txt`"

    printf '%s\n' "=================="
    printf '%s\n' "== cat text.txt | f_get_Lines_To_Array-String | f_get_Array-String_To_Lines =="
    cat text.txt | f_get_Lines_To_Array-String | f_get_Array-String_To_Lines
}

# Stuff that doesn't work:
f_do_Mistake_Examples()
{   #  -> IO , [String]
    printf '%s\n' "=================="
    printf '%s\n' "Things which don't work"
    printf '%s\n' "=================="
    printf '%s\n' "no examples yet"
}

f_get_Junk_Lines()
{   #  -> [String]
    printf '%s\n' 'this is junk'
    printf '%s\n' '#more junk \n and "b@d" characters!'
    printf '%s\n' '!#$^%^&(*)_^&% ^$#@:"<>?/.,\\""'
    printf '%s\n' "We still can't put ' and \" in the text how we want when using printf '%s\n' \"some-text\""
    printf '%s\n' "read -r works with EVERYTHING piped from a txt-file."
    printf '%s\n' "We might be able to put text freely inside printf '%s\n' if we temporarily edit the IFS to use the null-delimiter"
}

#array_test
f_do_Working_Examples

printf '%s\n' "== declare -A days; days=([monday]=eggs [tuesday]=bread [sunday]=jam) =="
declare -A days; days=([monday]=eggs [tuesday]=bread [sunday]=jam)
printf '%s\n' "== f_get_Key-Val-Ref_To_Key-Val-String \"days\" | f_get_Key-Val-String-Values_To_Lines =="
f_get_Key-Val-Ref_To_Key-Val-String "days" | f_get_Key-Val-String-Values_To_Lines
printf '%s\n' "== f_get_Key-Val-Ref_To_Key-Val-String \"days\" | f_get_Present_Key-Val =="
f_get_Key-Val-Ref_To_Key-Val-String "days" | f_get_Present_Key-Val



printf '%s\n' "== f_get_Junk_Lines | f_get_Lines_To_Array-String | f_get_Array-String_To_Lines =="
f_get_Junk_Lines | f_get_Lines_To_Array-String | f_get_Array-String_To_Lines

array=`f_get_Junk_Lines | f_get_Lines_To_Array-String`

printf '%s\n' "== f_get_Array-String-Ref_To_Array-String \"array\" =="
f_get_Array-String-Ref_To_Array-String "array"


