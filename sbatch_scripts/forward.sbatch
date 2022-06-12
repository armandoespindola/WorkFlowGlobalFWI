#!/bin/bash
#SBATCH --job-name="FORWARD"
#SBATCH --nodes=12
#SBATCH --ntasks=48
#SBATCH --ntasks-per-node=4
#SBATCH --ntasks-per-socket=2
#SBATCH --gres=gpu:4
#SBATCH --time=00:10:00
#SBATCH --output=output/forward_:job_id:.o
#SBATCH --error=output/forward_:job_id:.o
#SBATCH --partition=m100_usr_preempt
##SBATCH --partition=m100_usr_prod
#SBATCH --account=Pra22_5560


###################################################

NPROC=48

###################################################


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

# checks exit code
if [[ $? -ne 0 ]]; then exit 1; fi

echo "  forward run done: `date`"
echo


