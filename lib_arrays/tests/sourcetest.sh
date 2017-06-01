#!/bin/bash
source new_luks_lvm_backup.sh --source-only

echo "sourcetest can use the sourcable_var var if it prints here: ${sourcable_var}"
echo $SDEV
f_do_review_source_device_info 
