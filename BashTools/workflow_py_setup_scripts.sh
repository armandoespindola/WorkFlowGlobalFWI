#!/bin/bash

trap ' check_status 1 $(basename $0) ' ERR


function create_sbatch(){
    local file=$1

    target=`echo $file | sed -e s/\.sh.template//g`
    cp -v $file ${target}.sbatch


    if [ -z $DS_ACCOUNT ]; then sed -i "/:account:/d" ${target}.sbatch
    else
	sed -i "s/:account:/$DS_ACCOUNT/g" ${target}.sbatch
    fi

    if [ -z $DS_PARTITION ]; then sed -i "/.*partition.*/d" ${target}.sbatch
    else
	sed -i "s/:partition:/$DS_PARTITION/g" ${target}.sbatch
    fi

    if [ -z $DS_EXCLUSIVE ]; then sed -i "/.*exclusive.*/d" ${target}.sbatch ; fi

    if [ -z $DS_NODES ]; then sed -i "/.*nodes.*/d" ${target}.sbatch
    else
	sed -i "s/:nodes:/$DS_NODES/g" ${target}.sbatch
    fi

    if [ -z $DS_NTASK ]; then sed -i "/.*tasks.*/d" ${target}.sbatch
    else
	sed -i "s/:nproc:/$DS_NTASK/g" ${target}.sbatch
    fi

    if [ -z $DS_NARRAY ]; then sed -i "/.*array.*/d" ${target}.sbatch
    else
	sed -i "s/:array:/$DS_NARRAY/g" ${target}.sbatch
    fi

    if [ -z $DS_TIME ]; then sed -i "/.*time.*/d" ${target}.sbatch
    else
	sed -i "s/:time:/$DS_TIME/g" ${target}.sbatch
    fi

    if [ -z $DS_GRES ]; then sed -i "/.*gres.*/d" ${target}.sbatch
    else
	sed -i "s/:gres:/$DS_GPU/g" ${target}.sbatch
    fi

    echo "$target is written."
     
}


if [ $# -lt 2 ]; then
    echo "This program sets up sbatch scripts for workflow"
    echo "usage: ./workflow_py_setup_scripts.sh PAR_INV verbose[false==0/true==1]"; exit 1;
fi

PAR_INV=$1
verbose=$2


. workflow_py_load_config.sh $PAR_INV $verbose
check_status $?


if [ $verbose -eq 1 ]; then
    echo "##### Setup for sbatch scriptc for workflow"
    echo "Account: " $DS_ACCOUNT
    echo "Nproc: " $DS_NTASK
    echo "Narray: " $DS_NARRAY
fi

cd $WORKFLOW_DIR

templates=("converter/convert_to_asdf.sh.template"
           "proc/run_preprocessing.sh.template"
           "windows/select_windows.sh.template"
           "measure/run_measureadj.sh.template"
           "stations/extract_stations.sh.template"
           "filter/filter_windows.sh.template"
           "adjoint/run_pyadj_mt.sh.template"
           "weights/calc_weights.sh.template"
           "sum_adjoint/sum_adjoint.sh.template")

for template in "${templates[@]}"
do
    create_sbatch $template
done

check_status 0 $(basename $0)
exit 0
