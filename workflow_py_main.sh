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


cd $WORK_DIR
rm -fv $WORKFLOW_LOG_FILE

# Compute Forward Simulation
cd $WORK_DIR
workflow_py_forward.sh $PAR_INV $verbose 
check_status $?


# Compute windows, misfit and adjoint source
cd $WORK_DIR
account=Pra22_5560
nproc=32
narray=1
# Set up workflow python
workflow_py_setup.sh $PAR_INV $EVENT_FILE $account $nproc $narray $verbose
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

# Compute Direction

cd $WORK_DIR
workflow_py_compute_direction.sh $PAR_INV $OPT_METHOD $verbose
check_status $?

# Line Search

#copy model to RESULTS folder
cp -v $SIMULATION_DIR/DATA/GLL/model_gll.bp $RESULTS/model_gll_0.bp
workflow_py_linesearch.sh $PAR_INV $verbose

# Save Model

# Finalize iteration


log_status 0 $(basename $0)
exit 0


