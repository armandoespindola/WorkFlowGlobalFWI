#!/bin/bash

# This program compiles both binearies forward and adjoint

if [ $# -lt 4 ]; then
    echo "usage: ./workflow_py_compile_binaries.sh PAR_INV GPU[1==on/0==off] BINARIES[1==forward/2==adjoint] verbose[false=0/true=1]"
    exit 1
fi

PAR_INV=$1
GPU=$2
BINARIES=$3
verbose=$4

. workflow_py_load_config.sh $PAR_INV $verbose

printf "SPECFEM DIR: %s\nGPU[1==on/0==off]: %s\nBINARIES[1==forward/2==adjoint]: %s\n" \
       $SPECFEM_DIR $GPU $BINARIES
echo "SETUP DATE: $(date)"
echo


cd $SIMULATION_DIR

# SIMULATION FULL DIR
FULL_DIR=$(pwd)

echo " ### COMPILING SPECFEM ###"
echo "SIMULATION PATH: $FULL_DIR"

# select binary folder
if [ "$BINARIES" == "1" ]; then
    BINARIES_DIR=bin.forward
    sed -i "s/SAVE_FORWARD                    = .*/SAVE_FORWARD                    = .false./g" DATA/Par_file
    sed -i "s/UNDO_ATTENUATION                = .*/UNDO_ATTENUATION                = .false./g" DATA/Par_file
elif [ "$BINARIES" == "2" ]; then
    BINARIES_DIR=bin.kernel
    sed -i "s/SAVE_FORWARD                    = .*/SAVE_FORWARD                    = .true./g" DATA/Par_file
    sed -i "s/UNDO_ATTENUATION                = .*/UNDO_ATTENUATION                = .true./g" DATA/Par_file
else
  echo "BINARIES: $BINARIES - not suported, please choose 1==forward/2==adjoint"; exit 1
fi


cd $SPECFEM_DIR

cp -p -v $FULL_DIR/DATA/Par_file DATA/

echo
echo "COMPILING..."
echo


./mk_marconi100.sh $BINARIES

if [ $? -ne 0 ]; then echo ""; exit 1; fi
if [ ! -e $BINARIES_DIR/xspecfem3D ]; then echo "COMPILATION FAILED, PLEASE CHECK..."; exit 1; fi

# Copy bin files to 
cd $FULL_DIR
rm -r bin/*
cp $SPECFEM_DIR/$BINARIES_DIR/* bin/


echo
echo
echo "SIMULATION COMPILED SUCCESSFULLY"
echo "BINARIES: $BINARIES $BINARIES_DIR"
echo "\$ cd $FULL_DIR/"
echo
echo
