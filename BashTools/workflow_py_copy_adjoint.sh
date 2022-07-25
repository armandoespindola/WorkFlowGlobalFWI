#!/bin/bash

trap " log_status 1 $0 "  ERR

if [ $# -lt 3 ]; then
    echo  "This program creates links to adjoint sources and adjoint stations"
    echo  " usage: ./workflow_py_copy_adjoint.sh PAR_INV Q_FLAG[false=0/true=1] verbose[false=0/true=1] "
    echo 
    exit 1
fi

PAR_INV=$1
Q_FLAG=$2
verbose=$3


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

    if [ ! -e "${WORKFLOW_DIR}/sum_adjoint/output/STATIONS_ADJOINT.${ievent}" ]; then
	echo "File not found: ${WORKFLOW_DIR}/sum_adjoint/output/STATIONS_ADJOINT.${ievent}"
	exit 1
    else
	ln -sf ${WORKFLOW_DIR}/sum_adjoint/output/STATIONS_ADJOINT.${ievent} STATIONS_ADJOINT
	rm -rf SEM
    fi
    

    cd ..

    
    if [ ! -d SEM ]; then
	mkdir -p  SEM
	rm SEM/*
    fi

    cd SEM
    rm -f *.h5

    if [ ! -e "${WORKFLOW_DIR}/sum_adjoint/output/adjoint_sum.${ievent}.h5" ]; then
	echo "File not found: ${WORKFLOW_DIR}/sum_adjoint/output/adjoint_sum.${ievent}.h5"
	exit 1
    else

	if [ $KERNELS_ATTENUATION -eq 1 ]; then
	    if [ $Q_FLAG -eq 0 ]; then
		echo -ne "\n|---> Elastic adjoint source <---|\n"
		ln -sf ${WORKFLOW_DIR}/sum_adjoint/output/adjoint_sum.${ievent}.elastic.h5 adjoint.h5
	    elif [ $Q_FLAG -eq 1 ]; then
		echo -ne "\n|---> Anelastic adjoint source <---|\n"
		ln -sf ${WORKFLOW_DIR}/sum_adjoint/output/adjoint_sum.${ievent}.h5 adjoint.h5
	    fi
	else
	    echo -ne "\n|---> Adjoint source <---|\n"
	    ln -sf ${WORKFLOW_DIR}/sum_adjoint/output/adjoint_sum.${ievent}.h5 adjoint.h5
	fi
	
	
    fi
    
    
done

cd $WORK_DIR

log_status 0 $(basename $0)
exit 0
