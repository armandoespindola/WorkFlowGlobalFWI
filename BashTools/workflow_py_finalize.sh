#!/bin/bash

trap " log_status 1 $(basename $0) "  ERR


if [ $# -lt 2 ]
then
    echo "Usage: ./workflow_py_finalize.sh PAR_INV[file] verbose[false==0/true==1]"
    exit 1
fi


PAR_INV=$1
verbose=$2

. workflow_py_load_config.sh $PAR_INV $verbose

# Copying important files and remove files to start new iteration

cd $WORKFLOW_DIR/


# Copying Windows
cd windows
cp -rv output $RESULTS/windows/
cp -rv parfile $RESULTS/windows/
cp -v *.py $RESULTS/windows/
cd ..

cd sum_adjoint
mkdir -p $RESULTS/sum_adjoint
cp -v output/*.misfit.json $RESULTS/sum_adjoint/
cd ..

cd line_search
mkdir -p $RESULTS/line_search

cp -v steps $RESULTS/line_search/
cp -v alpha $RESULTS/line_search/
cp -v status $RESULTS/line_search/

cd $WORK_DIR

cp PAR_INV $RESULTS/

cd $SIMULATION_DIR
cp DATA/Par_file $RESULTS

check_status 0 $(basename $0)
exit 0
