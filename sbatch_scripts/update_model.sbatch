#!/bin/bash
#SBATCH --job-name="UPDATE"
#SBATCH --nodes=1
#SBATCH --ntasks=24
#SBATCH --ntasks-per-node=24
#SBATCH --ntasks-per-socket=12
#SBATCH --array=[1]
#SBATCH --time=00:10:00
#SBATCH --output=output/update_%a.o
#SBATCH --error=output/update_%a.o
#SBATCH --partition=m100_usr_preempt
#SBATCH --account=Pra22_5560

NPROC=$SLURM_NTASKS

mpirun --rank-by core -np $NPROC ./bin.kernel/xupdate_model_par 0.01 /m100_scratch/userexternal/aespindo/ITER/model_gll_0.bp /m100_scratch/userexternal/aespindo/base_model/DATABASES_MPI/solver_data.bp /m100_scratch/userexternal/aespindo/ITER/direction_SD.bp /m100_scratch/userexternal/aespindo/ITER/

if [ $? -ne 0 ]; then
echo "Update model"
exit 1
fi
