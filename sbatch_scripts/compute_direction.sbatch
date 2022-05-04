#!/bin/bash
#SBATCH --job-name="DIRECTION"
#SBATCH --nodes=1
#SBATCH --ntasks=24
#SBATCH --ntasks-per-node=24
#SBATCH --ntasks-per-socket=12
#SBATCH --array=[1]
#SBATCH --time=00:10:00
#SBATCH --output=output/direction_%a.o
#SBATCH --error=output/direction_%a.o
#SBATCH --partition=m100_usr_preempt
#SBATCH --account=Pra22_5560

NPROC=$SLURM_NTASKS

mpirun --rank-by core -np $NPROC ./bin.kernel/xsteepDescent /m100_scratch/userexternal/aespindo/ITER/gradient.bp /m100_scratch/userexternal/aespindo/ITER/precond.bp /m100_scratch/userexternal/aespindo/base_model/DATABASES_MPI/solver_data.bp direction_SD.bp

if [ $? -ne 0 ]; then
echo "Compute Direction"
exit 1
fi
