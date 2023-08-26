#!/bin/bash

rm -rf ./postProcessing ./0
cp -r 0.org/. 0
decomposePar -fields
mpirun -np 16 --use-hwthread-cpus renumberMesh -overwrite -parallel
mpirun -np 16 --use-hwthread-cpus potentialFoam -parallel -initialiseUBCs
mpirun -np 16 --use-hwthread-cpus pimpleFoam -parallel > logRun &
