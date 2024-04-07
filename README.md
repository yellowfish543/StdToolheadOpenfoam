# StdToolheadOpenfoam

![Banner!](images/banner.png "Test Case Results")

Standardised CFD workflow for 3d printer toolhead analysis based on Openfoam.com
<br><br>This repository aims to provide a standardised methodology for CFD analysis.
<br>The workflow follows the process outlined below:
1) Geometry preparation
2) Fluid domain generation
3) Boundary condition calculation
4) Mesh configuration
5) Case configuration including any additional parameter processing
6) Case execution and monitoring
7) Post-processing

The workflow uses software freely available for non-commercial use:
* Fusion 360 - CAD and Geometry Preparation (steps 1 & 2)
* Excel - Boundary condition calcs (step 3) - Ok so not free but readily available, can be migrated to python at some point   
* VSCode - All interfacing with Openfoam setup and execution as well as launching paraFoam/paraView for post-processing - (Steps 4-7)
* OpenFOAM v2306 - Openfoam.com flavour (largely the same as .org but syntax varies) (steps 4-6)
* ParaFOAM - Post-processor bundled into OpenFOAM, could also use ParaView either in Linux or Windows (step 7)

## Folder Structure
This workflow assumes a common folder structure:
<br>	`./<CaseName>/01_Geometry`
<br> 	`./<CaseName>/02_Run`
<br>	`./<CaseName>/03_Calcs`
<br><br>**Note** that the pre-run cleanup script will update the mesh geometry based on the contents of `./<CaseName>/01_Geometry` 

## OpenFOAM versions

The scripts are developed for running on v2306 of [OpenFOAM.com](https://develop.openfoam.com/Development/openfoam/-/wikis/precompiled)
The [Windows 10 installation guide](https://www.openfoam.com/download/openfoam-installation-on-windows-10) on the OpenFOAM website will install v2012. In order to install v2306 please use the following guide:
[https://develop.openfoam.com/Development/openfoam/-/wikis/precompiled/windows](https://develop.openfoam.com/Development/openfoam/-/wikis/precompiled/windows)
If you choose v2012 use the [./0.org/p_v2012](./02_Run/0.org/p_v2012) pressure boundary condition. **Note:** The file will need to be renamed to `p`

## CFD basics

Keeping this very brief as there are numerous far better guides than I could give, however this is aimed at providing the key points to enable a user to generate a CFD model, not understand it fully.<br>
A simulation is based on a domain, this is the volume you are modelling the fluid flow in (in our case, the fluid is air).<br>
The domain will have 3 classes of boundaries:  
1) Walls - no fluid passes through these
2) Inlets - Regions where fluid comes into the domain
3) Outlet - Regions where fluid exits the domain

In this workflow, the inlets are fan outlets. They are modelled as a uniform velocity based on a fan flow function curve (pressure drop relative to volumetric flow rate)<br>
The outlet is the atmosphere around the toolhead. The simulation will calculate the direction and velocity of the flow out of the domain.<br>
The simulation is run incompressible. This is due to the mach numbers generally being low (<0.3, or a velocity <100 m/s). This assumption may not be valid for the prediction of something like berd air or other very high pressure inlet.<br><br>
CFD can be run in a number of ways. The most common is to run it steady-state, in doing so there is an assumption that the flow is stable and doesn't change with time. This allows for faster calculations and is applicable to many applications. Steady-state predictions are less accurate for unstable flows, and unfortunately, cooling for toolheads can frequently fall into this category, specifically with poorly optimised designs or new concepts in their early development. Running these geometries steady state can lead to convergence issues and invalid predictions.<br><br>
To counter this, the models in this workflow are run transiently. This is a key reason for using a local copy of OpenFOAM as it is not possible in other free software options like simscale with a free license. Essentially the simulation will run from the starting of the cooling fans through to a fully developed flow. By running transiently it is possible to detect aerodynamic instabilities. This does increase the run time, however it is reasonably efficient and comparable to the time taken to print and test a concept.<br><br>
This is achieved through using clean, de-featured geometry and targeted mesh refinement. Typically this will solve within a couple of hours, although exact times vary significantly depending on CPU, and to a lesser extent, RAM performance.

