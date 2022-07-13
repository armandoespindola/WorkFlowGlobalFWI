#!/bin/bash


function log_status(){
    if [ $# -lt 2 ]
    then
	echo "Usage: log_status status \"message\" "
	exit 1
    fi

    printf "%s status %i\n" $2 $1 >> $WORKFLOW_LOG_FILE
    
}

export -f log_status


function check_status(){
    if [ $# -lt 1 ]
    then
	echo "Usage: check_status status"
	exit 1
    fi


    if [ ! -z "$2" ]
    then
	log_status $1 "$2"
    fi

    
    if [ $1 -ne 0 ]
    then
	exit 1
    fi

}

export -f check_status


function edit_sbatch(){

    if [ $# -lt 2 ]
    then
	echo "Usage: edit_sbatch sbatch_file Par_file[specfem]"
	exit 1
    fi

    _sbatch_file=$1
    _par_file=$2
    cp -v ${_sbatch_file}.template ${_sbatch_file} 
    NPROC_XI=$(grep -o NPROC_XI.* ${_par_file} | cut -f2 -d"=")              
    NPROC_ETA=$(grep -o NPROC_ETA.* ${_par_file} | cut -f2 -d"=")            
    NPROC=$((NPROC_XI * NPROC_ETA * 6))

    NSIMUL=$(grep -o ^NUMBER_OF_SIMULTANEOUS.* ${_par_file} | cut -f2 -d"=")
    NPROC_TOTAL=$((NPROC * NSIMUL))                                                           
    NODES=$(( (NPROC_TOTAL + (ARCH_PROC-1))/ARCH_PROC ))           
    PPN=$(( NODES * ARCH_PROC ))

    sed -i "s:^NPROC.*:NPROC=$NPROC_TOTAL:" $_sbatch_file
    sed -i "s/^#SBATCH --ntasks=.*/#SBATCH --ntasks=$PPN/" $_sbatch_file
    sed -i "s/^#SBATCH --nodes=.*/#SBATCH --nodes=$NODES/" $_sbatch_file
    sed -i "s/^#SBATCH --ntasks-per-node=.*/#SBATCH --ntasks-per-node=$ARCH_PROC/" $_sbatch_file
   
    }

export -f edit_sbatch
