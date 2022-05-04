#!/bin/bash
#SBATCH --job-name="KERNEL"
#SBATCH --nodes=6
#SBATCH --ntasks=24
#SBATCH --ntasks-per-node=4
#SBATCH --ntasks-per-socket=2
#SBATCH --array=[1]
#SBATCH --gres=gpu:4
#SBATCH --time=00:10:00
#SBATCH --output=output/kernel_%a.o
#SBATCH --error=output/kernel_%a.o
#SBATCH --partition=m100_usr_preempt
#SBATCH --account=Pra22_5560

NPROC=$SLURM_NTASKS

mpirun --rank-by core -np $NPROC ./bin.kernel/xsum_kernels /m100_scratch/userexternal/aespindo/ITER/event_kernel_sum /m100_scratch/userexternal/aespindo/ITER/kernel_sum.bp

if [ $? -ne 0 ]; then
echo " Error in Kernel_Sum"
exit 1
fi

mpirun --rank-by core -np $NPROC ./bin/xsmooth_sem_adios 500.0 200.0 mu_kl_crust_mantle /m100_scratch/userexternal/aespindo/ITER/kernel_sum.bp /m100_scratch/userexternal/aespindo/base_model/DATABASES_MPI/solver_data.bp /m100_scratch/userexternal/aespindo/ITER/gradient.bp .true.

if [ $? -ne 0 ]; then
echo " Error in Kernel_Smoothing"
exit 1
fi
