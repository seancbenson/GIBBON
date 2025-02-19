%% DEMO_febio_0005_cube_tension_compression_shear
% Below is a demonstration for:
% 
% * Building geometry for a cube with hexahedral elements
% * Defining the boundary conditions 
% * Coding the febio structure
% * Running the model
% * Importing and visualizing the displacement and stress results

%% Keywords
%
% * febio_spec version 2.5
% * febio, FEBio
% * compression, tension, compressive, tensile, shear
% * displacement control, displacement boundary condition
% * hexahedral elements, hex8
% * cube, box, rectangular
% * static, solid
% * hyperelastic, Ogden
% * displacement logfile
% * stress logfile

%%

clear; close all; clc;

%% Plot settings
fontSize=20;
faceAlpha1=0.8;
markerSize=40;
lineWidth=3;

%% Control parameters

% Path names
defaultFolder = fileparts(fileparts(mfilename('fullpath')));
savePath=fullfile(defaultFolder,'data','temp');

% Defining file names
febioFebFileNamePart='tempModel';
febioFebFileName=fullfile(savePath,[febioFebFileNamePart,'.feb']); %FEB file name
febioLogFileName=fullfile(savePath,[febioFebFileNamePart,'.txt']); %FEBio log file name
febioLogFileName_disp=[febioFebFileNamePart,'_disp_out.txt']; %Log file name for exporting displacement
febioLogFileName_force=[febioFebFileNamePart,'_force_out.txt']; %Log file name for exporting force

%Specifying dimensions and number of elements
cubeSize=10; 
sampleWidth=cubeSize; %Width 
sampleThickness=cubeSize; %Thickness 
sampleHeight=cubeSize; %Height
pointSpacings=1*ones(1,3); %Desired point spacing between nodes
numElementsWidth=round(sampleWidth/pointSpacings(1)); %Number of elemens in dir 1
numElementsThickness=round(sampleThickness/pointSpacings(2)); %Number of elemens in dir 2
numElementsHeight=round(sampleHeight/pointSpacings(3)); %Number of elemens in dir 3

%Define applied displacement 
stretchLoad=1.3;
displacementMagnitude=(stretchLoad*sampleHeight)-sampleHeight; %The displacement magnitude

%Material parameter set
c1=1e-3; %Shear-modulus-like parameter
m1=8; %Material parameter setting degree of non-linearity
k_factor=1e2; %Bulk modulus factor 
k=c1*k_factor; %Bulk modulus

% FEA control settings
numTimeSteps=10; %Number of time steps desired
max_refs=25; %Max reforms
max_ups=0; %Set to zero to use full-Newton iterations
opt_iter=6; %Optimum number of iterations
max_retries=5; %Maximum number of retires
dtmin=(1/numTimeSteps)/100; %Minimum time step size
dtmax=1/numTimeSteps; %Maximum time step size

%% Creating model geometry and mesh
% A box is created with tri-linear hexahedral (hex8) elements using the
% |hexMeshBox| function. The function offers the boundary faces with
% seperate labels for the top, bottom, left, right, front, and back sides.
% As such these can be used to define boundary conditions on the exterior. 

% Create a box with hexahedral elements
cubeDimensions=[sampleWidth sampleThickness sampleHeight]; %Dimensions
cubeElementNumbers=[numElementsWidth numElementsThickness numElementsHeight]; %Number of elements
outputStructType=2; %A structure compatible with mesh view
[meshStruct]=hexMeshBox(cubeDimensions,cubeElementNumbers,outputStructType);

%Access elements, nodes, and faces from the structure
E=meshStruct.elements; %The elements 
V=meshStruct.nodes; %The nodes (vertices)
Fb=meshStruct.facesBoundary; %The boundary faces
Cb=meshStruct.boundaryMarker; %The "colors" or labels for the boundary faces
elementMaterialIndices=ones(size(E,1),1); %Element material indices

%% 
% Plotting model boundary surfaces and a cut view

hFig=cFigure; 

subplot(1,2,1); hold on; 
title('Model boundary surfaces and labels','FontSize',fontSize);
gpatch(Fb,V,Cb,'k',faceAlpha1); 
colormap(gjet(6)); icolorbar;
axisGeom(gca,fontSize);

