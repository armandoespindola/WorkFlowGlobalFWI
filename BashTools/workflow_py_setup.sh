#!/bin/bash
trap ' check_status 1 $(basename $0) ' ERR



if [ $# -lt 2 ]; then
    echo "This program sets up worflow_py_setup.sh"
    echo "usage: ./workflow_py_setup.sh  PAR_INV WIN verbose[false==0/true==1]"; exit 1;
fi

PAR_INV=$1
WIN=$2
verbose=$3

# Loading env variables
. workflow_py_load_config.sh $PAR_INV $verbose
check_status $?

# Cleaning workflow directories
workflow_py_clean.sh $PAR_INV $WIN $verbose
check_status $?


# Get events names
cd $WORK_DIR
if [ ! -e "$WORKFLOW_DIR/$EVENT_FILE" ]
then
    echo "No $WORKFLOW_DIR/$event_file file found. Please check if you are running the program in the correct folder!"
    exit 1
fi

events=($(grep -v ^# "$WORKFLOW_DIR/$EVENT_FILE"))
nevents=${#events[@]}

if [ $verbose -eq 1 ]; then
    echo "Events: " ${events[@]}
    echo "Number Events: " $nevents
fi

cd $WORKFLOW_DIR/seis/raw/

for ifold in ${events[@]}; do
    # synthentic data
    rm -rvf *"${ifold}"*

    if [ ! -e  "$SYNT_DATA_DIR/$ifold/OUTPUT_FILES/synthetic.h5" ]; then
	echo "File not found: $SYNT_DATA_DIR/$ifold/OUTPUT_FILES/synthetic.h5"
	exit 1
    else
	cp -v  $SYNT_DATA_DIR/$ifold/OUTPUT_FILES/synthetic.h5 ${ifold}.synt.h5
    fi

    if [ ! -e "$OBS_DATA_DIR/$ifold/OUTPUT_FILES/synthetic.h5" ]; then
	echo "File not found: $OBS_DATA_DIR/$ifold/OUTPUT_FILES/synthetic.h5 ${ifold}.obsd.h5"
	exit 1
    else
	# observed data
	cp -v  $OBS_DATA_DIR/$ifold/OUTPUT_FILES/synthetic.h5 ${ifold}.obsd.h5
    fi
    
done

	     

# Setup bash scripts
cd $WORK_DIR
workflow_py_setup_scripts.sh $PAR_INV $verbose
check_status $? 


check_status 0 $(basename $0)
exit 0
