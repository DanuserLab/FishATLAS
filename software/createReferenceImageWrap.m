function createReferenceImageWrap(imageListOrProcess, varargin)
% createReferenceImageWrap wrapper function for CreateReferenceImageProcess
%
% INPUT
% imageListOrProcess - either a ImageList (legacy)
%                      or a Process (new as of July 2016)
%
% param - (optional) A struct describing the parameters, overrides the
%                    parameters stored in the process (as of Aug 2016)
%
% OUTPUT
% none (saved to p.OutputDirectory)
%
% Changes
% As of July 2016, the first argument could also be a Process. Use
% getOwnerAndProcess to simplify compatability.
%
% As of August 2016, the standard second argument should be the parameter
% structure
%
%
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

%% ------------------ Input ---------------- %%
ip = inputParser;
ip.addRequired('imageListOrProcess', @isProcessOrImageList);
ip.addOptional('paramsIn',[], @isstruct);
ip.parse(imageListOrProcess, varargin{:});
paramsIn = ip.Results.paramsIn;

%% Registration
% Get ImageList object and Process
[imageList, thisProc] = getOwnerAndProcess(imageListOrProcess, 'CreateReferenceImageProcess', true);
p = parseProcessParams(thisProc, paramsIn); % If parameters are explicitly given, they should be used
% rather than the one stored in CreateReferenceImageProcess

% Parameters
% p

numImDs = numel(imageList.imageDataFile_);
if isfield(p,'ImageDataIndex') && ~isempty(p.ImageDataIndex)
    imageDataIndex = p.ImageDataIndex;
else
    imageDataIndex = 1:numImDs;
end
if max(imageDataIndex) > numImDs || min(imageDataIndex)<1 || ~isequal(round(imageDataIndex), imageDataIndex)
    error('Invalid ImageData numbers specified! Check ImageDataIndex input!!')
end

% precondition / error checking
% check if FishPreProcessingProcess was run
if isempty(p.ProcessIndex)
    iFishPreProcessingProc = imageList.getProcessIndex('FishPreProcessingProcess',1,true); % nDesired = 1 ; askUser = true
    if isempty(iFishPreProcessingProc)
        error('FishPreProcessingProcess needs to be done before run this process.')
    end
elseif isa(imageList.processes_{p.ProcessIndex},'FishPreProcessingProcess')
    iFishPreProcessingProc = p.ProcessIndex;
else
    error('The process specified by ProcessIndex is not a valid FishPreProcessingProcess! Check input!')
end
fishPreProcessingProc = imageList.processes_{iFishPreProcessingProc};

ImDs = cell(1, numImDs);
for iImD = imageDataIndex
    ImDs{iImD} = ImageData.load(imageList.imageDataFile_{1,iImD});
end

% Do below on the ImD level:

allInFilePaths = cell(1, numImDs);
% allOutFilePaths = cell(1, numImDs);
[packageOutputDirectory, processOutputName] = fileparts(p.OutputDirectory);
[~, packageOutputName] = fileparts(packageOutputDirectory);
mkClrDir(p.OutputDirectory);

for iImD = imageDataIndex
    imageData = ImDs{1, iImD};

    % Sanity Checks
    nImFol = numel(imageData.imFolders_);
    if max(p.ImFolderIndex) > nImFol || min(p.ImFolderIndex)<1 || ~isequal(round(p.ImFolderIndex), p.ImFolderIndex)
        error('Invalid imFolder numbers specified! Check ImFolderIndex input!!')
    end

    fishPreProcessingOutFilePaths = fishPreProcessingProc.outFilePaths_{1,iImD};

    % logging input paths (bookkeeping)
    inFilePaths = cell(1, numel(imageData.imFolders_));
    for iImFolder = p.ImFolderIndex
        inFilePaths{1,iImFolder} = fishPreProcessingOutFilePaths{2,iImFolder}; % use .mat files as input
    end
    allInFilePaths{1,iImD} = inFilePaths;

    % % logging output paths. - It is a ImL process, no need to create ImDs level folders
    % imageOutputDirectory = fullfile(imageData.outputDirectory_, packageOutputName, processOutputName);
    % mkClrDir(imageOutputDirectory);
    % outFilePaths = cell(2, numel(imageData.imFolders_));
    % for iImFolder = p.ImFolderIndex
    %     outFilePaths{1,iImFolder} = [imageOutputDirectory filesep 'ch' num2str(iImFolder)]; % save image output per chan
    %     outFilePaths{2,iImFolder} = imageOutputDirectory; % save .mat files for all channels
    %     mkClrDir(outFilePaths{1,iImFolder}); % no need to do mkClrDir(outFilePaths{2,iImFolder}) here.
    % end
    % allOutFilePaths{1,iImD} = outFilePaths;
end

