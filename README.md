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
* Fusion 360 - CAD and Geometry Preparation (steps 1 & 2)
* Excel - Boundary condition calcs (step 3) - Ok so not free but readliy avaliable, can be migrated to python at some point   
* VSCode - All interfaceing with Openfoam setup and execution as well as launching paraFoam/paraView for post-processing - (Steps 4-7)
* OpenFOAM v2212 - Openfoam.com flavour (largely the same as .org but syntax varies) (steps 4-6)
* ParaFOAM - Post-processor bundled into OpenFOAM, could also use ParaView either in Linux or Windows (step 7)

## Folder Structure
This workflow assuems a common folder structure:
<br>	`./<CaseName>/01_Geometry`
<br> 	`./<CaseName>/02_Run`
<br>	`./<CaseName>/03_Calcs`

**Note** that the pre-run cleanup script will update the mesh geometry based on the contence of `./<CaseName>/01_Geometry` 

## Step 1: Geometry Preparation
To be added....

## Step 2: Fluid Domain Generation
details to be added...
The fluid domain is generated using stl's containing the surfaces which make up a given <code>patch</code>
<br>A patch is used to define boundary conditions, such as a domain inlet, outlet or a wall.
<br>Walls are sub-divided to enable mesh refinement in given regions, hence multiple stl's are required for the walls
<br>Volumetric regions are also used for mesh refinement, specifically fine refinment around the nozzle and moderate refinement around the part.

The following stl's are required for the meshing to work without modification: 

### Inlet
- inletLeft
- inletRight
### Outlet
- outletAtmosphere
### Walls
- walls
- wallsDuctLeft
- wallsDuctRight
- wallsNozzle
- wallsBuildplate
- wallsPart
### Refinement Regions
- refinementNozzle
- refinementPart

## Step 3: Boundary Condition Calculation
Template file includes suitable bounadry conditions to simulate a 4010 GDSTime blower into ambient air
<br>The Case is run isothermal incompressible with k-Omega SST turbulence model.
<br>Supporting workbook to be added... 

### Runtime considerations
This CFD is configured to run transiently. This ensures the CFD analysis is robust when solving unsteady flowfields (frequently caused by modelling opposing jets of air from the ducts) case is run transiently. It also allows the use of a fan pressure curve to determine the expected jet velocities for a given duct design.
<br><br>A transient analysis runs using time steps. The flowfield is re-calculated for each time step, in this case it's simulating the fan startup through to steady state operation.
<br><br>The analysis needs to be run sufficiently long that the flow has developed over the nozzle and stabilised. Testing has shown this is ~0.016s. The anlaysis is configured to run for 0.02s to give some headroom.
<br><br>The duration of a time step is set by the time taken for flow to pass through a cell within the simulation. Therefore a very fine mesh or a very high speed flow will lead to small time step being required and a longer run time. If the velocity is increased (ie more powerful fan is modelled) then the time required to reach a steady state condition is expected to reduce, however this should be monitored during the run using ParaFOAM to ensure the solution has reached a steady state condition.
<br><br>Before running very high velocity flows the user should consider whether it's required. If the flowfield is unchanged (likely to be the case for the low Mach numbers typically running), hand calculations are likely to be sufficient to estimate the velocity. 

## Step 4: Mesh Configuration
Meshing is completed in a number of steps.
1) blockMesh is generated for the fluid domain. This is the background mesh and will be refined.
2) The mesh is decomposed based on the number of processors solving the analysis
3) The geometry is processed to extract edges of the stl's
4) SnappyHexMesh refines the mesh around the geometry and refinement regions, generating the final analysis mesh

The case is configured to run in parallel using openMPI on 16 processors.
The variable numProc has been set in [decomposParDict](./02_Run/system/decomposeParDict) file.
Running on a couple few cores than the PC has enables post-processing during a run (assuming there is sufficient system RAM)
The meshing has been configured with the following:
* stl's should be saved in meters
* stl's should be stored in `./<CaseName>/01_Geometry`

When the fluid domain is modified the min/max coordinates must be updated in [blockMeshDict](./02_Run/system/blockMeshDict)
<br>The blockMesh domain should be larger than the fluid domain, therefore any values should be rounded up to the nearest 0.1mm
<br>eg. if the minimum corner point is (-60, -30, -25), the blockMeshDict should be updated to (-60.1, -30.1, -25.1)
<br>Issues with the blockMesh domain will result in a `world` patch being created and errors associates with boundary conditions not being provided during the decomposition of the mesh.

### Mesh refinement regions
<br> A number of mesh refinement regions are included in the baseline case. There is 

## Step 5: Case Configuration
To be added... 

## Step 6: Case Execution
before running the case ensure the number of processors in the run scripts are set according to [decomposParDict](./02_Run/system/decomposeParDict) 
The following files need to be checked and updated as required:
- [miniMesh](./miniMesh)
- [allRun](./allRun)
- [newBCs.sh](./newBCs.sh)

The `mpirun` commands should be configured to ensure the number of processors `-np` is correct.
<br>For example, 16 processors are requested for the following command in [allRun](./allRun) 
<br>`mpirun -np *16* --use-hwthread-cpus renumberMesh -overwrite -parallel`
<br>
<details>
  <summary>*Hyper Threading*</summary>
<br>The argument <code>--use-hwthread-cpus</code> enables hyper treads to be treated as cores. Typically simulation software runs slower using hyper threading, therefore should be disabled. Trials with this workflow havn't shown a significant impact and since it's expected the user will have a general use PC rather than a workstation, the mpi commands have been structed to use hyper threaded cores.
</details>

<br>Open the `02_Run` folder in VSCode
<br>Open a terminal
<br>Run `sh allMesh`
<br>This will complete a folder clean up to remove any previous meshes, then generate a mesh, decompose for the number of processors and then run the boundary condition initialisation followed by pimpleFoam solver.
<br>*Note* The cleanup script removed the geometry from the 02_Run folder and updates it from the 01_Geometry folder. This enables automated updating of the geometry but means the workflow will not run without the  

## Step 7: Post-processing

