#!/bin/bash

trap ' check_status 1 $(basename $0) ' ERR


function create_sbatch(){
    local file=$1

    target=`echo $file | sed -e s/\.sh.template//g`
    cp -v $file ${target}.sbatch



    ###### FRONTERA
    line=$(grep \\-\\-output ${target}.sbatch)
    sed -i "s/$line/${line}\n$SBATCH_OPTIONAL/g" ${target}.sbatch
    sed -i "s/mpirun.*-np/$MPIEXEC/g" ${target}.sbatch
    ######
    
    sed -i "s/\%a/:job_id:/g" ${target}.sbatch
    sed -i "s/^events=.*/events=(\$(\$gen list_events))/g" ${target}.sbatch                              
    sed -i "s/\$events/\${events[((:job_id: - 1))]}/g" ${target}.sbatch
    
    if [ -z $DS_ACCOUNT ]; then sed -i "/:account:/d" ${target}.sbatch
    else
	sed -i "s/:account:/$DS_ACCOUNT/g" ${target}.sbatch
    fi

    if [ -z $DS_PARTITION ]; then sed -i "/.*partition.*/d" ${target}.sbatch
    else
	sed -i "s/:partition:/$DS_PARTITION/g" ${target}.sbatch
    fi

    if [ -z $DS_EXCLUSIVE ]; then sed -i "/.*exclusive.*/d" ${target}.sbatch ; fi

    if [ -z $DS_NODE ]; then sed -i "/.*nodes.*/d" ${target}.sbatch
    else
	sed -i "s/:nodes:/$DS_NODE/g" ${target}.sbatch
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

misfit=$(grep ^misfit ${WORKFLOW_DIR}/settings.yml | cut -d: -f2 | xargs)
misfit_prefix=${misfit/'misfit_'/}
echo "#########"
echo "misfit: "$misfit
echo "#########"

cd $WORKFLOW_DIR

templates=("converter/convert_to_asdf.sh.template"
           "proc/run_preprocessing.sh.template"
           "windows/select_windows.sh.template"
           "measure/run_measureadj_${misfit_prefix}.sh.template"
           "stations/extract_stations.sh.template"
           "filter/filter_windows.sh.template"
	   "adjoint/run_pyadj_${misfit_prefix}.sh.template"
           "weights/calc_weights_${misfit_prefix}.sh.template"
           "sum_adjoint/sum_adjoint.sh.template")


for template in "${templates[@]}"
do
    create_sbatch $template
done

if [ $KERNELS_ATTENUATION -gt 0 ]
then
    echo -ne "\n|---> Anelastic and elastic adjoint source <---|\n"
cp -v adjoint/run_pyadj_${misfit_prefix}.sbatch adjoint/run_pyadj_${misfit_prefix}_q.sbatch
    sed -i "/-r.*/d" adjoint/run_pyadj_${misfit_prefix}.sbatch

elif [ $KERNELS_ATTENUATION -eq 0 ]
then
     echo -ne "\n|---> Elastic adjoint source <---|\n"
     sed -i "/-r.*/d" adjoint/run_pyadj_${misfit_prefix}.sbatch
fi

check_status 0 $(basename $0)
exit 0
