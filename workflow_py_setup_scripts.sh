#!/bin/bash

trap ' check_status 1 $(basename $0) ' ERR

if [ $# -lt 5 ]; then
    echo "This program sets up sbatch scripts for workflow"
    echo "usage: ./workflow_py_setup_scripts.sh PAR_INV account nproc narray verbose[false==0/true==1]"; exit 1;
fi

PAR_INV=$1
account=$2
nproc=$3
narray=$4
verbose=$5


. workflow_py_load_config.sh $PAR_INV $verbose
check_status $?


if [ $verbose -eq 1 ]; then
    echo "##### Setup for sbatch scriptc for workflow"
    echo "Account: " $account
    echo "Nproc: " $nproc
    echo "Narray: " $narray
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
	target=`echo $template | sed -e s/\.sh.template//g`
	cp -v $template ${target}.sbatch
	sed -i "s/:nproc:/$nproc/g" ${target}.sbatch
	sed -i "s/:array:/$narray/g" ${target}.sbatch
	if [[ -z $account ]]; then
		sed -i "/:account:/d" ${target}.sbatch
	else
		sed -i "s/:account:/$account/g" ${target}.sbatch
	fi
	echo "$target is written."
done


check_status 0 $(basename $0)
exit 0
