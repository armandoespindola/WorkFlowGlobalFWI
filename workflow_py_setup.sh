#!/bin/bash
trap ' check_status 1 $(basename $0) ' ERR



if [ $# -lt 6 ]; then
    echo "This program sets up worflow-py"
    echo "usage: ./workflow_py_clean.sh  PAR_INV event_file account[sbatch] nproc[sbatch] narray[sbatch] verbose[false==0/true==1]"; exit 1;
fi

PAR_INV=$1
event_file=$2
account=$3
nproc=$4
narray=$5
verbose=$6



# Loading env variables
. workflow_py_load_config.sh $PAR_INV $verbose
check_status $?

# Cleaning workflow directories
workflow_py_clean.sh $PAR_INV $verbose
check_status $?


# Get events names
cd $WORK_DIR
if [ ! -e "$WORKFLOW_DIR/$event_file" ]
then
    echo "No $WORKFLOW_DIR/$event_file file found. Please check if you are running the program in the correct folder!"
    exit 1
fi

events=($(grep -v ^# "$WORKFLOW_DIR/$event_file"))
nevents=${#events[@]}

if [ $verbose -eq 1 ]; then
    echo "Events: " ${events[@]}
    echo "Number Events: " $nevents
fi

cd $WORKFLOW_DIR/seis/raw/

for ifold in ${events[@]}; do
    # synthentic data
    rm -rvf *"${ifold}"*
    cp -v  $SYNT_DATA_DIR/$ifold/OUTPUT_FILES/synthetic.h5 ${ifold}.synt.h5
    # observed data
    cp -v  $OBS_DATA_DIR/$ifold/OUTPUT_FILES/synthetic.h5 ${ifold}.obsd.h5
done

	     

# Setup bash scripts
cd $WORK_DIR
workflow_py_setup_scripts.sh $PAR_INV $account $nproc $narray $verbose
check_status $? 


check_status 0 $(basename $0)
exit 0