% logging output paths - adding ImL outputdir to allOutFilePaths
allOutFilePaths{1,1} = p.OutputDirectory;
mkClrDir(allOutFilePaths{1,1});

% logging input/output paths on the ImL level.
thisProc.setInFilePaths(allInFilePaths);
thisProc.setOutFilePaths(allOutFilePaths);


% module 3 is imageList/cross-condition level in Hanieh's script!!!
%% Algorithm 
% Package process mapping:
% Process 2 CreateReferenceImageProcess wraps module 3 from
% scriptFishAtlas4Jenny_QZ.m:
%   module 3: create refimage
% I kept the algorithm most unchanged, just change the way how ImL handles params and input/output paths.. - QZ
p.Reg = p;

tic
% module 3-1: create a pool of all fish image for making a reference image across the
% conditions
fishImage_Total = {} % new cell array for pooling all images from imageList
% for iCond = 1: length(p.cellConditions)
%     % load from previous module "fishImage"  --> Jenny, I am not sure how
%     % we want to implement but basically I load the fishImage_4Reg.mat from
%     % imageData and pool them into a giant fishImage_Total for all
%     % conditions then I continue the rest of module 3:
%     filePath = [p.dataInfo.fileDirectory filesep p.cellConditions{iCond}  filesep 'ResultsGroup' filesep 'PreProcessing'];
%     load(fullfile(filePath, 'fishImage_4Reg.mat'))
%     fishImage_Total = [fishImage_Total ; fishImage_hwc]
% end
% QZ:
for iImD = imageDataIndex 
    inFilePaths = allInFilePaths{1,iImD};
    load([inFilePaths{1,p.ImFolderIndex(1)} filesep 'fishImage_4Reg.mat']); % load output fishImage_hwc from FishPreProcessingProcess - QZ
    fishImage_Total = [fishImage_Total ; fishImage_hwc]
end

% module 3-2:resize them:
% recognize the smaller size to avoid interpolation that might not good for
% registration
imageSize = cell2mat(cellfun(@size , fishImage_Total, 'UniformOutput' , false))
minImageSize = min(imageSize); % desire imageSize!
for iImage = 1: length(fishImage_Total)
    imageFishtmp = fishImage_Total{iImage};
    fishImage_hwc_Total{iImage} =  imresize3(imageFishtmp, [minImageSize]);
end

% savePath = [p.dataInfo.saveDirectory filesep 'PreProcessing'];
savePath = [p.OutputDirectory filesep 'PreProcessing']; % QZ - save this in ImL level
mkdir(savePath)
save(fullfile(savePath , 'fish_images.mat'), 'fishImage_Total'); % QZ: fish_images.mat is combined fishImage_4Reg.mat from all ImDs.
save(fullfile(savePath , 'fishImage_4Reg.mat'), 'fishImage_hwc_Total'); 


% module 3-3:rigid registration

% QZ:
imageData = ImDs{1, 1};
nChannel = numel(imageData.imFolders_); % number of imFolders is the same in all ImDs.
p.PreAlign.vasChannel = fishPreProcessingProc.funParams_.vasChannel; % ImL level param

prealignedImage = cat(3,fishImage_hwc_Total{:});
prealignedImage = prealignedImage(:,:,p.PreAlign.vasChannel:nChannel:end);

% initialize the variables before registration
rigidImage = nan(size(prealignedImage));
nonRigidImage = nan(size(prealignedImage));
nonRigidImageDemon = nan(size(prealignedImage));
nonRigidImageDeform = nan(size(prealignedImage));
dispField_demon = nan([size(prealignedImage,[1 2]),2,size(prealignedImage,3)]);
dispField_deform = nan([size(prealignedImage,[1 2]),2,size(prealignedImage,3)]);
tformTotal = cell(size(prealignedImage,3),1);

imageFlag_rigid = nan(size(prealignedImage,3),1);
imageFlag_nonRigid = nan(size(prealignedImage,3),1);
similarity_rigid = nan(size(prealignedImage,3),1);
similarity_nonrigid = nan(size(prealignedImage,3),2);

if isempty(p.Reg.rigid.RefImageID)
        idx = randi(size(prealignedImage,3)); % choose an index of the filelist randomly
        p.Reg.rigid.RefImageID = idx;
end

fixed = prealignedImage(:,:,p.Reg.rigid.RefImageID);
[optimizer, metric] = imregconfig(p.Reg.rigid.regmodel);
%set the optimization parameters
optimizer.MaximumIterations = p.Reg.rigid.maxIter;
if strcmp(p.Reg.rigid.regmodel, 'monomodal')
    optimizer.MaximumStepLength = optimizer.MaximumStepLength/ 3.5; % smaller Radius helped for optimization process (Felix)
end
    rigidImage = cast(rigidImage,class(prealignedImage));
