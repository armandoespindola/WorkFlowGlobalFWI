#!/bin/bash

trap " check_status 1 $(basename $0) "  ERR SIGINT 

function print_process(){
    string_title=$1

    echo "######################"
    echo "######################"
    echo $string_title
    echo "######################"
    echo "######################"
    clear
}

if [ $# -lt 3 ]; then
    echo "This program runs workflow-py to compute adjoint source"
    echo "usage: ./workflow_py_run.sh PAR_INV WIN[false==0/true==1] verbose[false==0/true==1]"; exit 1;
fi

PAR_INV=$1
WIN=$2
verbose=$3

# Loading env variables
. workflow_py_load_config.sh $PAR_INV $verbose
check_status $?
events_list=$(grep -v ^# "${WORKFLOW_DIR}/${EVENT_FILE}" | sed "s/[a-z]0*//g")
events_name=$(grep -v ^# "${WORKFLOW_DIR}/${EVENT_FILE}")
cd $WORKFLOW_DIR

python generate_path_files.py folders
python generate_path_files.py proc
cd proc
slurm_monitor.sh "run_preprocessing.sbatch" "$events_list" $verbose
check_status $? "run_preprocessing.sbatch"
print_process "run_preprocessing: done"
cd ..

if [ $WIN -eq 1 ]
then
    
    python generate_path_files.py windows
    cd windows
    slurm_monitor.sh "select_windows.sbatch" "$events_list" $verbose
    check_status $? "select_windows.sbatch"
    print_process "select_windows: done"
    cd ..
fi


python generate_path_files.py measure
cd measure
slurm_monitor.sh "run_measureadj.sbatch" "$events_list" $verbose
check_status $? "run_measureadj.sbatch"
print_process "run_measureadj: done"
cd ..

python generate_path_files.py stations
cd stations
slurm_monitor.sh "extract_stations.sbatch" "$events_list" $verbose
check_status $? "extract_stations.sbatch"
print_process "extract_stations: done"
cd ..

python generate_path_files.py filter
cd filter
slurm_monitor.sh "filter_windows.sbatch" "$events_list" $verbose
check_status $? "filter_windows.sbatch"
print_process "filter_windows: done"
cd ..

python generate_path_files.py adjoint_dt
python generate_path_files.py adjoint_am
cd adjoint

if [ $KERNELS_ATTENUATION -eq 0 ] || [ $KERNELS_ATTENUATION -eq 1 ]; then
    echo -ne "\n|---> Elastic adjoint source <---|\n"
    slurm_monitor.sh "run_pyadj_mt_dt_am.sbatch" "$events_list" $verbose
elif [ $KERNELS_ATTENUATION -eq 2 ]; then
    echo -ne "\n|---> Anelastic adjoint source <---|\n"
    slurm_monitor.sh "run_pyadj_mt_dt_am_q.sbatch" "$events_list" $verbose
fi

check_status $? "run_pyadj_mt_am.sbatch"
print_process "run_pyadj_mt: done"
cd ..

python generate_path_files.py weight_dt_and_am_params
python generate_path_files.py weight_dt_and_am_paths
cd weights
slurm_monitor.sh "calc_weights_dt_am.sbatch" "$events_list" $verbose
check_status $? "calc_weights_dt_am.sbatch"
print_process "calc_weights_dt_am: done"
cd ..

python generate_path_files.py sum_dt_am
cd sum_adjoint
slurm_monitor.sh "sum_adjoint.sbatch" "$events_list" $verbose
check_status $? "sum_adjoint.sbatch"
print_process "sum_adjoint: done"
cd ..


if [ $KERNELS_ATTENUATION -eq 1 ]
then
    cd adjoint
    cd output
    for ievent in $events_name
    do
	file_id=$(find ./ -name "*$ievent*" -exec basename {} \;)
	mv -v ${file_id} ${file_id/.h5/.elastic.h5}
    done
    cd ../../

    cd sum_adjoint
    cd output
    for ievent in $events_name
    do
	file_id=$(find ./ -name "*$ievent*.h5" -exec basename {} \;)
	mv -v ${file_id} ${file_id/.h5/.elastic.h5}
	file_id=$(find ./ -name "*$ievent*.json" -exec basename {} \;)
	mv -v ${file_id} ${file_id/.json/.elastic.json}
    done
    cd ../../
    echo -ne "\n|---> Anelastic adjoint source <---|\n"
    python generate_path_files.py adjoint_dt
    python generate_path_files.py adjoint_am
    cd adjoint
    slurm_monitor.sh "run_pyadj_mt_dt_am_q.sbatch" "$events_list" $verbose
    check_status $? "run_pyadj_mt_dt_am_q.sbatch"
    print_process "run_pyadj_mt: done"
    cd ..

    python generate_path_files.py sum_dt_am
    cd sum_adjoint
    slurm_monitor.sh "sum_adjoint.sbatch" "$events_list" $verbose
    check_status $? "sum_adjoint.sbatch"
    print_process "sum_adjoint: done"
    cd ..
    
fi

check_status 0 $(basename $0)
exit 0




