#!/bin/bash

trap " cancel_jobs " ERR SIGINT

function spin_bar(){
    local message="$1"
    local spin='-\|/'
    local time_sleep=$2

    for ((i=0;i<time_sleep;i++))
    do
	idx=$(( $i %4 ))
	echo -ne "\r$message ${spin:$idx:1} ${spin:$idx:1} ${spin:$idx:1}"
	sleep 1
    done
}

function cancel_jobs(){
    local _job
    for idx in ${!job_all[@]}
    do
	
	_job=${job_all[$idx]}
	echo "scancel ${_job%_*}"
	scancel ${_job%_*} 
    done

    exit 1
}

		     

function remove_jobs()
{
    # This function remove jobs completed and failed
    # remove jobs completed

    for i in ${jobs_done_idx[@]}
    do
	unset job_all[$i]
    done

    for i in ${jobs_fail_idx[@]}
    do
	unset job_all[$i]
    done
    
    
}

function submit_jobs_failed()
{
    # This function re-submit failed jobs and append job_id to job_all array
    local k=1
    for job in ${jobs_fail_id[@]}
    do
	#echo $job
	local step_id=$(echo $job | cut -f2 -d_)
	cp ${job_path}/$sbatch_file ${job_path}/resubmit_job.sbatch
	sed -i "s/:job_id:/${step_id}/g" ${job_path}/resubmit_job.sbatch
	# THIS LINE WAS MODIFIED FOR FRONTERA
	#sed -i "s/--array=.*/--array=${step_id}/g" ${job_path}/resubmit_job.sbatch
	job_new=$(sbatch ${job_path}/resubmit_job.sbatch | grep -o Submitted.* | cut -f4 -d" ")
	echo $job "--->" ${job_new}_${step_id}
	local end_idx=(${!job_all[@]})
	end_idx=${end_idx[@]: -1}
	local _idx=$((${end_idx} + $k))
	job_all[${_idx}]="${job_new}_${step_id}"
	k=$(($k + 1))
    done
    
    
    }

function _check_status()
{
    local k_done=1
    local k_fail=0
    
    for job_idx in ${!job_all[@]}
    do
	#"usage: ./job_check_status.sh jobid step";
	local _job=$(echo ${job_all[$job_idx]} | cut -f1 -d_)
	local _step=$(echo ${job_all[$job_idx]} | cut -f2 -d_)
	# THIS LINE WAS MODIFIED FOR FRONTERA
	#status=$(bash job_check_status.sh ${_job} ${_step})
	status=$(bash job_check_status.sh ${_job})
	if [ "$status" == "1" ]; then
	    local end_idx=(${!jobs_done_id[@]})
	    end_idx=${end_idx[@]: -1}
	    local _idx=$((${end_idx} + $k_done))
	    jobs_done_idx[${_idx}]=$job_idx
	    jobs_done_id[${_idx}]=${job_all[$job_idx]}
	    k_done=$((${k_done} + 1))
	elif [ "$status" == "-1" ]; then
	    jobs_fail_idx[$k_fail]=$job_idx
	    jobs_fail_id[$k_fail]=${job_all[$job_idx]}
	    k_fail=$((${k_fail} + 1))
	elif [ "$status" == "2" ]; then
	    continue
	elif [ "$status" == "0" ]; then
	    break
	fi
    done
    
}


function get_job_id()
{
    local _job_id=$(echo $1 | cut -f4 -d" ")
    local _job_ok=$(echo $1 | cut -f1 -d" ")

    job_id=$_job_id

    if [ "$_job_ok" == "Submitted" ]
    then
	if [ $verbose -eq 1 ]; then 
	    echo "JOB ID (SLURM MONITORING): " $job_id
	fi
    else
	if [ $verbose -eq 1 ]; then
	    echo "ERROR IN SBATCH (SLURM MONITORING)"
	fi
	exit 1
    fi
    }



function generate_jobids(){
local _sbatch_file=$1
local _job_list="$2"

for i in $_job_list
do
    job_id=""
    cp $_sbatch_file ${_sbatch_file}.${i}
    sed -i "s/:job_id:/${i}/g" ${_sbatch_file}.${i}
    output_sbatch=$(echo $(sbatch ${sbatch_file}.${i}) | grep -o Submitted.*)
    echo $output_sbatch
    get_job_id "$output_sbatch"
    job_all[$i]="${job_id}_$i"
    rm -f ${_sbatch_file}.${i}
done

}


if [ $# -lt 3 ]
then
    echo "usage: ./slurm_monitor sbatch_file nstep_job verbose[false==0/true==1]"
    exit 1
fi

#### MAIN PROGRAM

sbatch_file=$1
nstep_job=$2
verbose=$3

# Declere arrays

jobs_done_idx=()
jobs_done_id=()
jobs_fail_idx=()
jobs_fail_id=()
job_all=()
job_path=$(pwd)


JOBLOG_FILE="${job_path}/slurm_monitor.log"


generate_jobids $sbatch_file "$nstep_job"

while [ ${#job_all[@]} -gt 0 ]; do

    spin_bar "Monitoring jobs - Jobs left: ${#job_all[@]} - Jobs done: ${#jobs_done_id[@]}" 10
    
    # check status jobs
    _check_status
    # removes done and failed jobs
    remove_jobs

    # Resubmit jobs
    if [ ${#jobs_fail_id[@]} -gt 0 ]; then
	echo "Submiting Failed Jobs: " ${#jobs_fail_id[@]}
	submit_jobs_failed
	jobs_fail_idx=()
	jobs_fail_id=()
    fi


    if [ $verbose -eq 1 ]; then
	echo "###### LOG FILE ########" >$JOBLOG_FILE
	echo " "  >>$JOBLOG_FILE
	echo "###############" $(date) >>$JOBLOG_FILE
	echo "Running Jobs: " ${job_all[@]} >>$JOBLOG_FILE
	echo "----" >>$JOBLOG_FILE
	echo "Jobs Done: " ${jobs_done_id[@]} >>$JOBLOG_FILE
	echo "----" >>$JOBLOG_FILE
	echo "Jobs Failed: " ${jobs_fail_id[@]} >>$JOBLOG_FILE
	echo "----"  >>$JOBLOG_FILE
	echo "Jobs Submited As:" >>$JOBLOG_FILE
    fi
    spin_bar "Monitoring jobs - Jobs left: ${#job_all[@]} - Jobs done: ${#jobs_done_id[@]}" 2
done

echo



exit 0