hs=subplot(1,2,2); hold on; 
title('Cut view of solid mesh','FontSize',fontSize);
optionStruct.hFig=[hFig hs];
meshView(meshStruct,optionStruct);
axisGeom(gca,fontSize);

drawnow;

%% Defining the boundary conditions
% The visualization of the model boundary shows colors for each side of the
% cube. These labels can be used to define boundary conditions. 

%Define supported node sets
logicFace=Cb==5; %Logic for current face set
Fr=Fb(logicFace,:); %The current face set
bcSupportList=unique(Fr(:)); %Node set part of selected face

%Prescribed displacement nodes
logicPrescribe=Cb==6; %Logic for current face set
Fr=Fb(logicPrescribe,:); %The current face set
bcPrescribeList=unique(Fr(:)); %Node set part of selected face

%% 
% Visualizing boundary conditions. Markers plotted on the semi-transparent
% model denote the nodes in the various boundary condition lists. 

hf=cFigure;
title('Boundary conditions','FontSize',fontSize);
xlabel('X','FontSize',fontSize); ylabel('Y','FontSize',fontSize); zlabel('Z','FontSize',fontSize);
hold on;

gpatch(Fb,V,'kw','k',0.5);

hl(1)=plotV(V(bcSupportList,:),'k.','MarkerSize',markerSize);
hl(2)=plotV(V(bcPrescribeList,:),'r.','MarkerSize',markerSize);

legend(hl,{'BC support','BC prescribe'});

axisGeom(gca,fontSize);
camlight headlight; 
drawnow; 

%% Defining the FEBio input structure
% See also |febioStructTemplate| and |febioStruct2xml| and the FEBio user
% manual.

%Get a template with default settings 
[febio_spec]=febioStructTemplate;

%febio_spec version 
febio_spec.ATTR.version='2.5'; 

%Module section
febio_spec.Module.ATTR.type='solid'; 

%Create control structure for use by all steps
stepStruct.Control.analysis.ATTR.type='static';
stepStruct.Control.time_steps=numTimeSteps;
stepStruct.Control.step_size=1/numTimeSteps;
stepStruct.Control.time_stepper.dtmin=dtmin;
stepStruct.Control.time_stepper.dtmax=dtmax; 
stepStruct.Control.time_stepper.max_retries=max_retries;
stepStruct.Control.time_stepper.opt_iter=opt_iter;
stepStruct.Control.max_refs=max_refs;
stepStruct.Control.max_ups=max_ups;

%Add template based default settings to proposed control section
[stepStruct.Control]=structComplete(stepStruct.Control,febio_spec.Control,1); %Complement provided with default if missing

%Remove control field (part of template) since step specific control sections are used
febio_spec=rmfield(febio_spec,'Control'); 

febio_spec.Step{1}.Control=stepStruct.Control;
febio_spec.Step{1}.ATTR.id=1;
febio_spec.Step{2}.Control=stepStruct.Control;
febio_spec.Step{2}.ATTR.id=2;
febio_spec.Step{3}.Control=stepStruct.Control;
febio_spec.Step{3}.ATTR.id=3;
febio_spec.Step{4}.Control=stepStruct.Control;
febio_spec.Step{4}.ATTR.id=4;
febio_spec.Step{5}.Control=stepStruct.Control;
febio_spec.Step{5}.ATTR.id=5;

%Material section
febio_spec.Material.material{1}.ATTR.type='Ogden';
febio_spec.Material.material{1}.ATTR.id=1;
febio_spec.Material.material{1}.c1=c1;
febio_spec.Material.material{1}.m1=m1;
febio_spec.Material.material{1}.c2=c1;
febio_spec.Material.material{1}.m2=-m1;
febio_spec.Material.material{1}.k=k;

%Geometry section
% -> Nodes
febio_spec.Geometry.Nodes{1}.ATTR.name='nodeSet_all'; %The node set name
febio_spec.Geometry.Nodes{1}.node.ATTR.id=(1:size(V,1))'; %The node id's
febio_spec.Geometry.Nodes{1}.node.VAL=V; %The nodel coordinates

% -> Elements
febio_spec.Geometry.Elements{1}.ATTR.type='hex8'; %Element type of this set
febio_spec.Geometry.Elements{1}.ATTR.mat=1; %material index for this set 
febio_spec.Geometry.Elements{1}.ATTR.name='Cube'; %Name of the element set
febio_spec.Geometry.Elements{1}.elem.ATTR.id=(1:1:size(E,1))'; %Element id's
febio_spec.Geometry.Elements{1}.elem.VAL=E;

