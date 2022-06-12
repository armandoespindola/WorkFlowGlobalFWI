#!/bin/bash
#SBATCH --job-name="ADJOINT"
#SBATCH --nodes=6
#SBATCH --ntasks=24
#SBATCH --ntasks-per-node=4
#SBATCH --gres=gpu:4
#SBATCH --exclusive 
#SBATCH --time=00:15:00
#SBATCH --output=output/adjoint_:job_id:.o
#SBATCH --error=output/adjoint_:job_id:.o
#SBATCH --partition=m100_usr_preempt
##SBATCH --partition=m100_usr_prod
#SBATCH --account=Pra22_5560

###################################################

NPROC=$SLURM_NTASKS

###################################################

echo "running simulation: `date`"
echo "directory: `pwd`"
echo


# Preparing Simulation
## Forward run
cp DATA/Par_file DATA/Par_file.org
./change_simulation_type.pl -F
sleep 2

echo
echo "running solver..."
echo `date`
# spectrum-mpi
mpirun --rank-by core -np $NPROC ./bin/xspecfem3D

if [[ $? -ne 0 ]]; then exit 1; fi
sleep 1

##
## adjoint simulation
##
./change_simulation_type.pl -b

echo
echo `date`
echo "starting adjoint run in current directory $PWD"
echo

# spectrum-mpi
mpirun --rank-by core -np $NPROC ./bin/xspecfem3D

# checks exit code
if [[ $? -ne 0 ]]; then exit 1; fi

sleep 1

# restore original Par_file
mv -v DATA/Par_file.org DATA/Par_file
rm -v DATA/Par_file
rm -v DATABASES_MPI/save_forward_arrays_undoatt.bp
echo "  adjoint run done: `date`"
echo


