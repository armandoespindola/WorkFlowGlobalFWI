#!/bin/bash

trap " log_status 1 $(basename $0) "  ERR


if [ $# -lt 2 ]
then
    echo "Usage: ./workflow_py_main.sh PAR_INV[file] verbose[false==0/true==1]"
    exit 1
fi


PAR_INV=$1
verbose=$2


# Loading env variables and utilities
. workflow_py_load_config.sh  $PAR_INV $verbose

if [ -d $RESULTS ]; then
    echo -n "The $(basename $RESULTS) folder already exists. Do you want to overwrite it? [y/n] "
    read flag

    if [ $flag == "y" ]; then
	echo "Removing data from folder $(basename $RESULTS)"
    elif [ $flag == "n" ]; then
	echo "Please copy your data from $(basename $RESULTS) to another folder "
	exit 1
    else
	echo " This is not and option "
	exit 1
    fi
fi


if [ ! -d $RESULTS ]
then
    mkdir -p $RESULTS
else
    rm -f "$RESULTS"/*
fi
	
cd $WORK_DIR
rm -fv $WORKFLOW_LOG_FILE
    

# Compute Forward Simulation
cd $WORK_DIR
workflow_py_forward.sh $PAR_INV $verbose 
check_status $?


# Compute windows, misfit and adjoint source
cd $WORK_DIR

# Set up workflow python
workflow_py_setup.sh $PAR_INV $verbose
check_status $?

# Runs WorkFlow
cd $WORK_DIR
WIN=1
workflow_py_run.sh $PAR_INV $WIN $verbose
check_status $?


# Compute kernels

cd $WORK_DIR
workflow_py_adjoint.sh $PAR_INV $verbose
check_status $?

# Preprocesing Kernels and Compute Direction

cd $WORK_DIR
workflow_py_kernel_processing.sh $PAR_INV $verbose
check_status $?
exit 0
# Compute Direction

cd $WORK_DIR
workflow_py_compute_direction.sh $PAR_INV $OPT_METHOD $verbose
check_status $?


# Line Search

#copy model to RESULTS folder
workflow_py_linesearch.sh $PAR_INV $verbose
check_status $?

# Finalize iteration
workflow_py_finalize.sh $PAR_INV $verbose
check_status $?

log_status 0 $(basename $0)
exit 0


