#!/bin/bash

# This program sets environment variables for modules inversion


if [ $# -lt 2 ]; then echo "usage: ./workflow_py_load_config.sh PAR_INV[file] verbose[false==0/true==1]"; exit 1; fi

PAR_INV=$1
verbose=$2

if [ ! -e $PAR_INV ]; then
    echo "$PAR_INV not found. Please check!"
    exit 1
fi


# Load Vars
. $PAR_INV

# Load Utilities
if [ -z "$__utils__" ]
then
    export __utils__=1
    export utils="$(dirname $0)/utils/utils.sh"
    . "$utils"
fi


if [ ! -e $KERNEL_PARFILE ]; then
    echo "KERNEL PARFILE: $KERNEL_PARFILE  not found. Please check!"
    exit 1
fi

VARS=($(grep -v ^#  $PAR_INV))

echo 
echo "############# CONFIG FILE ##############"
for ivars in ${VARS[@]}
do
    echo $ivars
done
echo "Utilities : " $utils
echo