## Step 1: Pre-Flight Checks

Before jumping in to running a new case, install openFoam, get vscode working, **run the case in this repo** and check the results in paraFoam. The following guide gives detail on how this case has been constructed and by following through the tutorial example the user should be able to generate their own case but OpenFOAM is a relatively complex suite of software and therefore it's worth while taking the time to run the tutorial case first and check everything is working as expected before generating something new.

OpenFOAM also have some tutorials which will both give a good intro to the software to both run cases and visualise the results as well as flushing out any issues with a specific installation:
[https://wiki.openfoam.com/"first_glimpse"_series](https://wiki.openfoam.com/%22first_glimpse%22_series)

## Step 2: Geometry Preparation

Geometry preparation is critical to high quality meshes and convergence. The geometry will also directly impact the mesh size and hence solution time.<br>
The following is given as an example of the preparation and which can then be used on your own geometry. [https://a360.co/3PRtX5L](https://a360.co/3PRtX5L)<br>
Additionally, the tutorial Fusion 360 file is stored in [01_Geometry/CFD_v30_touching v2.f3d](./01_Geometry/CFD_v30_touching%20v2.f3d)<br>

The initial steps are as follows:
1) Start with the basic arrangement of the geometry and add part geometry to simulate more realistic restrictions about the nozzle.
![Basic Arrangement of the toolhead, nozzle and simulated part!](images/BasicArrangement.png "Basic Arrangement")
2) Simplify the duct and nozzle geometry. Removing small faces and insignificant features will significantly reduce the mesh size and in turn, the simulation run-time.
3) Define the fluid domain - Basically work out how much you want to model. Take a note of the min/max x,y,z coords for this domain.
![Simulation fluid domain!](images/fluidDomain.png "Fluid Domain")
4) Subtract the geometry from the fluid domain
![Final simulation fluid domain!](images/subtractedFluidDomain.png "Subtracted Fluid Domain")
5) Position the geometry with the origin (0,0,0) at the nozzle tip
![Origin Position - Front view!](images/originFront.png "Origin at Nozzle Tip")
![Origin Position - Isometric!](images/OriginIsometric.png "Origin at Nozzle Tip")
6) Un-stitch the domain and re-stitch faces based on the regions defined in step 2.
![Unstitched Solid Fluid Domain](images/unstiched.png "Unstitched Fluid Domain")
![Stitched Solid Fluid Domain based on boundary Conditions](images/stichedSurfaces.png "Stitched Fluid Domain")
    6.1) Domain inlets:
![Inlet Surfaces!](images/inletSurfaces.png "Inlet Surfaces")
    6.2) Domain outlet:
![Outlet Atmosphere Surfaces!](images/outletAtmosphereSurfaces.png "Outlet Atmosphere Surfaces")
    6.3) Buildplate walls:
![Buildplate Surfaces!](images/wallsBuildplateSurfaces.png "Buildplate Surfaces") 
    6.4) Nozzle walls:
![Nozzle Surfaces!](images/wallsNozzleSurfaces.png "Nozzle Surfaces")
    6.5) Dummy part walls:
![Dummy Part Surfaces!](images/wallsPartSurfaces.png "Dummy Part Surfaces")
    6.6) Duct outer walls:
![Duct Outer Surfaces!](images/wallsSurfaces.png "Duct Outer Surfaces")
    6.7) Duct internal walls:
![Duct Internal Surfaces!](images/wallsDuctSurfaces.png "Duct Internal Surfaces")
7) Generate solid bodies for the refinement zones about the part and nozzle.<br>
    7.1) Nozzle refinement:
![Nozzle refinement region](images/nozzleRefinement.png "Nozzle refinement region")
    7.2) Part refinement:
![Part refinement region](images/partRefinement.png "Part refinement region")
10) Convert grouped faces to mesh
11) Combine meshes as required (ie. left and right duct outer walls into 'walls')
![Merging Mesh Groups for walls](images/mergedWalls.png "Merging Mesh Groups")
12) Export all mesh and solid bodies as stl's (in _**meters**_)
![Select mesh body for export](images/exportMesh1.png "Select mesh body for export")
![Export as ASCII STL in meters](images/exportMesh2.png "Export as ASCII STL in meters")
13) Save all stls in <code>./01_Geometry/</code>

