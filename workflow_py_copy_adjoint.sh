#!/bin/bash

trap " log_status 1 $0 "  ERR

if [ $# -lt 2 ]; then
    echo  "This program creates links to adjoint sources and adjoint stations"
    echo  " usage: ./workflow_py_copy_adjoint.sh PAR_INV verbose[false=0/true=1] "
    echo 
    exit 1
fi

PAR_INV=$1
verbose=$2


# Loading env variables
. workflow_py_load_config.sh  $PAR_INV $verbose

cd $WORK_DIR

if [ ! -e "$WORKFLOW_DIR/$EVENT_FILE" ]; then
    echo "No $WORKFLOW_DIR/$EVENT_FILE file found. Please check!"
    exit 1
fi

events=($(grep -v ^# "$WORKFLOW_DIR/$EVENT_FILE"))
nevents=${#events[@]}

for ievent in ${events[@]}
do
    cd  ${SIMULATION_DIR}/${ievent}
    echo -ne "Creating links to files in $SIMULATION_DIR/$ievent ... \r"
    cd DATA
    echo $(pwd)
    rm  -fv STATIONS_ADJOINT
    ln -sf ${WORKFLOW_DIR}/sum_adjoint/output/STATIONS_ADJOINT.${ievent} STATIONS_ADJOINT
    rm -rf SEM

    cd ..
    
    if [ ! -d SEM ]; then
	mkdir -p  SEM
	rm SEM/*
    fi

    cd SEM
    rm -f *.h5
    ln -sf ${WORKFLOW_DIR}/sum_adjoint/output/adjoint_sum.${ievent}.h5 adjoint.h5
    
done

cd $WORK_DIR

log_status 0 $(basename $0)
exit 0
