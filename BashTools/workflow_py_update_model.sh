#!/bin/bash

trap " log_status 1 $(basename $0) "  ERR


if [ $# -lt 3 ]
then
    echo "Usage: ./$(basename $0) PAR_INV[file] step verbose[false==0/true==1]"
    exit 1
fi


PAR_INV=$1
step=$2
verbose=$3


# Loading env variables and utilities
. workflow_py_load_config.sh  $PAR_INV $verbose

cd $WORK_DIR

echo "Update Model"
echo "Checking input parameters"

if [ -z $MODEL_FILE ]; then echo "MODEL_FILE not defined";exit 1;fi
if [ ! -e $MODEL_FILE ]; then echo "MODEL_FILE not found";exit 1;fi

cd $SIMULATION_DIR

if [ ! -e $LS_BIN ]; then echo "$LS_BIN not found"; exit 1; fi


if [ ! -e "$SBATCH_LS.template" ] || [ -z $SBATCH_LS ]; then echo "SBATCH_LS not found";exit 1; fi




edit_sbatch "$SBATCH_LS" $SIMULATION_DIR/DATA/Par_file
sed -i "s/^#SBATCH --time=.*/#SBATCH --time=$LS_TIME/" $SBATCH_LS
sed -i "s/^#SBATCH -p.*/#SBATCH -p $LS_PARTITION/" $SBATCH_LS

#cp -v $MODEL_FILE ${RESULTS}/model_gll_0.bp
SOLVER_FILE="$SIMULATION_DIR/DATABASES_MPI/solver_data.bp"
PAR_LS="$KERNEL_PARFILE $step ${RESULTS}/model_gll_0.bp $SOLVER_FILE $RESULTS/$DIR_GRAD_OUTPUT $RESULTS"

sed -i "s|:executable:|$LS_BIN|g" $SBATCH_LS
sed -i "s|:parameters:|$PAR_LS|g" $SBATCH_LS

slurm_monitor.sh "$SBATCH_LS" 1 $verbose
check_status $? "$SBATCH_LS" 

mv $RESULTS/model_gll.bp $RESULTS/model_gll_test.bp

cp -v $RESULTS/model_gll_test.bp $SIMULATION_DIR/DATA/GLL/model_gll.bp

check_status 0 $(basename $0)

exit 0
