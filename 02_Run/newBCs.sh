#!/bin/bash

rm -rf ./postProcessing ./0
cp -r 0.org/. 0
decomposePar -fields
mpirun -np 22 -bind-to core -bind-to socket renumberMesh -overwrite -parallel
mpirun -np 22 -bind-to core -bind-to socket potentialFoam -parallel -initialiseUBCs
mpirun -np 22 -bind-to core -bind-to socket pimpleFoam -parallel > logRun &