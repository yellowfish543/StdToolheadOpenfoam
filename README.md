# StdToolheadOpenfoam
Standardised CFD workflow for 3d printer toolhead analysis based on Openfoam.com

This repository aims to provide a standardised methodolodgy for CFD analysis.
The workflow follows the process outlined below:
1) Geometry preparation
2) Fluid domain generation
3) Boundary condition calculation
4) Mesh configuration
5) Case configuration including any additional parameter processing
6) Case execution and monitoring
7) Post-processing

The workflow uses software freely avaliable for non-commercial use:
  Fusion 360 - CAD and Geometry Preparation (steps 1 & 2)
  Excel - Boundary condition calcs (step 3) - Ok so not free but readliy avaliable, can be migrated to python at some point 
  VSCode - All interfaceing with Openfoam setup and execution as well as launching paraFoam/paraView for post-processing - (Steps 4-7)
  OpenFOAM v2212 - Openfoam.com flavour (largely the same as .org but syntax varies) (steps 4-6)
  ParaFOAM - Post-processor bundled into OpenFOAM, could also use ParaView either in Linux or Windows  

