#!/bin/bash

trap " check_status 1 $0 "  ERR

if [ $# -lt 2 ]; then echo "usage: ./workflow_py_adjoint.sh PAR_INV verbose[false==0/true==1]"; exit 1; fi

PAR_INV=$1
verbose=$2


# Loading env variables
. workflow_py_load_config.sh  $PAR_INV $verbose

workflow_py_compile_binaries.sh $PAR_INV 1 2 1
check_status $?

nevent=$(grep -v ^# ${WORKFLOW_DIR}/${EVENT_FILE} | wc -l)

cd $SIMULATION_DIR

copy_mesh2events.sh "${WORKFLOW_DIR}/${EVENT_FILE}"  $verbose
check_status $?

cd $WORK_DIR

workflow_py_copy_adjoint.sh $PAR_INV $verbose
check_status $?

if [ $? -ne 0 ]; then echo " Mesh error "; exit 1; fi

cd $SIMULATION_DIR

sed -i "s/--array=.*/--array=[1-${nevent}]/" $SBATCH_ADJOINT

# DO NOT FORGET TO QUOTE THE JOB VARIABLE
slurm_monitor.sh "$SBATCH_ADJOINT" $nevent $verbose
check_status $? "$SBATCH_ADJOINT"

check_status 0 $(basename $0)
exit 0