## Step 3: Fluid Domain Generation

The fluid domain is generated using the exported stl's containing the surfaces which make up a given <code>patch</code> or <code>wall</code>
- A patch is used to define boundary conditions, such as a domain inlet or outlet.
- Walls are sub-divided to enable mesh refinement in given regions, hence multiple stl's are required for the walls.

Volumetric regions (created as solid bodies in Fusion 360) are also used for mesh refinement, specifically fine refinement around the nozzle and moderate refinement around the part.

The following stl's are required for the templates to complete meshing without modification: 

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

The walls are split to allow more detailed refinement during meshing, allowing higher resolution in specific regions of flow sensitivity. This refinement is to generally capture the flow separations from the walls and hence is focused on the internal geometry of the cooling ducts. The external geometry of the ducts requires a level of refinement beyond the background mesh but can be reduced to keep computational cost to a minimum.<br>
The refinement regions ensure a good level of resolution is achieved where the flow interacts with the part geometry and is further refined directly around the nozzle.<br>
Whilst modelling details of the surroundings, such as gantries, detailed print beds or surrounding features like nozzle brushes could be included, the models purpose is to refine print cooling and any additional complexity is likely to lead to issues with meshing and hence should be avoided. The user should only include geometry which has a first order impact on the results.<br>
Whilst developing this workflow, a number of studies were completed, such as the impact of leaving a gap between the nozzle and the part. There was no appreciable impact on the overall flowfield around the nozzle, however the mesh required significant refinement and therefore additional computational cost.

## Step 4: Mesh Configuration

Meshing is completed in a number of steps.
1) blockMesh is generated for the fluid domain. This is the background mesh and will be refined.
2) The mesh is decomposed based on the number of processors solving the analysis
3) The geometry is processed to extract edges of the stl's
4) SnappyHexMesh refines the mesh around the geometry and refinement regions, generating the final analysis mesh<br>

The case is configured to run in parallel using openMPI on 16 processors.
  - The variable numProc has been set in [decomposParDict](./02_Run/system/decomposeParDict) file.
  - Running on a couple fewer cores than the PC has enables post-processing during a run (assuming there is sufficient system RAM).

The meshing has been configured with the following:
  * stls should be saved in meters
  * stls should be stored in `./<CaseName>/01_Geometry`
  
### OpenFoam Meshing Process
This guide will use the blockMesh and snappyHexMesh functions in OpenFoam. <br>
- blockMesh defines a background mesh. 
  - The size extents in X, Y & Z are user specified as min/max dimensions
  - The elements are uniform size based on the user defined element size 
- snappyHexMesh is used to complete the detailed meshing: 
  1) The uniform blockMesh is refined based on the user inputs for each stl or refinement region
  2) The solid (ie non-fluid) regions are remove based on the 'location in fluid' defined in the setup script
  3) The cells within the mesh which cross the walls defining the interface between the solid and fluid regions are then snapped to match the surface profile of the geometry
  4) The snapping and smoothing is iterated to meet mesh quality requirements for regularly sized cells.

