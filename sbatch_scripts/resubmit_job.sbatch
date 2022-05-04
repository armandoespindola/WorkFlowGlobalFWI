#!/bin/bash
#SBATCH --job-name="FORWARD"
#SBATCH --nodes=6
#SBATCH --ntasks=24
#SBATCH --ntasks-per-node=4
#SBATCH --ntasks-per-socket=2
#SBATCH --array=4
#SBATCH --gres=gpu:4
#SBATCH --time=00:10:00
#SBATCH --output=output/forward_%a.o
#SBATCH --error=output/forward_%a.o
#SBATCH --partition=m100_usr_preempt
#SBATCH --account=Pra22_5560


###################################################

NPROC=$SLURM_NTASKS

###################################################
RUN_DIR=$(printf "run%04d" $SLURM_ARRAY_TASK_ID)
cd $RUN_DIR

echo "running simulation: `date`"
echo "directory: `pwd`"
echo



# Preparing Simulation

## Forward run
echo
echo "running solver..."
echo `date`
# spectrum-mpi
mpirun --rank-by core -np $NPROC ./bin/xspecfem3D
sleep 1
rm -v DATA/Par_file

# checks exit code
if [[ $? -ne 0 ]]; then exit 1; fi

echo "  forward run done: `date`"
echo



