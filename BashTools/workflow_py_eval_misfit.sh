#!/bin/bash

trap " log_status 1 $(basename $0) " ERR

function copy_synthetic_data(){

    cd $WORK_DIR
    if [ ! -e "$WORKFLOW_DIR/$EVENT_FILE" ];
    then
	echo "No $WORKFLOW_DIR/$EVENT_FILE file found."
	exit 1
    fi
    
    events=($(grep -v ^# "$WORKFLOW_DIR/$EVENT_FILE"))
    nevents=${#events[@]}

    cd $WORKFLOW_DIR/seis/raw/
    
    for ifold in ${events[@]}; do
	# synthentic data
	mv -v ${ifold}.synt.h5 ${ifold}.synt.h5.bak 
	ln -sf  $SYNT_DATA_DIR/$ifold/OUTPUT_FILES/synthetic.h5 ${ifold}.synt.h5
    done

}


function compute_misfit(){
    cd $WORKFLOW_DIR
    events_list=$(grep -v ^# "${WORKFLOW_DIR}/${EVENT_FILE}" | sed "s/[a-z]0*//g")
    cd proc
    slurm_monitor.sh "run_preprocessing.sbatch" "$events_list" $verbose
    check_status $?
    echo "run_preprocessing: done"
    cd ..

    cd measure
    slurm_monitor.sh "run_measureadj.sbatch" "$events_list" $verbose
    check_status $?
    echo "run_measureadj: done"
    cd ..

    # cd adjoint
    # slurm_monitor.sh "run_pyadj_mt.sbatch" "$events_list" $verbose
    # check_status $?
    # echo "run_pyadj_mt: done"
    # cd ..


    #python print_linesearch.py "."
    python generate_path_files.py $LS_MISFIT
    check_status $?

    cp fval line_search/
    
    }


if [ $# -lt 2 ]
then
    echo "Usage ./workflow_py_eval_misfit.sh PAR_INV[file] verbose[false==0/true==1]"
    exit 1
fi

PAR_INV=$1
verbose=$2

. workflow_py_load_config.sh $PAR_INV $verbose


# Compute Forward

workflow_py_forward.sh $PAR_INV 1 $verbose
check_status $?

# Compute Misfit

## copy data
copy_synthetic_data
check_status $?

## copute misfit 
compute_misfit
check_status $?

check_status 0 $(basename $0)

exit 0