A more detailed explanation of the processes can be found on the OpenFOAM wiki:<br>
blockMesh: [https://www.openfoam.com/documentation/user-guide/4-mesh-generation-and-conversion/4.3-mesh-generation-with-the-blockmesh-utility](https://www.openfoam.com/documentation/user-guide/4-mesh-generation-and-conversion/4.3-mesh-generation-with-the-blockmesh-utility)<br>
snappyHexMesh: [https://www.openfoam.com/documentation/user-guide/4-mesh-generation-and-conversion/4.4-mesh-generation-with-the-snappyhexmesh-utility](https://www.openfoam.com/documentation/user-guide/4-mesh-generation-and-conversion/4.4-mesh-generation-with-the-snappyhexmesh-utility)<br>

The blockMesh configuration is defined in [<code>./02_Run/system/blockMeshDict</code>](02_Run/system/blockMeshDict)<br>
The snappyHexMesh configuration is defined in [<code>./02_Run/system/snappyHexMeshDict</code>](02_Run/system/snappyHexMeshDict)<br><br>
The following sections detail the user configuration required, followed by some more basic modifications which may be required to refine the simulation depending on the specific geometry.<br>

### blockMesh configuration in blockMeshDict

The blockMeshDict, in [<code>./02_Run/system/blockMeshDict</code>](02_Run/system/blockMeshDict) requires the user to define the minimum and maximum extents of the fluid domain. This can relatively easily be measured in Fusion 360.<br> 
```
// Define corners of fluid volume in meters
xMin    -0.044;
xMax     0.044;
yMin    -0.060;
yMax     0.060;
zMin    -0.026;
zMax     0.032;
```
Measurements should be provided in **meters**<br>
It's strongly advised that the measurements are increased by 1mm in all directions to avoid issues with meshing.<br><br>
Additionally the user may want to increase the mesh refinement. This is not typically required, but included in this guide for completeness<br>
The background cell size, or blockSize is the largest size any cell in the mesh will be. For regions around the outlet this can be pretty coarse, with 3mm being a reasonable basis for most cases. The refinement in snappyHexMesh will ensure details around features like the ducts are properly resolved.<br>
```
// Define blockmesh element size - default is 3mm, this is the largest element in the mesh.
// Increase this to reduce mesh size and run time
blockSize 0.003;
```
### snappyHexMesh configuration in snappyHexMeshDict
snappyHexMesh is used to generate the final mesh from the basic grid generated in blockMesh. The mesher will calculate where the surfaces defining the fluid domain are, refine them to the user defined level and blend that refinement out away from the surfaces as defined by the user. Whilst a relatively powerful program it's also quite complex.<br>
The template included in this guide attempts to make this more accessible, with the following section outlining the general file structure of snappyHexMeshDict, with examples of core functions which the user may want to modify.<br>
This does not attempt to provide a comprehensive guide, instead this is more of a quick start guide which should allow someone to generate their own mesh for their own geometry.<br>
### Mesh refinement

Mesh refinement is used to decrease the cell size generated by the blockMesh. The case has been configured to use 2 approaches for this, surface refinement and volumetric refinement.
<br><br>The refinement is applied in regions of higher velocity, strong interaction between jets or regions of interest where details in the geometry may impact the results.
<br><br>Refinement is defined based on the level of reduction in the region relative to the blockMesh size, with each level halving the cell size. More details can be found in the [OpenFOAM guide](https://www.openfoam.com/documentation/guides/latest/doc/guide-meshing-snappyhexmesh).

#### Surface refinement

The focus of the wall refinement is in the ducts and nozzle, with the nozzle being more refined than the ducts
<br><br>The part and build plate have a level of refinement to ensure the geometry is well resolved, however the velocities slow significantly by this region and therefore significant refinement is not required.

#### Volumetric refinement

Volumetric refinement is used to capture the region of interaction between the opposing jets, as well as an additional highly resolved region between the part and the nozzle. Gaps require ~8 cells to properly resolve flow, however the low level of flow coupled with the resultant very small cells will significantly increase both run time and mesh size (ram requirements) and is not expected to significantly alter understanding.<br><br>
The preceding steps have generated a number of STL files to allow local refinement of the mesh in OpenFoam. This section will cover a brief overview of the meshing process followed by detail on how to control the mesh via the various dictionaries (setup files) within OpenFoam.

### Configuring snappyHexMeshDict

If the user has followed the naming convention in steps 2 and 3, the following sections are all that will require editing:
The mesher requires a point to be defined which lies within the fluid domain. This has been preset to be 25mm upstream of the nozzle on the central plane. Check that the design being modelled has this point within the fluid domain, or define an alternative location. Note, as always, dimensions are in meters.
```
locationInMesh (0.0 0.025 0.0);
```

For more advanced users the file is structured in the following way:
1) The meshing steps required are defined:
```
castellatedMesh true;
snap            true;
addLayers       false;
```
The castellation will refine the mesh around the surfaces are remove regions outside of the fluid domain. This will not provide smooth walls as the mesh is essentially cubes which are sub-divisions of the blockMesh.<br>
Next the mesher will snap the mesh to the surfaces. This provides a mesh which matches the geometry, although the quality of the mesh will be a function of a number of more detailed settings. This section defines that snapping is required.<br>
<code>addLayers</code> will generate prism layers, which better capture the boundary layer flow within the model. This allows for the near wall velocity gradients to be better modelled though refinement normal to the surface but doesn't refine the mesh in the plane of the surface, therefore it is a computationally efficient way to mesh.<br>
However the layer addition within snappyHexMesh is not very robust and therefore this modelling process as been built around mesh refinement within the castellation and snapping phases to avoid requiring layer addition. This is viable for the small models being used here, although would not scale to other applications, such as external aerodynamics of a car or wing.

2) The geometry required for the mesh is defined in the <code>geometry</code> section, with the example below showing how the inlet geometry is imported into the mesh. This structure is repeated for all stl's.  
```
geometry
{
    inletLeft
    {
        type triSurfaceMesh;
        file "inletLeft.stl";
    }
    inletRight
    {
        type triSurfaceMesh;
        file "inletRight.stl";
    }
...
}
```
One notable addition is the nozzle tip refinement, which is defined using a <code>searchableCylinder</code>, starting 1mm below the nozzle and extending to 3mm above the nozzle, with a 2.5mm radius. This allows for higher levels of refinement around the nozzle tip, however this is not actually used in the tutorial and left as a potentially useful example. snappyHexMesh has a number of basic shapes which can be defined in a similar manner, with further guidance in the [snappyHexMesh wiki](https://www.openfoam.com/documentation/guides/latest/doc/guide-meshing-snappyhexmesh).
```
    refinementNozzleTip
    {
        type            searchableCylinder;
        point1          (0 0 -1e-3);
        point2          (0 0  3e-3);
        radius          0.0025;
    }
```
3) castellatedMeshControls defines the settings used for the castellation step. This section contains the definition of the maximum number of cells for the mesh, the minimum cell size, how to blend between different cell sizes/levels of refinement and the default angular refinement.
```
castellatedMeshControls
{
    maxLocalCells   10000000;
    maxGlobalCells  10000000;
    minRefinementCells 10;
    maxLoadUnbalance 0.1;
    nCellsBetweenLevels 3;
    locationInMesh (0.0 0.025 0.0);
    allowFreeStandingZoneFaces true;
    resolveFeatureAngle 25;
```
This is followed by the features, which imports the *.eMesh files which define features like sharp edges in the geometry.
```
    features
    (
        {
            file "inletLeft.eMesh";
            level 2;
        }
        {
            file "inletRight.eMesh";
            level 2;
        }
    ...
    );
```
<details>
  <summary>eMesh Files</summary>
    The *.eMesh files are generated using the <code>02_Run/system/surfaceFeatureExtractDict</code>, which is a relatively basic file structure used to extract the geometric data from an stl:

      FoamFile
      {
          version         2;
          format          ascii;
          class           dictionary;
          object          surfaceFeaturesDict;
      }
      ...
      inletLeft.stl
      {
          extractionMethod extractFromSurface;
          extractFromSurfaceCoeffs { includedAngle 180; }
          writeObj yes;
      }

      inletRight.stl
      {
          extractionMethod extractFromSurface;
          extractFromSurfaceCoeffs { includedAngle 180; }
          writeObj yes;
      }
      ...
  If filenames are changed for the stl's then the <code>surfaceFeatureExtractDict</code> will require editing.
</details>
The level of refinement on a surface is defined in <code>refinmentSurfaces</code>. The extract below highlights a number of key parameters within this section. The first line sets the names of the geometry which the surface refinement applies to, so in this case the first row sets the inletLeft and inletRight to the same settings. The levels command defines the (<min> <max>) surface refinement. The minimum level is applied across the surface and the maximum level is applied to cells at locations where the surface angle exceeds the resolveFeatureAngle. The <code>patchInfo</code> sets the surface as either a patch (boundary condition), or a wall.<br>

```
refinementSurfaces
    {
        "(inletLeft|inletRight)"
        {
            level (2 3);
            patchInfo { type patch; }
        }
        outletAtmosphere
        {
            level (0 1);
            patchInfo { type patch; }
        }
        "(walls|wallsBuildplate)"
        {
            level (2 2);
            patchInfo { type wall; }
        }
    ...
    )
```

The final section in this part is the refinementRegions. In this example only an internal refinement is applied. In this case the initial number is set very high and the internal refinement level is based on the second number, so 3 in this specific example:


    refinementRegions
    {
        refinementNozzle
        {
            mode inside;
            levels ((1e3 3));
        }
        ...
    }
snappyHexMesh can also accept refinement based on the distance from a surface amongst other settings. 

The final parts of the setup file define the number of iterations and refinement tolerances required for the mesh. The settings have been defined to give a reasonably robust meshing process which produces reliably usable meshes. It's not recommended that these settings are modified. Generally issues with the meshing process are driven by the blockMesh bounding box, incorrect location in mesh or  geometry which isn't watertight (ie gaps between surfaces) or geometry which is overly complex and requires further simplification.

## Step 5: Boundary Condition Calculation

Template file includes suitable boundary conditions to simulate a 4010 GDSTime blower into ambient air
<br>The Case is run isothermal incompressible with k-Omega SST turbulence model.
<br><br>Supporting workbook to be added... 
<br>Further details to be added...
### Runtime considerations

This CFD is configured to run transiently. This ensures the CFD analysis is robust when solving unsteady flowfields (frequently caused by modelling opposing jets of air from the ducts) case is run transiently. It also allows the use of a fan pressure curve to determine the expected jet velocities for a given duct design.
<br><br>A transient analysis runs using time steps. The flowfield is re-calculated for each time step, in this case it's simulating the fan startup through to steady state operation.
<br><br>The analysis needs to be run sufficiently long that the flow has developed over the nozzle and stabilised. Testing has shown this is ~0.016s. The analysis is configured to run for 0.02s to give some headroom.
<br><br>The duration of a time step is set by the time taken for flow to pass through a cell within the simulation. Therefore a very fine mesh or a very high speed flow will lead to small time step being required and a longer run time. If the velocity is increased (ie more powerful fan is modelled) then the time required to reach a steady state condition is expected to reduce, however this should be monitored during the run using ParaFOAM to ensure the solution has reached a steady state condition.
<br><br>Before running very high velocity flows the user should consider whether it's required. If the flowfield is unchanged (likely to be the case for the low Mach numbers typically running), hand calculations are likely to be sufficient to estimate the velocity. 

## Step 6: Case Configuration
To be added... 

## Step 7: Case Execution

Before running the case ensure the number of processors in the run scripts are set according to [decomposParDict](./02_Run/system/decomposeParDict) 
<br><br>The following files need to be checked and updated as required:
- [miniMesh](./miniMesh)
- [allRun](./allRun)
- [newBCs.sh](./newBCs.sh)

The `mpirun` commands should be configured to ensure the number of processors `-np` is correct.
<br>For example, 16 processors are requested for the following command in [allRun](./allRun) 
<br>`mpirun -np 16 --use-hwthread-cpus renumberMesh -overwrite -parallel`
<details>
  <summary>Hyper Threading</summary>
The argument <code>--use-hwthread-cpus</code> enables hyper treads to be treated as cores. Typically simulation software runs slower using hyper threading, therefore should be disabled. Trials with this workflow haven't shown a significant impact and since it's expected the user will have a general use PC rather than a workstation, the mpi commands have been structed to use hyper threaded cores.
</details>
Open the <code>02_Run</code> folder in VSCode
<br>Open a terminal
<br>Run <code>sh allMesh</code>
<br>This will complete a folder clean up to remove any previous meshes, then generate a mesh, decompose for the number of processors and then run the boundary condition initialisation followed by pimpleFoam solver.
<br><bold>Note</bold> The cleanup script removed the geometry from the 02_Run folder and updates it from the 01_Geometry folder. This enables automated updating of the geometry but means the workflow will not run without the  

## Step 8: Post-processing

