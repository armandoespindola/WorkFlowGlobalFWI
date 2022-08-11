#!/bin/bash



function fstatus()
{
    local _status=$1

    if [ "$_status" == "COMPLETED" ]; then
	echo "1"
    elif [ "$_status" == "FAILED+" ] || [ "$_status" == "CANCELLED" ] || [ "$_status" == "PREEMPTED" ]; then
	echo "-1"
    elif  [ "$_status" == "CANCELLED+" ]; then
	echo "-1"
    elif [ -z "$_status" ]; then
	echo "0"
    elif [ "$_status" == "RUNNING" ]; then
	echo "2"
    fi
    
}

# CHECK STATUS SLURM JOB OPTIONAL STEP

if [ "$1" == "" ]
then
    echo "usage: ./job_check_status.sh jobid step";
    exit 1
fi

jobid=$1
step=$2

if [ -z "$step" ]; then
    job_step=$jobid
else
    job_step=${jobid}_${step}
fi


output=$(sacct -n -o jobid,state -j ${job_step})
job_slurm=$(echo $output | cut -f1 -d" " | xargs)
status_slurm=$(echo $output | cut -f2 -d" " | xargs)


if [ "$job_slurm" == "$job_step" ]
then
    echo "$(fstatus $status_slurm)"
else
    echo "0"
fi



