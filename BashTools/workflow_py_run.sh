#!/bin/bash

trap " check_status 1 $(basename $0) "  ERR SIGINT 

function print_process(){
    string_title=$1

    echo "######################"
    echo "######################"
    echo $string_title
    echo "######################"
    echo "######################"
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

cd $WORKFLOW_DIR

python generate_path_files.py folders
python generate_path_files.py proc
cd proc
slurm_monitor.sh "run_preprocessing.sbatch" 1 $verbose
check_status $? "run_preprocessing.sbatch"
print_process "run_preprocessing: done"
cd ..

if [ $WIN -eq 1 ]
then
    
    python generate_path_files.py windows
    cd windows
    slurm_monitor.sh "select_windows.sbatch" 1 $verbose
    check_status $? "select_windows.sbatch"
    print_process "select_windows: done"
    cd ..
fi


python generate_path_files.py measure
cd measure
slurm_monitor.sh "run_measureadj.sbatch" 1 $verbose
check_status $? "run_measureadj.sbatch"
print_process "run_measureadj: done"
cd ..

python generate_path_files.py stations
cd stations
slurm_monitor.sh "extract_stations.sbatch" 1 $verbose
check_status $? "extract_stations.sbatch"
print_process "extract_stations: done"
cd ..

python generate_path_files.py filter
cd filter
slurm_monitor.sh "filter_windows.sbatch" 1 $verbose
check_status $? "filter_windows.sbatch"
print_process "filter_windows: done"
cd ..

python generate_path_files.py adjoint
cd adjoint
slurm_monitor.sh "run_pyadj_mt.sbatch" 1 $verbose
check_status $? "run_pyadj.sbatch"
print_process "run_pyadj_mt: done"
cd ..

python generate_path_files.py weight_params
python generate_path_files.py weight_paths
cd weights
slurm_monitor.sh "calc_weights.sbatch" 1 $verbose
check_status $? "calc_weights.sbatch"
print_process "calc_weights: done"
cd ..

python generate_path_files.py sum
cd sum_adjoint
slurm_monitor.sh "sum_adjoint.sbatch" 1 $verbose
check_status $? "sum_adjoint.sbatch"
print_process "sum_adjoint: done"
cd ..

check_status 0 $(basename $0)
exit 0




