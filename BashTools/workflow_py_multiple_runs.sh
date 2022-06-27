trap " clean_data " ERR SIGINT

function clean_data()
{
    rm -rvf $SIMULATION_DIR/run0*
    check_status 1 $(basename $0)
    }

if [ $# -lt 2 ]; then echo "usage: ./workflow_multiple_runs.sh PAR_INV simulation[forward/adjoint] verbose[false==0/true==1]"; exit 1; fi


PAR_INV=$1
simulation=$2
verbose=$3

# Loading env variables
. workflow_py_load_config.sh $PAR_INV $verbose
check_status $?

events=($(grep -v ^# "$WORKFLOW_DIR/$EVENT_FILE"))
nevents=${#events[@]}


count=$((nevents/NRUNS))
reminder=$((nevents%NRUNS))

sed -i "s/^NUMBER_OF_SIMULTANEOUS_RUNS.*/NUMBER_OF_SIMULTANEOUS_RUNS     = $NRUNS/g" $SIMULATION_DIR/DATA/Par_file

for ((i=0;i<=$count;i++))
do
    start_idx=$((i * NRUNS))
    end_idx=$(((i+1) * NRUNS - 1))
    
    if [ $i -eq $count ] && [ $reminder -gt 0 ]; then
	sed -i "s/^NUMBER_OF_SIMULTANEOUS_RUNS.*/NUMBER_OF_SIMULTANEOUS_RUNS     = $reminder/g" $SIMULATION_DIR/DATA/Par_file
	end_idx=$((i * NRUNS + reminder - 1))
    elif [ $i -eq $count ] && [ $reminder -eq 0 ]; then
	break
    fi

    echo "Running events from ${events[$start_idx]} to ${events[$end_idx]}"
    id_job=1
    for ((ievent=$start_idx;ievent<=$end_idx;ievent++))
    do
	cd $SIMULATION_DIR
	RUN_DIR=$(printf "run%04d" $id_job)
	rm -fv $RUN_DIR

	if [ -n "${events[$ievent]}" ]; then 
	    ln -s ${events[$ievent]}  $RUN_DIR
	    rm -fv $RUN_DIR/DATA/Par_file
	if [ $ievent -eq $start_idx ];then
	    rsync -av OUTPUT_FILES/*.txt $RUN_DIR/OUTPUT_FILES/
	    rsync -av OUTPUT_FILES/*.h $RUN_DIR/OUTPUT_FILES/
	    cd $RUN_DIR/DATABASES_MPI
	    ln -sf ../../DATABASES_MPI/addressing.txt
	    ln -sf ../../DATABASES_MPI/attenuation.bp
	    ln -sf ../../DATABASES_MPI/boundary.bp
	    ln -sf ../../DATABASES_MPI/proc000000_reg1_topo.bin
	    ln -sf ../../DATABASES_MPI/solver_data.bp
	    ln -sf ../../DATABASES_MPI/solver_data_mpi.bp
	    cd $SIMULATION_DIR
	fi

	else
	    echo "Error in events list"
	    exit 1
	fi

	((id_job++))
    done

    echo "Running events from ${events[$start_idx]} to ${events[$end_idx]}"
    events_list="1"
    # DO NOT FORGET TO QUOTE THE JOB VARIABLE
    NPROC_XI=$(grep -o NPROC_XI.* $SIMULATION_DIR/DATA/Par_file | cut -f2 -d"=")                         
    NPROC_ETA=$(grep -o NPROC_ETA.* $SIMULATION_DIR/DATA/Par_file | cut -f2 -d"=")                       
    NPROC=$((NPROC_XI * NPROC_ETA * 6))                                                                  
                                                                                                         
    NSIMUL=$(grep -o ^NUMBER_OF_SIMULTANEOUS.* $SIMULATION_DIR/DATA/Par_file | cut -f2 -d"=")            
    NPROC_TOTAL=$((NPROC * NSIMUL))                                                                      
    NODES=$(( (NPROC_TOTAL + (ARCH_PROC-1))/ARCH_PROC ))                                                 
    PPN=$(( NODES * ARCH_PROC ))

    if [ $simulation == "forward" ]; then
	echo "Forward Simulation"
	sed -i "s:^NPROC.*:NPROC=$NPROC_TOTAL:" $SBATCH_FORWARD                                          
        sed -i "s/^#SBATCH --ntasks=.*/#SBATCH --ntasks=$PPN/" $SBATCH_FORWARD                   
        sed -i "s/^#SBATCH --nodes=.*/#SBATCH --nodes=$NODES/" $SBATCH_FORWARD                           
        sed -i "s/^#SBATCH --ntasks-per-node=.*/#SBATCH --ntasks-per-node=$ARCH_PROC/" $SBATCH_FORWARD
	slurm_monitor.sh "$SBATCH_FORWARD" "$events_list" $verbose
	check_status $? "$SBATCH_FORWARD"
    fi

    if [ $simulation == "adjoint" ]; then
	echo "Adjoint Simulation"
	sed -i "s:^NPROC.*:NPROC=$NPROC_TOTAL:" $SBATCH_ADJOINT                                          
        sed -i "s/^#SBATCH --ntasks=.*/#SBATCH --ntasks=$PPN/" $SBATCH_ADJOINT                   
        sed -i "s/^#SBATCH --nodes=.*/#SBATCH --nodes=$NODES/" $SBATCH_ADJOINT                           
        sed -i "s/^#SBATCH --ntasks-per-node=.*/#SBATCH --ntasks-per-node=$ARCH_PROC/" $SBATCH_ADJOINT
	slurm_monitor.sh "$SBATCH_ADJOINT" "$events_list" $verbose
	check_status $? "$SBATCH_ADJOINT"
    fi
    
     
done

sed -i "s/^NUMBER_OF_SIMULTANEOUS_RUNS.*/NUMBER_OF_SIMULTANEOUS_RUNS     = 1/g" $SIMULATION_DIR/DATA/Par_file

check_status 0 $(basename $0)
exit 0
