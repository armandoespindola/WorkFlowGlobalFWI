#!/bin/bash

trap " check_status 1 $(basename $0) " ERR

#<2022-03-20 Sun>

#

if [ $# -lt 2 ]; then
    echo "usage: ./workflow_py_clean.sh PAR_INV[file] verbose[false==0/true==1]"
    exit 1
fi


PAR_INV=$1
WIN=$2
verbose=$3

folder=("converter"
           "proc"
           "measure"
           "stations"
           "filter"
           "adjoint"
           "weights"
           "sum_adjoint"
	   "seis/proc"
       "seis/raw" )

if [ $WIN -eq 1 ]; then 
    folder[${#folder}]="windows"
fi


# Loading env variables
. workflow_py_load_config.sh  $PAR_INV $verbose
check_status $?

for ifolder in ${folder[@]}; do

    cd $WORKFLOW_DIR
    cd $ifolder

    if [ ! -z "$verbose" ]; then
	echo "Cleaning folder: $ifolder"
    fi
    

    rm -f *.*~
    rm -f *.h5
    rm -f *.o
    rm -f *.sh

    if [ -d "paths" ];then rm -vrf paths/* ; fi
    if [ -d "figures" ];then rm -vrf figures/* ; fi
    if [ -d "output" ];then rm -vrf output/* ; fi

    cd ../
done

check_status 0 $(basename $0)
exit 0

    
    
