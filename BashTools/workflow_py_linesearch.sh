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
    #python print_linesearch.py "."
    python generate_path_files.py "misfit"
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
       if [ ! -e $FVAL_OLD ]; then echo "$FVAL_OLD not found"; exit 1; fi
       fval_old=$(cat $FVAL_OLD)
       if [ ! -e $STEP_OLD ]; then echo "$STEP_OLD not found"; exit 1; fi
       step_old=$(cat $STEP_OLD)
       if [ ! -e $GTP_OLD ]; then echo "$GTP_OLD not found"; exit 1; fi
       gtp_old=$(cat $GTP_OLD)
   fi
fi
   


if [ "$OPT_METHOD" == "SD" ] || [ "$OPT_METHOD" == "NLCG" ]; then
    linesearch="bracket"
    #step_max=$(awk -v a="$gtg" 'BEGIN {b=0.15;print b/a}')
    max_val=$(grep -o max_val.* $SIMULATION_DIR/output/direction_1.o | cut -d : -f2)
    step_max=$(awk -v a="$max_val" 'BEGIN {b=0.15;print b/a}')
    step="0.0"
elif [ "$OPT_METHOD" == "LBFGS" ]; then
    linesearch="backtrack"
    max_val=$(grep -o max_val.* $SIMULATION_DIR/output/direction_1.o | cut -d : -f2)
    step_max=$(awk -v a="$max_val" 'BEGIN {b=0.15;print b/a}')
fi


cd $WORKFLOW_DIR
cd line_search

echo "# Line Search #" > $RESULTS/linesearch.par.dat
echo "fval : " $fval >> $RESULTS/linesearch.par.dat
echo "step : " $step >> $RESULTS/linesearch.par.dat
echo "gtg : " $gtg >> $RESULTS/linesearch.par.dat
echo "gtp : " $gtp >> $RESULTS/linesearch.par.dat
echo "step_trials : " $step_trials >> $RESULTS/linesearch.par.dat
echo "step_max : " $step_max >> $RESULTS/linesearch.par.dat
echo "line serach : " $linesearch >> $RESULTS/linesearch.par.dat
echo "work dir : " $WORK_DIR >> $RESULTS/linesearch.par.dat

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

    mv -v $RESULTS/model_gll_test.bp $RESULTS/model_gll_new.bp
fi

check_status 0 $(basename $0)
exit 0





