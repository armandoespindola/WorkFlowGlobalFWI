#!/bin/bash

if [ $# -lt 1 ]; then
    echo "This program create links to xmeshfem3D output files"
    echo "event_file: list of events"
    echo "usage: ./copy_mesh2events.sh event_file verbose[false==0/true==1]"; exit 1;
fi

event_file=$1
verbose=$2

if [ -z "$verbose" ]; then
    verbose=0
fi


if [ ! -e $event_file ]; then echo "No $event_file file found. Please check!" ; exit 1; fi

events=($(grep -v ^# $event_file))


if [ $? -eq 0 ]; then
    if [ $verbose -eq 1 ]; then echo "Reading Event File: OK"; fi
else
    if [ $verbose -eq 1 ]; then echo "Reading Event File: ERROR"; fi
    exit 1
fi

if [ $verbose -eq 1 ]; then
    echo "Events: " ${events[@]}
fi


if [ $verbose -eq 1 ]; then
    echo "Copying files and creating symbolic links"
fi

	
	
for ievent in ${events[@]}
do

    if [ $verbose -eq 1 ]; then
    echo "##### : " $ievent
    fi
    
    
    # Set simulation for every run
    cd $ievent

    rsync -av ../change_simulation_type.pl ./
    #if [ -e ../DATA/GLL/model_gll.bp ]; then rsync -av ../DATA/model_gll.bp DATA/GLL/ ; fi
    rm  -v OUTPUT_FILES/*
    rm -v DATA/Par_file
    rsync -av ../bin/xspecfem3D bin/
    rsync -av ../DATA/Par_file DATA/
    rsync -av ../OUTPUT_FILES/*.txt OUTPUT_FILES/
    rsync -av ../OUTPUT_FILES/*.h OUTPUT_FILES/
    rm -rf DATABASES_MPI
    mkdir DATABASES_MPI
    cd DATABASES_MPI
    ln -sf ../../DATABASES_MPI/addressing.txt
    ln -sf ../../DATABASES_MPI/attenuation.bp
    ln -sf ../../DATABASES_MPI/boundary.bp
    ln -sf ../../DATABASES_MPI/proc000000_reg1_topo.bin
    ln -sf ../../DATABASES_MPI/solver_data.bp
    ln -sf ../../DATABASES_MPI/solver_data_mpi.bp
    cd ../
    cd ../
done





