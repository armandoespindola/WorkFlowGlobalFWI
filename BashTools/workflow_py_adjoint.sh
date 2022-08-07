#!/bin/bash

trap " check_status 1 $0 "  ERR

if [ $# -lt 2 ]; then echo "usage: ./workflow_py_adjoint.sh PAR_INV verbose[false==0/true==1]"; exit 1; fi

PAR_INV=$1
verbose=$2


# Loading env variables
. workflow_py_load_config.sh  $PAR_INV $verbose

KERNELS_TYPE=$(sed -n 1p $KERNEL_PARFILE)

if [ "$KERNELS_TYPE" == "ISO" ] 
then
    sed -i "s/SAVE_TRANSVERSE_KL_ONLY.*/SAVE_TRANSVERSE_KL_ONLY         = .false./g" ${SIMULATION_DIR}/DATA/Par_file
    sed -i "s/ANISOTROPIC_KL.* /ANISOTROPIC_KL                  = .false./g" ${SIMULATION_DIR}/DATA/Par_file
elif [ "$KERNELS_TYPE" == "TISO" ]
then
    echo -ne "\n|---> TISO Model Parameters <---|\n"
    sed -i "s/SAVE_TRANSVERSE_KL_ONLY.*/SAVE_TRANSVERSE_KL_ONLY         = .true./g" ${SIMULATION_DIR}/DATA/Par_file
    sed -i "s/ANISOTROPIC_KL.* /ANISOTROPIC_KL                  = .true./g" ${SIMULATION_DIR}/DATA/Par_file
else
    echo -ne "Model parameters option not found \"$KERNELS_TYPE\". Possible options: ISO,TISO\n"
    echo -ne "Please check file $WORK_DIR/${KERNEL_PARFILE}\n"
    exit 1
fi

     
workflow_py_compile_binaries.sh $PAR_INV 1 2 1
check_status $?

events_list=$(grep -v ^# "${WORKFLOW_DIR}/${EVENT_FILE}")
events=$(echo $events_list | sed "s/[a-z]0*//g" | sed "s/ /,/g")

cd $SIMULATION_DIR

# Check if events folders exist
for ievent in $events_list
do
    if [ ! -d $ievent ]; then echo "Event folder -> $ievent not found"; exit 1;fi
done

copy_mesh2events.sh "${WORKFLOW_DIR}/${EVENT_FILE}"  $verbose
check_status $?


# Change simulation Par_file
cp DATA/Par_file DATA/Par_file.org
./change_simulation_type.pl -b

cd $WORK_DIR

workflow_py_copy_adjoint.sh $PAR_INV 0 $verbose
check_status $?

if [ $? -ne 0 ]; then echo " Mesh error "; exit 1; fi

# cd $SIMULATION_DIR

# sed -i "s/--array=.*/--array=[${events}]/" $SBATCH_ADJOINT

# # DO NOT FORGET TO QUOTE THE JOB VARIABLE
# slurm_monitor.sh "$SBATCH_ADJOINT" "$events_list" $verbose
# check_status $? "$SBATCH_ADJOINT"
cd $WORK_DIR
workflow_py_multiple_runs.sh $PAR_INV "adjoint" $verbose
check_status $?

if [ $KERNELS_ATTENUATION -eq 1 ]
then
    events=($(grep -v ^# "$WORKFLOW_DIR/$EVENT_FILE"))
    for ievent in ${events[@]}
    do
	mv -v $SIMULATION_DIR/$ievent/OUTPUT_FILES/kernels.bp \
	   $SIMULATION_DIR/$ievent/OUTPUT_FILES/kernels.elastic.bp
    done
    
    sed -i "s/SAVE_TRANSVERSE_KL_ONLY.*/SAVE_TRANSVERSE_KL_ONLY         = .false./g" ${SIMULATION_DIR}/DATA/Par_file
    sed -i "s/ANISOTROPIC_KL.* /ANISOTROPIC_KL                  = .false./g" ${SIMULATION_DIR}/DATA/Par_file
    workflow_py_compile_binaries.sh $PAR_INV 1 2 1
    check_status $?
    workflow_py_copy_adjoint.sh $PAR_INV 1 1
    workflow_py_multiple_runs.sh $PAR_INV "adjoint" $verbose
    check_status $?
fi


cd $SIMULATION_DIR
mv DATA/Par_file.org DATA/Par_file
./change_simulation_type.pl -F

check_status 0 $(basename $0)
exit 0
