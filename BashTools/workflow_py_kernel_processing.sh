#!/bin/bash

trap " check_status 1 $(basename $0)  " ERR

function create_event_file_specfem(){
    local status=0
    local event_file="${WORKFLOW_DIR}/${EVENT_FILE}"
    if [ ! -e $event_file ]; then echo "No $event_file file found. Please check!" ; exit 1; fi
    nevent=$(grep -v ^# $event_file | wc -l)
    events=($(grep -v ^# $event_file))

    echo $nevent > $1
    echo $nevent > $2
    for ievent in ${events[@]}
    do
        local name_file="kernels.bp"
        local path="$SIMULATION_DIR/${ievent}/OUTPUT_FILES"
        echo "1.0" >> $1
        echo ${path}/$name_file >> $1
        echo "$SIMULATION_DIR/${ievent}/DATABASES_MPI" >> $2

	if [ ! -e "${path}/$name_file" ]; then
	    echo "File not found: ${path}/$name_file"
	    status=1
	fi
	
    done

    if [ $status -eq 1 ]; then
	exit 1
    fi
    
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

# GPU KERNEL SMOOTHING

SOLVER_FILE="$SIMULATION_DIR/DATABASES_MPI/solver_data.bp"

if [ ! -e $SOLVER_FILE ]; then echo "$SOLVER_FILE not found"; exit 1; fi

if [ ! -e "$RESULTS/model_gll_0.bp" ]; then
    echo "Copying $SIMULATION_DIR/DATA/GLL/model_gll.bp $RESULTS/model_gll_0.bp"
    cp -v $SIMULATION_DIR/DATA/GLL/model_gll.bp $RESULTS/model_gll_0.bp
fi

# Create Event File
cd $WORK_DIR
create_event_file_specfem $KERNEL_SUM_INPUT $KERNEL_MASK_DIRS_FILE
if [ $? -ne 0 ]; then echo " Error in event file specfem sum"; exit 1; fi

cd $SIMULATION_DIR

# Create Sbatch File

edit_sbatch "$SBATCH_KERNEL" $SIMULATION_DIR/DATA/Par_file
sed -i "s/^#SBATCH --time=.*/#SBATCH --time=$KERNEL_TIME/" $SBATCH_KERNEL
sed -i "s/^#SBATCH -p.*/#SBATCH -p $KERNEL_PARTITION/" $SBATCH_KERNEL

# Kernel Sum
sed -i "s|:event_file:|$KERNEL_SUM_INPUT|g" $SBATCH_KERNEL
sed -i "s|:output_file:|$KERNEL_SUM_OUTPUT|g" $SBATCH_KERNEL
sed -i "s|:model_file:|${RESULTS}/model_gll_0.bp|g" $SBATCH_KERNEL

# Kernel Smoothing

sed -i "s/:SIGMA_H:/$SIGMA_H/g" $SBATCH_KERNEL
sed -i "s/:SIGMA_V:/$SIGMA_V/g" $SBATCH_KERNEL
sed -i "s/:KERNEL_NAME:/$KERNEL_NAME/g" $SBATCH_KERNEL
sed -i "s|:INPUT_FILE:|$KERNEL_SMOOTH_INPUT|g" $SBATCH_KERNEL
sed -i "s|:SOLVER_FILE:|$SOLVER_FILE|g" $SBATCH_KERNEL
sed -i "s|:OUTPUT_FILE:|$KERNEL_OUTPUT_FILE|g" $SBATCH_KERNEL
sed -i "s/:GPU_MODE:/$GPU_MODE/g" $SBATCH_KERNEL

# Kernel Mask Source

sed -i "s|:KERNEL_FILE:|$KERNEL_MASK_INPUT|g" $SBATCH_KERNEL
sed -i "s|:MASK_DIRS_FILE:|$KERNEL_MASK_DIRS_FILE|g" $SBATCH_KERNEL
sed -i "s|:OUTPUT_FILE_MASK:|$KERNEL_MASK_OUTPUT|g" $SBATCH_KERNEL



slurm_monitor.sh "$SBATCH_KERNEL" 1 $verbose
check_status $? "$SBATCH_KERNEL"

check_status 0 $(basename $0)
exit 0