% -> NodeSets
febio_spec.Geometry.NodeSet{1}.ATTR.name='bcSupportList';
febio_spec.Geometry.NodeSet{1}.node.ATTR.id=bcSupportList(:);

febio_spec.Geometry.NodeSet{2}.ATTR.name='bcPrescribeList';
febio_spec.Geometry.NodeSet{2}.node.ATTR.id=bcPrescribeList(:);

%Boundary condition section 
% -> Fix boundary conditions
febio_spec.Boundary.fix{1}.ATTR.bc='x';
febio_spec.Boundary.fix{1}.ATTR.node_set=febio_spec.Geometry.NodeSet{1}.ATTR.name;
febio_spec.Boundary.fix{2}.ATTR.bc='y';
febio_spec.Boundary.fix{2}.ATTR.node_set=febio_spec.Geometry.NodeSet{1}.ATTR.name;
febio_spec.Boundary.fix{3}.ATTR.bc='z';
febio_spec.Boundary.fix{3}.ATTR.node_set=febio_spec.Geometry.NodeSet{1}.ATTR.name;

% -> Prescribe boundary conditions
%STEP 1 Tension
febio_spec.Step{1}.Boundary.prescribe{1}.ATTR.bc='z';
febio_spec.Step{1}.Boundary.prescribe{1}.ATTR.node_set=febio_spec.Geometry.NodeSet{2}.ATTR.name;
febio_spec.Step{1}.Boundary.prescribe{1}.scale.ATTR.lc=1;
febio_spec.Step{1}.Boundary.prescribe{1}.scale.VAL=1;
febio_spec.Step{1}.Boundary.prescribe{1}.relative=1;
febio_spec.Step{1}.Boundary.prescribe{1}.value=displacementMagnitude;

febio_spec.Step{1}.Boundary.prescribe{2}.ATTR.bc='x';
febio_spec.Step{1}.Boundary.prescribe{2}.ATTR.node_set=febio_spec.Geometry.NodeSet{2}.ATTR.name;
febio_spec.Step{1}.Boundary.prescribe{2}.scale.ATTR.lc=1;
febio_spec.Step{1}.Boundary.prescribe{2}.scale.VAL=1;
febio_spec.Step{1}.Boundary.prescribe{2}.relative=1;
febio_spec.Step{1}.Boundary.prescribe{2}.value=0;

febio_spec.Step{1}.Boundary.prescribe{3}.ATTR.bc='y';
febio_spec.Step{1}.Boundary.prescribe{3}.ATTR.node_set=febio_spec.Geometry.NodeSet{2}.ATTR.name;
febio_spec.Step{1}.Boundary.prescribe{3}.scale.ATTR.lc=1;
febio_spec.Step{1}.Boundary.prescribe{3}.scale.VAL=1;
febio_spec.Step{1}.Boundary.prescribe{3}.relative=1;
febio_spec.Step{1}.Boundary.prescribe{3}.value=0;

%STEP 2 Return form tension
febio_spec.Step{2}.Boundary.prescribe{1}.ATTR.bc='z';
febio_spec.Step{2}.Boundary.prescribe{1}.ATTR.node_set=febio_spec.Geometry.NodeSet{2}.ATTR.name;
febio_spec.Step{2}.Boundary.prescribe{1}.scale.ATTR.lc=2;
febio_spec.Step{2}.Boundary.prescribe{1}.scale.VAL=1;
febio_spec.Step{2}.Boundary.prescribe{1}.relative=1;
febio_spec.Step{2}.Boundary.prescribe{1}.value=-displacementMagnitude;

febio_spec.Step{2}.Boundary.prescribe{2}.ATTR.bc='x';
febio_spec.Step{2}.Boundary.prescribe{2}.ATTR.node_set=febio_spec.Geometry.NodeSet{2}.ATTR.name;
febio_spec.Step{2}.Boundary.prescribe{2}.scale.ATTR.lc=2;
febio_spec.Step{2}.Boundary.prescribe{2}.scale.VAL=1;
febio_spec.Step{2}.Boundary.prescribe{2}.relative=1;
febio_spec.Step{2}.Boundary.prescribe{2}.value=0;

