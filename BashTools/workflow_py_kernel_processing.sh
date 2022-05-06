#!/bin/bash

trap " check_status 1 $(basename $0)  " ERR

function create_event_file_specfem(){

    local event_file="${WORKFLOW_DIR}/${EVENT_FILE}"
    if [ ! -e $event_file ]; then echo "No $event_file file found. Please check!" ; exit 1; fi
    nevent=$(grep -v ^# $event_file | wc -l)
    events=($(grep -v ^# $event_file))

    echo $nevent > $1
    for ievent in ${events[@]}
    do
	local name_file="kernels.bp"
	local path="$SIMULATION_DIR/${ievent}/OUTPUT_FILES/$name_file"
	echo "1.0" >> $1
	echo $path >> $1
    done
    

    }

if [ $# -lt 2 ]; then
    echo "This program executes Kernel Processing"
    echo "usage: ./workflow_py_kernel_processing.sh PAR_INV verbose[false==0/true===1]"
    exit 1
fi


PAR_INV=$1
verbose=$2

# Loading env variables
. workflow_py_load_config.sh $PAR_INV $verbose



if [ ! -d $RESULTS ]
then
    mkdir -p $RESULTS
else
    rm -f "$RESULTS"/*
fi
       

# GPU KERNEL SMOOTHING

SOLVER_FILE="$SIMULATION_DIR/DATABASES_MPI/solver_data.bp"

if [ ! -e $SOLVER_FILE ]; then echo "$SOLVER_FILE not found"; exit 1; fi



# Create Event File
cd $WORK_DIR
create_event_file_specfem $KERNEL_SUM_INPUT


cd $SIMULATION_DIR

# Create Sbatch File
cp "$SBATCH_KERNEL.template" $SBATCH_KERNEL

# Kernel Sum
sed -i "s|:event_file:|$KERNEL_SUM_INPUT|g" $SBATCH_KERNEL
sed -i "s|:output_file:|$KERNEL_SUM_OUTPUT|g" $SBATCH_KERNEL

# Kernel Smoothing

sed -i "s/:SIGMA_H:/$SIGMA_H/g" $SBATCH_KERNEL
sed -i "s/:SIGMA_V:/$SIGMA_V/g" $SBATCH_KERNEL
sed -i "s/:KERNEL_NAME:/$KERNEL_NAME/g" $SBATCH_KERNEL
sed -i "s|:INPUT_FILE:|$KERNEL_SMOOTH_INPUT|g" $SBATCH_KERNEL
sed -i "s|:SOLVER_FILE:|$SOLVER_FILE|g" $SBATCH_KERNEL
sed -i "s|:OUTPUT_FILE:|$KERNEL_OUTPUT_FILE|g" $SBATCH_KERNEL
sed -i "s/:GPU_MODE:/$GPU_MODE/g" $SBATCH_KERNEL




job=$(sbatch $SBATCH_KERNEL)
slurm_monitor.sh "$SBATCH_KERNEL" 1 $verbose
check_status $? "$SBATCH_KERNEL"

check_status 0 $(basename $0)
exit 0
