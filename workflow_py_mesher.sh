#!/bin/bash

trap " check_status 1 $(basename $0)  " ERR

if [ $# -lt 2 ]; then echo "usage: ./workflow_py_mesher.sh PAR_INV verbose[false==0/true==1]"; exit 1; fi
# This program run the mesher for specefem
PAR_INV=$1
verbose=$2

# Loading env variables

. workflow_py_load_config.sh $PAR_INV $verbose
check_status $?

#workflow_py_compile_binaries.sh $PAR_INV 1 1 1
nevent=1

cd $SIMULATION_DIR

job=$(sbatch $SBATCH_MESHER)

slurm_monitor.sh "$job" 1 $nevent $verbose
check_status $? "$SBATCH_MESHER" 

check_status 0 $(basename $0)
exit 0