febio_spec.Step{2}.Boundary.prescribe{3}.ATTR.bc='y';
febio_spec.Step{2}.Boundary.prescribe{3}.ATTR.node_set=febio_spec.Geometry.NodeSet{2}.ATTR.name;
febio_spec.Step{2}.Boundary.prescribe{3}.scale.ATTR.lc=2;
febio_spec.Step{2}.Boundary.prescribe{3}.scale.VAL=1;
febio_spec.Step{2}.Boundary.prescribe{3}.relative=1;
febio_spec.Step{2}.Boundary.prescribe{3}.value=0;

%STEP 3 Compression
febio_spec.Step{3}.Boundary.prescribe{1}.ATTR.bc='z';
febio_spec.Step{3}.Boundary.prescribe{1}.ATTR.node_set=febio_spec.Geometry.NodeSet{2}.ATTR.name;
febio_spec.Step{3}.Boundary.prescribe{1}.scale.ATTR.lc=3;
febio_spec.Step{3}.Boundary.prescribe{1}.scale.VAL=1;
febio_spec.Step{3}.Boundary.prescribe{1}.relative=1;
febio_spec.Step{3}.Boundary.prescribe{1}.value=-displacementMagnitude;

febio_spec.Step{3}.Boundary.prescribe{2}.ATTR.bc='x';
febio_spec.Step{3}.Boundary.prescribe{2}.ATTR.node_set=febio_spec.Geometry.NodeSet{2}.ATTR.name;
febio_spec.Step{3}.Boundary.prescribe{2}.scale.ATTR.lc=3;
febio_spec.Step{3}.Boundary.prescribe{2}.scale.VAL=1;
febio_spec.Step{3}.Boundary.prescribe{2}.relative=1;
febio_spec.Step{3}.Boundary.prescribe{2}.value=0;

febio_spec.Step{3}.Boundary.prescribe{3}.ATTR.bc='y';
febio_spec.Step{3}.Boundary.prescribe{3}.ATTR.node_set=febio_spec.Geometry.NodeSet{2}.ATTR.name;
febio_spec.Step{3}.Boundary.prescribe{3}.scale.ATTR.lc=3;
febio_spec.Step{3}.Boundary.prescribe{3}.scale.VAL=1;
febio_spec.Step{3}.Boundary.prescribe{3}.relative=1;
febio_spec.Step{3}.Boundary.prescribe{3}.value=0;

%STEP 4 Return from compression
febio_spec.Step{4}.Boundary.prescribe{1}.ATTR.bc='z';
febio_spec.Step{4}.Boundary.prescribe{1}.ATTR.node_set=febio_spec.Geometry.NodeSet{2}.ATTR.name;
febio_spec.Step{4}.Boundary.prescribe{1}.scale.ATTR.lc=4;
febio_spec.Step{4}.Boundary.prescribe{1}.scale.VAL=1;
febio_spec.Step{4}.Boundary.prescribe{1}.relative=1;
febio_spec.Step{4}.Boundary.prescribe{1}.value=displacementMagnitude;

febio_spec.Step{4}.Boundary.prescribe{2}.ATTR.bc='x';
febio_spec.Step{4}.Boundary.prescribe{2}.ATTR.node_set=febio_spec.Geometry.NodeSet{2}.ATTR.name;
febio_spec.Step{4}.Boundary.prescribe{2}.scale.ATTR.lc=4;
febio_spec.Step{4}.Boundary.prescribe{2}.scale.VAL=1;
febio_spec.Step{4}.Boundary.prescribe{2}.relative=1;
febio_spec.Step{4}.Boundary.prescribe{2}.value=0;

febio_spec.Step{4}.Boundary.prescribe{3}.ATTR.bc='y';
febio_spec.Step{4}.Boundary.prescribe{3}.ATTR.node_set=febio_spec.Geometry.NodeSet{2}.ATTR.name;
febio_spec.Step{4}.Boundary.prescribe{3}.scale.ATTR.lc=4;
febio_spec.Step{4}.Boundary.prescribe{3}.scale.VAL=1;
febio_spec.Step{4}.Boundary.prescribe{3}.relative=1;
febio_spec.Step{4}.Boundary.prescribe{3}.value=0;