for iFile = 1: size(prealignedImage,3)
    moving = prealignedImage(:,:,iFile);
    iFile
    tform = imregtform(moving,fixed,p.Reg.rigid.tformType,optimizer,metric);
    [rigidImage(:,:,iFile) ]= imwarp(moving,tform,'OutputView',imref2d(size(fixed)));
    tformTotal{iFile} = tform;
end

% remove some bad registered from the rigid step
[similarity_rigid, imageFlag_rigid] = discardNonRegImages(fixed, rigidImage,p.Reg.rigid.FilterMetric,p.Reg.rigid.FilterThreshold);
savePath = [p.OutputDirectory filesep 'Registration']; % QZ
if ~isdir(savePath) mkdir(savePath); end

save(fullfile(savePath,'registeredFishRigid.mat'),'rigidImage', 'similarity_rigid','imageFlag_rigid','tformTotal');

% module 3-4: nonrigid registration
Ind_good_rigid = find(imageFlag_rigid); % only keep the good quality image after rigid registration
Ind_good = Ind_good_rigid; % define good fish after rigid registration

% repeat the nonrigid registration until there is no bad registered
% image based on the threshold or maxIter
Ind_good_nonrigid = 0;
nIter = 1;

Ind_badFish_afGroupwise = 0;

while nIter > p.Reg.nonRigid.maxIterWhileLoop || ~isempty(Ind_badFish_afGroupwise)
    nIter
    imageRegistereduint8_updated = rigidImage(:,:,Ind_good); % only good rigid registered images contribute in groupwise registration

    [dispFieldtmp,imGroupwiseRegtmp] = imreggroupwise(imageRegistereduint8_updated,...
        GridRegularization=p.Reg.nonRigid.GridRegularization,NumPyramidLevels = p.Reg.nonRigid.NumPyramidLevels);

    % I should have a new imgroupwis to be consistant for the number of
    % fish file
    imGroupwiseReg = nan(size(rigidImage));
    dispField = nan([size(rigidImage,[1 2]), 2, size(rigidImage,3)]);

    %replace the registered fish for those pass the filter after rigid
    imGroupwiseReg(:,:,Ind_good) = imGroupwiseRegtmp;
    dispField (:,:,:,Ind_good) = dispFieldtmp;

    imGroupwiseReg = cast(imGroupwiseReg,class(imGroupwiseRegtmp)); % it convert the nan to 0 for uint class

    imGroupwiseReg_median3 = imGroupwiseReg;
    %create a refimage based on mean or median and decide which one is sharper
    %based on gradiant image
    RefImage_mean = nanmean(imGroupwiseReg_median3,3); % I used the laplacian filter and check the sharpness, mean is better than median
    %convert the imageRef format to what it is for imgroupwise
    [bluredFlag sharpness_mean] = identifyBlurredImage(RefImage_mean,p.Reg.RefImageFilter);
    RefImage_median = nanmedian(imGroupwiseReg_median3,3); % I used the laplacian filter and check the sharpness, mean is better than median
    %convert the imageRef format to what it is for imgroupwise
    [bluredFlag sharpness_median] = identifyBlurredImage(RefImage_median,p.Reg.RefImageFilter);

    if sharpness_median < sharpness_mean
        RefImage = RefImage_mean;
    else
        RefImage = RefImage_median;
    end


    RefImage = cast(RefImage,class(imGroupwiseReg));

    [similarity_nonRigid imageFlag_nonRigid ] = discardNonRegImages(RefImage, imGroupwiseReg, ...
        p.Reg.nonRigid.FilterMetric, p.Reg.nonRigid.FilterThreshold);

    % recreate the refimage after filtering bad fish from the groupwise
    % registration --> ideally we should do the imgroupwise again!
    Ind_good_nonrigid = find(imageFlag_nonRigid);

    Ind_badFish_afGroupwise = find(ismember(Ind_good_rigid,Ind_good_nonrigid)==0);
    Ind_good = Ind_good_nonrigid;
    nIter = nIter + 1;
    if nIter == p.Reg.nonRigid.maxIterWhileLoop
        error('There are some bad registered images after non-rigid registration - update maxIterWhileLoop or FilterThreshold in parames.Reg.nonRigid!')
    end
end

nonRigidImage = imGroupwiseReg;
%save all results,
save(fullfile(p.OutputDirectory,'registeredFishnonRigid.mat'),'nonRigidImage','dispField','similarity_nonRigid',...
    'imageFlag_nonRigid','Ind_good_nonrigid','Ind_good_rigid');

% module 3-5: define the refernece image from the groupwise registration
imwrite(RefImage, fullfile(p.OutputDirectory, 'RefImage.tif'));
save(fullfile(p.OutputDirectory, 'RefImage.mat'),'RefImage');

% % save parameters
% save(fullfile(p.OutputDirectory,'params_imageList.mat'), 'p');

toc


disp('Finished fish reference image creation!')
