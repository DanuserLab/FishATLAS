% A sample script to create a ImageData and run NewFishATLAS Package by script.
% Qiongjing (Jenny) Zou, Feb 2026
%
% Copyright (C) 2026, Danuser Lab - UTSouthwestern 
%
% This file is part of FishATLAS_Package.
% 
% FishATLAS_Package is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% FishATLAS_Package is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with FishATLAS_Package.  If not, see <http://www.gnu.org/licenses/>.
% 
% 

%% ImageData creation
% Constructor needs an array of imFolders and an output directory (for analysis)
clear

if ispc
    tmpdir = 'C:\Users\s184919\Documents\Data\NewFishATLASPackWriting202511\testScript\data4Jenny\CHLA9';
elseif isunix
    tmpdir = '/work/bioinformatics/s184919/Analysis/Hanieh/202511NewFishATLASPack/testScript/data4Jenny/CHLA9';
end

% Note the filesep at the end (deleted on 6/26), but when create a ImD using GUI, the paths'
% end of imFolders has no filesep, I have edit proc 1 wrapper fcn to make it work.
imFolder(1) = ImFolder([tmpdir filesep 'ch1']); % 1st imFolder must be the black field images!
imFolder(1).pixelSize_ = 100; % fake value to test pixelSize_ can be properly set
imFolder(2) = ImFolder([tmpdir filesep 'ch2']); % 2nd imFolder must be the depth maps images!
imFolder

saveFolder = [tmpdir filesep 'analysis20260206'];
if ~isdir(saveFolder) mkdir(saveFolder); end
ImD = ImageData(imFolder, saveFolder); % saveFolder here is ImD's outputDirectory_
ImD.setPath(saveFolder); % set imageDataPath_, where to save .mat file
ImD.setFilename('imageData.mat');

% Set some additional image data properties
ImD.notes_= 'NewFishATLAS Package test run!';

% Run sanityCheck on ImageData.
% Save the image data if successful
ImD.sanityCheck; % add reader to the object, also does ImD.save(), Also add reader and nImages_ to ImD.imFolders(i);
                 % Also, set/update both ImD and ImD.imFolders(i)'s readers' properties - sizeXmax, sizeYmax, nImages, bitDepthMax, sizeZ, and filenames
                 % if pixelSize_ of one imFolder was set, copy it to the readers of that imFolder and ImD.
ImD.save; % included in the ImD.sanityCheck
ImD.reset(); % to clean up processes_ and packages_

%% Load the image data contents
clear ImD; % verify we can reload the object as intended.
ImD = ImageData.load(fullfile(saveFolder,'imageData.mat')); % if isMatFile, also does ImD.sanityCheck

%% Create FishATLAS Package and retrieve package index
Package_ = NewFishATLASPackage(ImD);
ImD.addPackage(Package_);
stepNames = Package_.getProcessClassNames;
iPack =  ImD.getPackageIndex('NewFishATLASPackage');
disp('=====================================');
disp('|| Available Package Process Steps ||');
disp('=====================================');
disp(ImD.getPackage(1).getProcessClassNames');

steps2Test = [1 2 3 4 5];
assert(length(Package_.processes_) >= length(steps2Test));
assert(length(Package_.processes_) >= max(steps2Test));
disp('Selected Package Process Steps');

for i=steps2Test
  disp(['Step ' num2str(i) ': ' stepNames{i}]);
end

%% Step 1: FishPreProcessingProcess
disp('===================================================================');
disp('Running (1st) FishPreProcessingProcess');
disp('===================================================================');
iPack = 1;
step_ = 1;
ImD.getPackage(iPack).createDefaultProcess(step_)
params = ImD.getPackage(iPack).getProcess(step_).funParams_;

ImD.getPackage(iPack).getProcess(step_).setPara(params);
ImD.save;
params = ImD.getPackage(iPack).getProcess(step_).funParams_
ImD.getPackage(iPack).getProcess(step_).run(); % also does obj.getOwner().save(), i.e. ImD.save()

%% Step 2: CreateReferenceImageProcess 
disp('===================================================================');
disp('Running (2nd) CreateReferenceImageProcess'); 
disp('===================================================================');
iPack = 1;
step_ = 2;
ImD.getPackage(iPack).createDefaultProcess(step_)
params = ImD.getPackage(iPack).getProcess(step_).funParams_;

ImD.getPackage(iPack).getProcess(step_).setPara(params);
ImD.save;
params = ImD.getPackage(iPack).getProcess(step_).funParams_
ImD.getPackage(iPack).getProcess(step_).run();

%% Step 3: FishRegistrationProcess 
disp('===================================================================');
disp('Running (3rd) FishRegistrationProcess'); 
disp('===================================================================');
iPack = 1;
step_ = 3;
ImD.getPackage(iPack).createDefaultProcess(step_)
params = ImD.getPackage(iPack).getProcess(step_).funParams_;

params.useRefImage = 1; % use the reference image; Can also run with 0 - no RefImage.
params.RefImagePath = '/work/bioinformatics/s184919/Analysis/Hanieh/202511NewFishATLASPack/testScript/data4Jenny';

ImD.getPackage(iPack).getProcess(step_).setPara(params);
ImD.save;
params = ImD.getPackage(iPack).getProcess(step_).funParams_
ImD.getPackage(iPack).getProcess(step_).run(); % took 21 min!

%% Step 4: CancerDetectionProcess
disp('===================================================================');
disp('Running (4th) CancerDetectionProcess'); 
disp('===================================================================');
iPack = 1;
step_ = 4;
ImD.getPackage(iPack).createDefaultProcess(step_)
params = ImD.getPackage(iPack).getProcess(step_).funParams_;

ImD.getPackage(iPack).getProcess(step_).setPara(params);
ImD.save;
params = ImD.getPackage(iPack).getProcess(step_).funParams_
ImD.getPackage(iPack).getProcess(step_).run();

%% Step 5: AccumulationProcess
disp('===================================================================');
disp('Running (5th) AccumulationProcess'); 
disp('===================================================================');
iPack = 1;
step_ = 5;
ImD.getPackage(iPack).createDefaultProcess(step_)
params = ImD.getPackage(iPack).getProcess(step_).funParams_;

ImD.getPackage(iPack).getProcess(step_).setPara(params);
ImD.save;
params = ImD.getPackage(iPack).getProcess(step_).funParams_
ImD.getPackage(iPack).getProcess(step_).run();


%% test NewFishATLASPackage GUI:
% method 0
movieSelectorGUI('ImD',ImD)

% method 1
NewFishATLASPackage.GUI(ImD)

% method 2
NewFishATLASPackageGUI(ImD)



