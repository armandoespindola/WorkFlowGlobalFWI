#!/bin/bash
# 
#SBATCH --job-name="run SPECFEM3D_GLOBE"
#SBATCH --nodes=6
#SBATCH --ntasks=24
#SBATCH --ntasks-per-node=4
#
##SBATCH --gres=gpu:4         # 4 gpus per node out of 4
##SBATCH --exclusive          # node allocation exclusive for this job
##SBATCH --constraint=gpu
##SBATCH --mem=4096          # memory per node out of 246,000 MB
#
#SBATCH --time=01:00:00
#SBATCH --output=output/mesher.o
#SBATCH --error=output/mesher.o
#
#SBATCH --partition=m100_usr_preempt
##SBATCH --partition=m100_usr_prod
##SBATCH --qos=m100_qos_bprod
#
#SBATCH --account=Pra22_5560


###################################################

NPROC=24

##################################################

# user output
echo "job: $SLURM_JOB_NAME"
echo
echo "number of nodes: $SLURM_JOB_NUM_NODES"
echo
echo "tasks per node       : $SLURM_NTASKS_PER_NODE"
echo "total number of tasks: $SLURM_NTASKS"
echo
echo "On which nodes it executes" 
echo $SLURM_JOB_NODELIST 
echo

mkdir -p OUTPUT_FILES
rm OUTPUT_FILES/*
cp -v DATA/Par_file OUTPUT_FILES/
cp -v DATA/STATIONS OUTPUT_FILES/
cp -v DATA/CMTSOLUTION OUTPUT_FILES/

echo
echo "running mesher: `date`"
echo "directory: `pwd`"
echo

# spectrum-mpi
mpirun --rank-by core -np $NPROC ./bin/xmeshfem3D
# other mpi 
#srun -n $NPROC ./bin/xmeshfem3D
if [[ $? -ne 0 ]]; then exit 1; fi

echo "done: `date`"

# backup important files addressing.txt and list*.txt 
BASEMPIDIR=`grep LOCAL_PATH DATA/Par_file | cut -d = -f 2 | awk '{print $1}' `
echo "databases directory: $BASEMPIDIR/"
if [ -e "$BASEMPIDIR/" ]; then
  cp -v OUTPUT_FILES/*.txt $BASEMPIDIR/
  #rm -rf $BASEMPIDIR/OUTPUT_FILES
  #cp -rp OUTPUT_FILES $BASEMPIDIR/
fi

