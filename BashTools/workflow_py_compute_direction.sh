#!/bin/bash

trap " check_status 1 $(basename $0)  " ERR



if [ $# -lt 3 ]
then
    echo "This program computes the direction of optimization winth SD,NCG,LBFGS"
    echo "SD: Steepest Descent direction"
    echo "NCG: No-Linear Conjugate Gradient direction"
    echo "L-BFGS: Limited-memory BFGS direction"
    echo "usage: workflow_py_compute_direction.sh PAR_INV method[\"SD\"/\"NLCG\"/\"LBFGS\"] verbose[false==0/true==1]"
    exit 
fi

PAR_INV=$1
method=$2
verbose=$3

. workflow_py_load_config.sh $PAR_INV $verbose

if [ "$method" == "SD" ]
then
    echo "Method: Steepest Descent ($method)"

    echo "Checking input parameters"

    if [ ! -e $GRAD_FILE ];then echo "Gradient file not found"; exit 1;fi
    #if [ ! -e $PRECOND_FILE ];then echo "Preconditioner file not found"; exit 1;fi
    if [ -z $DIR_GRAD_OUTPUT ]; then echo "Direction output file not defined";exit 1;fi




    cd $SIMULATION_DIR

    if [ ! -e $SD_EXECUTABLE ]; then echo "$SD_EXECUTABLE not found"; exit 1; fi


    cp $SBATCH_OPT.template $SBATCH_OPT

    SOLVER_FILE="$SIMULATION_DIR/DATABASES_MPI/solver_data.bp"

    PAR_SD="$GRAD_FILE $PRECOND_FILE $SOLVER_FILE $DIR_GRAD_OUTPUT"

    sed -i "s|:executable:|$SD_EXECUTABLE|g" $SBATCH_OPT
    sed -i "s|:parameters:|$PAR_SD|g" $SBATCH_OPT

    slurm_monitor.sh "$SBATCH_OPT" 1 $verbose
    check_status $? "$SBATCH_OPT"

    cp -v $DIR_GRAD_OUTPUT ${RESULTS}
    cp -v gtg ${RESULTS}
    cp -v gtp ${RESULTS}

    
fi


if [ "$method" == "NLCG" ]
then
    echo "Method: No Linear Conjugate Gradient ($method)"
    echo " Checking input parameters"

    if [ -z $GRAD_FILE_OLD ]; then echo "PAR_INV: GRAD_FILE_OLD not defined"; exit 1; fi
    if [ -z $DIRECTION_FILE_OLD ]; then echo "PAR_INV: DIRECTION_FILE_OLD not defined"; exit 1; fi
    if [ -z $GRAD_FILE_NEW ]; then echo "PAR_INV: GRAD_FILE_NEW not defined"; exit 1; fi
    if [ -z $DIR_GRAD_OUTPUT ]; then echo "Direction output file not defined"; exit 1; fi

    if [ ! -e $GRAD_FILE_OLD ]; then echo "PAR_INV: GRAD_FILE_OLD not found"; exit 1; fi
    if [ ! -e $DIRECTION_FILE_OLD ]; then echo "PAR_INV: DIRECTION_FILE_OLD is not found"; exit 1; fi

    cd $SIMULATION_DIR
    
    if [ ! -e $NLCG_EXECUTABLE ]; then echo "$NLCG_EXECUTABLE not found"; exit 1; fi




    cp $SBATCH_OPT.template $SBATCH_OPT

    SOLVER_FILE="$SIMULATION_DIR/DATABASES_MPI/solver_data.bp"

    PAR_NLCG="$GRAD_FILE_OLD $GRAD_FILE_NEW $DIRECTION_FILE_OLD $SOLVER_FILE $DIR_GRAD_OUTPUT"

    sed -i "s|:executable:|$NLCG_EXECUTABLE|g" $SBATCH_OPT
    sed -i "s|:parameters:|$PAR_NLCG|g" $SBATCH_OPT

    slurm_monitor.sh "$SBATCH_OPT" 1 $verbose
    check_status $? "$SBATCH_OPT"

    cp -v $DIR_GRAD_OUTPUT ${RESULTS}
    cp -v gtg ${RESULTS}
    cp -v gtp ${RESULTS}
    
fi


check_status 0 $(basename $0)
exit 0
