#!/bin/bash

trap " check_status 1 $(basename $0)  " ERR

if [ $# -lt 3 ]; then echo "usage: ./workflow_py_forward.sh PAR_INV SAVE_FORWARD[false==0/true==1] verbose[false==0/true==1]"; exit 1; fi

PAR_INV=$1
SAVE_FORWARD=$2
verbose=$3



# Loading env variables
. workflow_py_load_config.sh $PAR_INV $verbose
check_status $?

cd $WORK_DIR
workflow_py_compile_binaries.sh $PAR_INV 1 2 1
check_status $?

cd $WORK_DIR
workflow_py_mesher.sh $PAR_INV $verbose
check_status $?

events_list=$(grep -v ^# "${WORKFLOW_DIR}/${EVENT_FILE}")
events=$(echo $events_list | sed "s/[a-z]0*//g"  | sed "s/ /,/g")

cd $SIMULATION_DIR

# Check if events folders exist
for ievent in $events_list
do
    if [ ! -d $ievent ]; then echo "Event folder -> $ievent not found"; exit 1;fi
done

if [ $SAVE_FORWARD -eq 1 ]; then 
    cp DATA/Par_file DATA/Par_file.org
    ./change_simulation_type.pl -F
else
    ./change_simulation_type.pl -f
fi

copy_mesh2events.sh "${WORKFLOW_DIR}/${EVENT_FILE}"  $verbose
check_status $?

if [ $? -ne 0 ]; then echo " Mesh error "; exit 1; fi


# DO NOT FORGET TO QUOTE THE JOB VARIABLE
# slurm_monitor.sh "$SBATCH_FORWARD" "$events_list" $verbose
# check_status $? "$SBATCH_FORWARD"
cd $WORK_DIR
workflow_py_multiple_runs.sh $PAR_INV "forward" $verbose
check_status $?


if [ $SAVE_FORWARD -eq 1 ]; then 
    cd $SIMULATION_DIR
    mv DATA/Par_file.org DATA/Par_file
    ./change_simulation_type.pl -F
fi


cd $WORK_DIR
check_status 0 $(basename $0)
exit 0