%STEP 5 Shear
febio_spec.Step{5}.Boundary.prescribe{2}.ATTR.bc='x';
febio_spec.Step{5}.Boundary.prescribe{2}.ATTR.node_set=febio_spec.Geometry.NodeSet{2}.ATTR.name;
febio_spec.Step{5}.Boundary.prescribe{2}.scale.ATTR.lc=5;
febio_spec.Step{5}.Boundary.prescribe{2}.scale.VAL=1;
febio_spec.Step{5}.Boundary.prescribe{2}.relative=1;
febio_spec.Step{5}.Boundary.prescribe{2}.value=displacementMagnitude;

febio_spec.Step{5}.Boundary.prescribe{3}.ATTR.bc='y';
febio_spec.Step{5}.Boundary.prescribe{3}.ATTR.node_set=febio_spec.Geometry.NodeSet{2}.ATTR.name;
febio_spec.Step{5}.Boundary.prescribe{3}.scale.ATTR.lc=5;
febio_spec.Step{5}.Boundary.prescribe{3}.scale.VAL=1;
febio_spec.Step{5}.Boundary.prescribe{3}.relative=1;
febio_spec.Step{5}.Boundary.prescribe{3}.value=0;

febio_spec.Step{5}.Boundary.prescribe{1}.ATTR.bc='z';
febio_spec.Step{5}.Boundary.prescribe{1}.ATTR.node_set=febio_spec.Geometry.NodeSet{2}.ATTR.name;
febio_spec.Step{5}.Boundary.prescribe{1}.scale.ATTR.lc=5;
febio_spec.Step{5}.Boundary.prescribe{1}.scale.VAL=1;
febio_spec.Step{5}.Boundary.prescribe{1}.relative=1;
febio_spec.Step{5}.Boundary.prescribe{1}.value=0;

%LoadData section
febio_spec.LoadData.loadcurve{1}.ATTR.id=1;
febio_spec.LoadData.loadcurve{1}.ATTR.type='linear';
febio_spec.LoadData.loadcurve{1}.point.VAL=[0 0; 1 1];

febio_spec.LoadData.loadcurve{2}.ATTR.id=2;
febio_spec.LoadData.loadcurve{2}.ATTR.type='linear';
febio_spec.LoadData.loadcurve{2}.point.VAL=[1 0; 2 1];

febio_spec.LoadData.loadcurve{3}.ATTR.id=3;
febio_spec.LoadData.loadcurve{3}.ATTR.type='linear';
febio_spec.LoadData.loadcurve{3}.point.VAL=[2 0; 3 1];

febio_spec.LoadData.loadcurve{4}.ATTR.id=4;
febio_spec.LoadData.loadcurve{4}.ATTR.type='linear';
febio_spec.LoadData.loadcurve{4}.point.VAL=[3 0; 4 1];

febio_spec.LoadData.loadcurve{5}.ATTR.id=5;
febio_spec.LoadData.loadcurve{5}.ATTR.type='linear';
febio_spec.LoadData.loadcurve{5}.point.VAL=[4 0; 5 1];

%Output section 
% -> log file
febio_spec.Output.logfile.ATTR.file=febioLogFileName;
febio_spec.Output.logfile.node_data{1}.ATTR.file=febioLogFileName_disp;
febio_spec.Output.logfile.node_data{1}.ATTR.data='ux;uy;uz';
febio_spec.Output.logfile.node_data{1}.ATTR.delim=',';
febio_spec.Output.logfile.node_data{1}.VAL=1:size(V,1);

febio_spec.Output.logfile.node_data{2}.ATTR.file=febioLogFileName_force;
febio_spec.Output.logfile.node_data{2}.ATTR.data='Rx;Ry;Rz';
febio_spec.Output.logfile.node_data{2}.ATTR.delim=',';
febio_spec.Output.logfile.node_data{2}.VAL=1:size(V,1);

%% Quick viewing of the FEBio input file structure
% The |febView| function can be used to view the xml structure in a MATLAB
% figure window. 

%%
% |febView(febio_spec); %Viewing the febio file|

%% Exporting the FEBio input file
% Exporting the febio_spec structure to an FEBio input file is done using
% the |febioStruct2xml| function. 

febioStruct2xml(febio_spec,febioFebFileName); %Exporting to file and domNode

%% Running the FEBio analysis
% To run the analysis defined by the created FEBio input file the
% |runMonitorFEBio| function is used. The input for this function is a
% structure defining job settings e.g. the FEBio input file name. The
% optional output runFlag informs the user if the analysis was run
% succesfully. 

