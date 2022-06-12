#!/bin/bash
trap " log_status 1 $(basename $0) " ERR



if [ $# -lt 2 ]
then
    echo "Usage: ./$(basename $0) PAR_INV[file] verbose[false==0/true==1]"
    exit 1
fi

PAR_INV=$1
verbose=$2

. workflow_py_load_config.sh $PAR_INV $verbose


cd $WORKFLOW_DIR
if [ ! -e $RESULTS/fval ]; then
    mpirun -np 1 python print_linesearch.py "."
    check_status $?
    cp -v  fval $RESULTS/
fi


cd $WORK_DIR

# PARAMETERS LINE SEARCH 
if [ ! -e $RESULTS/fval ]; then echo "$RESULTS/fval not found";exit 1;fi
fval=$(cat $RESULTS/fval)

if [ ! -e $RESULTS/gtg ]; then echo "$RESULTS/gtg not found";exit 1;fi
gtg=$(cat $RESULTS/gtg)

if [ ! -e $RESULTS/gtp ]; then echo "$RESULTS/gtp not found";exit 1;fi
gtp=$(cat $RESULTS/gtp)

#bash_val=" workflow_py_update_model.sh INV_PAR

if [ -z $STEP_TRIALS ]; then echo "STEP_TRIALS not defined";exit 1;fi
step_trials="$STEP_TRIALS"

step="0.0"


if [ $OLD_ITER -eq 1 ]; then 
   if [ -z "$FVAL_OLD" ] && [ -z "$STEP_OLD" ] && [ -z "$GTP_OLD" ]; then
       echo "Check values FVAL_OLD, STEP_OLD and GTP_OLD are defined"
       exit 1
   else
       fval_old=$(cat $FVAL_OLD)
       step_old=$(cat $STEP_OLD)
       gtp_old=$(cat $GTP_OLD)
   fi
fi
   


if [ "$OPT_METHOD" == "SD" ] || [ "$OPT_METHOD" == "NLCG" ]; then
    linesearch="bracket"
elif [ "$OPT_METHOD" == "LBFGS" ]; then
    linesearch="backtrack"
fi


cd $WORKFLOW_DIR
cd line_search

step_max=$(awk -v a="$gtg" 'BEGIN {b=0.15;print b/a}')
echo "fval : " $fval
echo "step : " $step
echo "gtg : " $gtg
echo "gtp : " $gtp
echo "step_trials : " $step_trials
echo "step_max : " $step_max
echo "line serach : " $linesearch
echo "work dir : " $WORK_DIR

# Removing previous files
rm -f alpha
rm -r steps
rm -r status



if [ ! -e "$RESULTS/model_gll_0.bp" ]; then
    echo "Copying $SIMULATION_DIR/DATA/GLL/model_gll.bp $RESULTS/model_gll_0.bp"
    cp -v $SIMULATION_DIR/DATA/GLL/model_gll.bp $RESULTS/model_gll_0.bp
fi


if [ $OLD_ITER -eq 1 ]; then
    
    python line_search.py -workdir $WORK_DIR  -funcval $fval -funcval_old $fval_old  \
	   -step $step -step_old $step_old -step_max "$step_max" -gtg $gtg -gtp $gtp -gtp_old $gtp_old -step_trials $step_trials \
	   -line_search "$linesearch"

    check_status $?

    echo "funval old : " $fval_old
    echo "step old : " $step_old
    echo "gtp old : " $gtp_old
    
else
    python line_search.py -workdir "$WORK_DIR" -funcval "$fval"  \
	   -step "$step" -step_max "$step_max" -gtg "$gtg" -gtp "$gtp" -step_trials "$step_trials" \
	   -linesearch "$linesearch"

    check_status $?
    
fi

if [ ! -e "alpha" ] || [ ! -e "status" ];then echo "status and step files from line search not found!";exit 1;fi
step_ls=$(cat alpha)
status_ls=$(cat status)

cd $WORK_DIR

if [ $status_ls -eq 1 ]; then
    echo "step found: $step status: $status_ls"

    workflow_py_update_model.sh $PAR_INV $step_ls $verbose
    check_status $?

    mv $RESULTS/model_gll_test.bp $RESULTS/model_gll_new.bp
fi

check_status 0 $(basename $0)
exit 0





