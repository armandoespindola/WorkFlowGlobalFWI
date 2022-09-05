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


cd $SIMULATION_DIR
edit_sbatch "$SBATCH_OPT" $SIMULATION_DIR/DATA/Par_file
sed -i "s/^#SBATCH --time=.*/#SBATCH --time=$OPT_TIME/" $SBATCH_OPT
sed -i "s/^#SBATCH -p.*/#SBATCH -p $OPT_PARTITION/" $SBATCH_OPT

if [ "$method" == "SD" ]
then
    echo "Method: Steepest Descent ($method)"

    echo "Checking input parameters"

    if [ ! -e $GRAD_FILE ];then echo "Gradient file not found"; exit 1;fi
    #if [ ! -e $PRECOND_FILE ];then echo "Preconditioner file not found"; exit 1;fi
    if [ -z $DIR_GRAD_OUTPUT ]; then echo "Direction output file not defined";exit 1;fi




    cd $SIMULATION_DIR

    if [ ! -e $SD_BIN ]; then echo "$SD_BIN not found"; exit 1; fi


    #cp $SBATCH_OPT.template $SBATCH_OPT

    SOLVER_FILE="$SIMULATION_DIR/DATABASES_MPI/solver_data.bp"

    if [ ! -e $SOLVER_FILE ];then echo "Solver file not found"; exit 1;fi

    PAR_SD="$KERNEL_PARFILE $GRAD_FILE $SOLVER_FILE $DIR_GRAD_OUTPUT $PRECOND_FILE"

    sed -i "s|:executable:|$SD_BIN|g" $SBATCH_OPT
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
    if [ ! -e $PRECOND_FILE_NLCG ]; then echo "PAR_INV: PRECOND_FILE_NLCG is not found"; exit 1; fi
    
    cd $SIMULATION_DIR
    
    if [ ! -e $NLCG_BIN ]; then echo "$NLCG_BIN not found"; exit 1; fi




    #cp $SBATCH_OPT.template $SBATCH_OPT

    SOLVER_FILE="$SIMULATION_DIR/DATABASES_MPI/solver_data.bp"

    if [ ! -e $SOLVER_FILE ];then echo "Solver file not found"; exit 1;fi

       PAR_NLCG="$KERNEL_PARFILE $GRAD_FILE_OLD $GRAD_FILE_NEW $DIRECTION_FILE_OLD $SOLVER_FILE $DIR_GRAD_OUTPUT"
       PAR_NLCG="$PAR_NLCG $PRECOND_FILE_NLCG"

    sed -i "s|:executable:|$NLCG_BIN|g" $SBATCH_OPT
    sed -i "s|:parameters:|$PAR_NLCG|g" $SBATCH_OPT

    slurm_monitor.sh "$SBATCH_OPT" 1 $verbose
    check_status $? "$SBATCH_OPT"

    cp -v $DIR_GRAD_OUTPUT ${RESULTS}
    cp -v gtg ${RESULTS}
    cp -v gtp ${RESULTS}
    
fi


if [ "$method" == "LBFGS" ]
then
    echo "Method: LBFGS ($method)"
    echo " Checking input parameters"

    if [ -z $LBFGS_PATH_FILE ]; then echo "PAR_INV: LBFGS_PATH_FILE not defined"; exit 1; fi
    if [ ! -e $LBFGS_PATH_FILE ]; then echo "PAR_INV: LBFGS_PATH_FILE not found"; exit 1; fi

    file_line=$(cat $LBFGS_PATH_FILE)

    kline=1
    for iline in $file_line
    do
	echo "File config: " $iline
	if [ $kline -eq 1 ]; then
	    test=$(echo $iline | grep "^-\?[0-9]\+$")
	    if [ -z $test ]; then echo "Check file $LBFGS_PATH_FILE - Number of previous gradients"
				  exit 1; fi
	else

	if [ ! -e $iline ]; then echo "Check file $LBFGS_PATH_FILE - (File not found : $iline) "
				 exit 1;
	fi

	fi
	
	kline=$((kline + 1))
	    
    done

    cd $SIMULATION_DIR
    #cp $SBATCH_OPT.template $SBATCH_OPT
    
    if [ ! -e $LBFGS_BIN ]; then echo "$LBFGS_BIN not found"; exit 1; fi

    SOLVER_FILE="$SIMULATION_DIR/DATABASES_MPI/solver_data.bp"

    if [ ! -e $SOLVER_FILE ];then echo "Solver file not found"; exit 1;fi

    if [ ! -e $LBFGS_H0_FILE ]; then echo "$LBFGS_H0_FILE not found"; exit 1; fi

    PAR_LBFGS="$KERNEL_PARFILE $LBFGS_PATH_FILE $SOLVER_FILE $DIR_GRAD_OUTPUT $LBFGS_H0_FILE"

    sed -i "s|:executable:|$LBFGS_BIN|g" $SBATCH_OPT
    sed -i "s|:parameters:|$PAR_LBFGS|g" $SBATCH_OPT

    slurm_monitor.sh "$SBATCH_OPT" 1 $verbose
    check_status $? "$SBATCH_OPT"

    cp -v $DIR_GRAD_OUTPUT ${RESULTS}
    cp -v gtg ${RESULTS}
    cp -v gtp ${RESULTS}


    
fi



check_status 0 $(basename $0)
exit 0