febioAnalysis.run_filename=febioFebFileName; %The input file name
febioAnalysis.run_logname=febioLogFileName; %The name for the log file
febioAnalysis.disp_on=1; %Display information on the command window
febioAnalysis.disp_log_on=1; %Display convergence information in the command window
febioAnalysis.runMode='external';%'internal';
febioAnalysis.t_check=0.25; %Time for checking log file (dont set too small)
febioAnalysis.maxtpi=1e99; %Max analysis time
febioAnalysis.maxLogCheckTime=3; %Max log file checking time

[runFlag]=runMonitorFEBio(febioAnalysis);%START FEBio NOW!!!!!!!!

%% Import FEBio results 

if runFlag==1 %i.e. a succesful run
    
    % Importing nodal displacements from a log file
    [time_mat, N_disp_mat,~]=importFEBio_logfile(fullfile(savePath,febioLogFileName_disp)); %Nodal displacements    
    time_mat=[0; time_mat(:)]; %Time
    
    N_disp_mat=N_disp_mat(:,2:end,:);
    sizImport=size(N_disp_mat);
    sizImport(3)=sizImport(3)+1;
    N_disp_mat_n=zeros(sizImport);
    N_disp_mat_n(:,:,2:end)=N_disp_mat;
    N_disp_mat=N_disp_mat_n;
    
    DN_MAG=sqrt(sum(N_disp_mat.^2,2));
    DN=N_disp_mat(:,:,end);
    DN_magnitude=sqrt(sum(DN(:,3).^2,2));
    V_def=V+DN;
    V_DEF=N_disp_mat+repmat(V,[1 1 size(N_disp_mat,3)]);
    X_DEF=V_DEF(:,1,:);
    Y_DEF=V_DEF(:,2,:);
    Z_DEF=V_DEF(:,3,:);
    [CF]=vertexToFaceMeasure(Fb,DN_magnitude);
    
    %% 
    % Plotting the simulated results using |anim8| to visualize and animate
    % deformations 
    
    % Create basic view and store graphics handle to initiate animation
    hf=cFigure; %Open figure  
    gtitle([febioFebFileNamePart,': Press play to animate']);
    hp=gpatch(Fb,V_def,CF,'k',1); %Add graphics object to animate
    gpatch(Fb,V,0.5*ones(1,3),'k',0.25); %A static graphics object
    
    colormap(gjet(250)); colorbar;
    caxis([0 max(DN_MAG(:))]);
    axisGeom(gca,fontSize);
    axis([min(X_DEF(:)) max(X_DEF(:)) min(Y_DEF(:)) max(Y_DEF(:)) min(Z_DEF(:)) max(Z_DEF(:))]);
    axis manual; 
    camlight headlight;   
    drawnow;     
        
    % Set up animation features
    animStruct.Time=time_mat; %The time vector    
    for qt=1:1:size(N_disp_mat,3) %Loop over time increments        
        DN=N_disp_mat(:,:,qt); %Current displacement
        DN_magnitude=sqrt(sum(DN.^2,2)); %Current displacement magnitude
        V_def=V+DN; %Current nodal coordinates
        [CF]=vertexToFaceMeasure(Fb,DN_magnitude); %Current color data to use
        
        %Set entries in animation structure
        animStruct.Handles{qt}=[hp hp]; %Handles of objects to animate
        animStruct.Props{qt}={'Vertices','CData'}; %Properties of objects to animate
        animStruct.Set{qt}={V_def,CF}; %Property values for to set in order to animate
    end        
    anim8(hf,animStruct); %Initiate animation feature    
    drawnow;
       
end

%% 
%
% <<gibbVerySmall.gif>>
% 
% _*GIBBON*_ 
% <www.gibboncode.org>
% 
% _Kevin Mattheus Moerman_, <gibbon.toolbox@gmail.com>
 
%% 
% _*GIBBON footer text*_ 
% 
% License: <https://github.com/gibbonCode/GIBBON/blob/master/LICENSE>
% 
% GIBBON: The Geometry and Image-based Bioengineering add-On. A toolbox for
% image segmentation, image-based modeling, meshing, and finite element
% analysis.
% 
% Copyright (C) 2019  Kevin Mattheus Moerman
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
