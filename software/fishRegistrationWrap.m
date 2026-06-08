function fishRegistrationWrap(imageListOrProcess, varargin)
% fishRegistrationWrap wrapper function for FishRegistrationProcess
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
[imageList, thisProc] = getOwnerAndProcess(imageListOrProcess, 'FishRegistrationProcess', true);
p = parseProcessParams(thisProc, paramsIn); % If parameters are explicitly given, they should be used
% rather than the one stored in FishRegistrationProcess

% Parameters
% p % for now, all ImDs use same p - QZ

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
allOutFilePaths = cell(1, numImDs);
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

    % logging output paths.
    imageOutputDirectory = fullfile(imageData.outputDirectory_, packageOutputName, processOutputName);
    mkClrDir(imageOutputDirectory);
    outFilePaths = cell(2, numel(imageData.imFolders_));
    for iImFolder = p.ImFolderIndex
        outFilePaths{1,iImFolder} = [imageOutputDirectory filesep 'ch' num2str(iImFolder)]; % save image output per chan
        outFilePaths{2,iImFolder} = imageOutputDirectory; % save .mat files for all channels
        mkClrDir(outFilePaths{1,iImFolder}); % no need to do mkClrDir(outFilePaths{2,iImFolder}) here.
    end
    allOutFilePaths{1,iImD} = outFilePaths;
end

% logging input/output paths on the ImL level.
thisProc.setInFilePaths(allInFilePaths);
thisProc.setOutFilePaths(allOutFilePaths);


% Run below Algorithm on the ImD level:


for iImD = imageDataIndex
    imageData = ImDs{1, iImD};
    inFilePaths = allInFilePaths{1,iImD};
    outFilePaths = allOutFilePaths{1,iImD};

%% Algorithm
% Package process mapping:
% Process 3 FishRegistrationProcess wraps module 4 from
% scriptFishAtlas4Jenny_QZ.m:
%   module 4: registration
% I kept the algorithm most unchanged, just change the way how ImD handles params and input/output paths.. - QZ
params.Reg = p;

% two modes: 1) no refImage; 2) refImage
tic
%create a folder for saving this module seperatedly
savePath = outFilePaths{2,p.ImFolderIndex(1)};

%step 4-1: take the channel for registeration from all fish Image
load([inFilePaths{1,p.ImFolderIndex(1)} filesep 'fishImage_4Reg.mat']); % load output fishImage_hwc from FishPreProcessingProcess - QZ
prealignedImage = cat(3,fishImage_hwc{:}); % load output from FishPreProcessingProcess - QZ
nChannel = numel(imageData.imFolders_);
nFish = size(fishImage_hwc,1);
imFileNamesF = imageData.getImageFileNames(1);
fileList = cellfun(@(x) str2double(regexp(x, '\d+', 'match', 'once')), imFileNamesF{1})';
if any(isnan(fileList))
    fileList = (1:nFish)';
end
prealignedImage = prealignedImage(:,:,p.vasChannel:nChannel:end);

% step 4-2
if params.Reg.useRefImage
    %load reference image - anything!
    RefImage = tiffreadVolume(fullfile(params.Reg.RefImagePath,params.Reg.RefImageName));

    % make the same size - how to deal with low resolution one, should I
    % add the pad or imresize
    SZ_RefImg = size(RefImage);
    SZ_fishImage = size(prealignedImage);
    %compare the size and resize it to the original size of the refrence
    %image --> cancer channel should be rescale after point detection
    %(otherwise some fake local maxima due to interpolation)
    if SZ_RefImg ~= SZ_fishImage(1:2)
        prealignedImage = nan([SZ_RefImg size(fishImage_hwc,1)]);
        for iFile = 1: size(fishImage_hwc,1)
            imageFishtmp = fishImage_hwc{iFile};
            imageFishtmp = imresize3(imageFishtmp, [SZ_RefImg(1) SZ_RefImg(2) size(imageFishtmp,3)]);
            fishImage_hwc_resize{iFile,1} = imageFishtmp;
        end
    else
        fishImage_hwc_resize = fishImage_hwc;
    end
    prealignedImage = cat(3,fishImage_hwc_resize{:});
    prealignedImage = prealignedImage(:,:,p.vasChannel:nChannel:end);

    % do pairwise rigid rgisteration
    [optimizer, metric] = imregconfig(params.Reg.rigid.regmodel);
    optimizer.MaximumIterations = params.Reg.rigid.maxIter;
    if strcmp(params.Reg.rigid.regmodel, 'monomodal')
        optimizer.MaximumStepLength = optimizer.MaximumStepLength/ 5; % smaller Radius helped for optimization process (Felix /3.5)
    end
    % rigidImage =nan(size(prealignedImage)); nonRigidImage
    % =nan(size(prealignedImage));
    RefImage = cast(RefImage,class(prealignedImage));

    %initilize matrix before 'for' loop
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

    for iFile = 1: size(prealignedImage,3)
        moving = prealignedImage(:,:,iFile);
        % covert the image class before registration
        moving = cast(moving, class(RefImage));

        % iFile
        tform = imregtform(moving,RefImage,params.Reg.rigid.tformType,optimizer,metric);
        [imagetmpReg]= imwarp(moving,tform,'OutputView',imref2d(size(RefImage)));
        rigidImage(:,:,iFile)  = imagetmpReg;
        tformTotal{iFile} = tform;

        % check if the rigid registration is good
        [similarity_rigid(iFile,1), imageFlag_rigid(iFile,1)] = discardNonRegImages(RefImage, imagetmpReg,...
            params.Reg.rigid.FilterMetric,params.Reg.rigid.FilterThreshold);

        if imageFlag_rigid(iFile,1) < 1
            % you can change this one to continue for skipping this fish
            warning(['rigid registeration is not good for fish = ' num2str(iFile)])
        end
        % do pairwise nonrigid registeration case 'demon'
        [dispField_demon(:,:,:,iFile),nonRigidImageDemontmp] = imregdemons(imagetmpReg,RefImage,...
            params.Reg.nonRigid.maxIter, 'PyramidLevels', params.Reg.nonRigid.NumPyramidLevels,...
            'AccumulatedFieldSmoothing',params.Reg.nonRigid.AccumulatedFieldSmoothing);

        % case 'deform'
        [dispField_deform(:,:,:,iFile),nonRigidImageDeformtmp] = imregdeform(imagetmpReg,RefImage, ...
            GridRegularization=params.Reg.nonRigid.GridRegularization,NumPyramidLevels = params.Reg.nonRigid.NumPyramidLevels);

        % otherwise
        %     error('Choose a proper nonrigid registration method: demon Or
        %     deform')


        % calculate which nonrigid method is better for this fish now
        % compare which one is similar to refimage
        [similarity_nonrigid(iFile,1) ] = discardNonRegImages(RefImage, nonRigidImageDemontmp,params.Reg.nonRigid.FilterMetric);
        [similarity_nonrigid(iFile,2) ] = discardNonRegImages(RefImage, nonRigidImageDeformtmp,params.Reg.nonRigid.FilterMetric);

        if max(similarity_nonrigid(iFile,:)) < params.Reg.nonRigid.FilterThreshold
            imageFlag_nonRigid(iFile,1) = 0;
            warning(['optimize the parameter for this fish = ' num2str(iFile)]);
        end
        if similarity_nonrigid(iFile,1) >= similarity_nonrigid(iFile,2)
            nonRigidImage(:,:,iFile) = nonRigidImageDemontmp;
            dispField(:,:,:,iFile) =  dispField_demon(:,:,:,iFile);
            params.Reg.nonRigid.method{iFile,1} = 'demon';
            imageFlag_nonRigid(iFile,1) = 1;
        else
            nonRigidImage(:,:,iFile) = nonRigidImageDeformtmp;
            dispField(:,:,:,iFile) = dispField_deform(:,:,:,iFile);
            params.Reg.nonRigid.method{iFile,1} = 'deform';
            imageFlag_nonRigid(iFile,1) = 1;
        end

        % otherwise it will be filled as double not uint8
        nonRigidImageDemon(:,:,iFile) = nonRigidImageDemontmp;
        nonRigidImageDeform(:,:,iFile) = nonRigidImageDeformtmp;



    end

    %conert to uint8 /uint16
    rigidImage = cast(rigidImage,class(RefImage));
    nonRigidImageDemon = cast(nonRigidImageDemon,class(RefImage));
    nonRigidImageDeform = cast(nonRigidImageDeform,class(RefImage));
    nonRigidImage = cast(nonRigidImage,class(RefImage));

    % remove bad registered when reference image is created
    save(fullfile(savePath,'registeredFishRigid.mat'),'rigidImage', 'similarity_rigid','imageFlag_rigid','tformTotal');
    save(fullfile(savePath,'registeredFishnonRigid.mat'),'nonRigidImage','nonRigidImageDemon', ...
        'nonRigidImageDeform','dispField', 'dispField_demon','dispField_deform','similarity_nonrigid', ...
        'imageFlag_nonRigid');

    % %rename this file to be a consistent output for next module
    % fishImage_hwc = fishImage_hwc_resize;  % I should keep the
    % fishImage_hwc without any rescaling because the raw image is better
    % for both point detection and bianry image of cancer channel

    % save the cropped image again after resizing with refImage!
    % save(fullfile(savePath,'fishImage.mat'),'fishImage_hwc_resize');
    save(fullfile(savePath,'fishImage_resize.mat'),'fishImage_hwc_resize'); % QZ I made this change, b/c fishImage_hwc_resize is not used later
    %resave all channels of raw image for next module
    save(fullfile(savePath,'fishImage.mat'),'fishImage_hwc'); % QZ I made this change, we need fishImage_hwc for step 4.

    %save reference image
    save(fullfile(savePath, 'RefImage.mat'),'RefImage');
    imwrite(RefImage, fullfile(savePath, 'RefImage.tif'));

else     % if there is no reference image, do groupwise registration
    % do the registeration within the group and save a reference Image

    % rigid registeration, they still need to pick the refrence image ID
    % for rigid registeration from the GUI or just the first image
    if isempty(params.Reg.rigid.RefImageID)
       idx = randi(size(prealignedImage,3)); % choose an index of the filelist randomly
       params.Reg.rigid.RefImageID = idx;
    end
    fixed = prealignedImage(:,:,params.Reg.rigid.RefImageID);
    [optimizer, metric] = imregconfig(params.Reg.rigid.regmodel);

    %set the optimization parameters
    optimizer.MaximumIterations = params.Reg.rigid.maxIter;
    if strcmp(params.Reg.rigid.regmodel, 'monomodal')
        optimizer.MaximumStepLength = optimizer.MaximumStepLength/ 3.5; % smaller Radius helped for optimization process (Felix)
    end

    rigidImage =nan(size(prealignedImage));
    rigidImage = cast(rigidImage,class(prealignedImage)); % class should be same as raw image, preferebly uint8 for imregtform
    tformTotal = cell(size(prealignedImage,3),1);

    for iFile = 1: size(prealignedImage,3)

        tform = imregtform(prealignedImage(:,:,iFile),fixed,params.Reg.rigid.tformType,optimizer,metric);
        [rigidImage(:,:,iFile) ]= imwarp(prealignedImage(:,:,iFile),tform,'OutputView',imref2d(size(fixed)));
        tformTotal{iFile} = tform;

        % imgReg = rididImage(:,:,iImage); % imgReg = im2uint16(imgReg); s
        % = sprintf('fish%03d.tif',iImage);
        % imwrite(imgReg,fullfile(savePath,s ));
    end

    % remove some bad registered from the rigid step
    [similarity_rigid, imageFlag_rigid] = discardNonRegImages(fixed, rigidImage,params.Reg.rigid.FilterMetric,params.Reg.rigid.FilterThreshold);

    %nonrigid groupwise registeration
    Ind_good_rigid = find(imageFlag_rigid);
    Ind_good = Ind_good_rigid; % define good fish after rigid registration

    % repeat the nonrigid registration until there is no bad registered
    % image based on the threshold or maxIter
    Ind_badFish_afGroupwise = 0;
    nIter = 1;
    % regenerating groupwise-based registration while all registered image
    % satisfy the threshold for good registration
    while nIter > params.Reg.nonRigid.maxIterWhileLoop || ~isempty(Ind_badFish_afGroupwise)

        imageRegistereduint8_updated = rigidImage(:,:,Ind_good); % only good rigid registered images contribute in groupwise registration

        [dispFieldtmp,imGroupwiseRegtmp] = imreggroupwise(imageRegistereduint8_updated,...
            GridRegularization=params.Reg.nonRigid.GridRegularization,NumPyramidLevels = params.Reg.nonRigid.NumPyramidLevels);

        % I should have a new imgroupwis to be consistant for the number of
        % fish file
        imGroupwiseReg = nan(size(rigidImage));
        dispField = nan([size(rigidImage,[1 2]), 2, size(rigidImage,3)]);

        %replace the registered fish for those pass the filter after rigid
        imGroupwiseReg(:,:,Ind_good) = imGroupwiseRegtmp;
        dispField (:,:,:,Ind_good) = dispFieldtmp;

        imGroupwiseReg = cast(imGroupwiseReg,class(imGroupwiseRegtmp)); % it convert the nan to 0 for uint class

        %create a refimage based on mean or median and decide which one is
        %sharper based on gradiant image
        RefImage_mean = nanmean(imGroupwiseReg,3); % I used the laplacian filter and check the sharpness, mean is better than median
        %convert the imageRef format to what it is for imgroupwise
        [bluredFlag sharpness_mean] = identifyBlurredImage(RefImage_mean,params.Reg.RefImageFilter);
        RefImage_median = nanmedian(imGroupwiseReg,3); % I used the laplacian filter and check the sharpness, mean is better than median
        %convert the imageRef format to what it is for imgroupwise
        [bluredFlag sharpness_median] = identifyBlurredImage(RefImage_median,params.Reg.RefImageFilter);

        if sharpness_median < sharpness_mean
            RefImage = RefImage_mean;
        else
            RefImage = RefImage_median;
        end

        RefImage = cast(RefImage,class(imGroupwiseReg));

        [similarity_nonRigid imageFlag_nonRigid ] = discardNonRegImages(RefImage, imGroupwiseReg, ...
            params.Reg.nonRigid.FilterMetric, params.Reg.nonRigid.FilterThreshold);

        % recreate the refimage after filtering bad fish from the groupwise
        % registration --> ideally we should do the imgroupwise again!
        Ind_good_nonrigid = find(imageFlag_nonRigid);

        Ind_badFish_afGroupwise = find(ismember(Ind_good_rigid,Ind_good_nonrigid)==0);
        Ind_good = Ind_good_nonrigid;
        nIter = nIter + 1
        if nIter == params.Reg.nonRigid.maxIterWhileLoop
            error('There are some bad registered images after non-rigid registration - update maxIterWhileLoop or FilterThreshold in parames.Reg.nonRigid!')
        end
    end

    nonRigidImage = imGroupwiseReg;
    %save all results,
    save(fullfile(savePath,'registeredFishRigid.mat'),'rigidImage', 'similarity_rigid','imageFlag_rigid','tformTotal');
    save(fullfile(savePath,'registeredFishnonRigid.mat'),'nonRigidImage','imGroupwiseReg', 'similarity_nonRigid','dispField',...
        'sharpness_mean','sharpness_median', 'similarity_nonRigid', 'imageFlag_nonRigid', 'nIter');

    %resave all channels of raw image for next module
    save(fullfile(savePath,'fishImage.mat'),'fishImage_hwc');

    %save reference image
    save(fullfile(savePath, 'RefImage.mat'),'RefImage');
    imwrite(RefImage, fullfile(savePath, 'RefImage.tif'));

    %save in the params that we can use later for point pattern
    params.Reg.RefImagePath = savePath;
    params.Reg.RefImageName = 'RefImage.tif';
end

% save tif files for rigid registration
savePath1 = [savePath filesep 'rigid' filesep 'ch' num2str(p.vasChannel)];
if ~isdir(savePath1) mkdir(savePath1); end
for iFile = 1:nFish
    s = sprintf('fish%04d.tif',fileList(iFile));
    imagetmp = rigidImage(:,:,iFile);
    imwrite(im2uint8(imagetmp), fullfile(savePath1, s));
end

% save tif files for nonrigid registration
savePath1 = [savePath filesep 'nonrigid' filesep 'ch' num2str(p.vasChannel)];
if ~isdir(savePath1) mkdir(savePath1); end
for iFile = 1:nFish
    s = sprintf('fish%04d.tif',fileList(iFile));
    imagetmp = nonRigidImage(:,:,iFile);
    imwrite(im2uint8(imagetmp), fullfile(savePath1, s));
end

% transfer and save the cancer/second channel
cancerChannel = 2;
if nChannel >= cancerChannel
    savePath1 = [savePath filesep 'rigid' filesep 'ch' num2str(cancerChannel)];
    if ~isdir(savePath1) mkdir(savePath1); end
    savePath2 = [savePath filesep 'nonrigid' filesep 'ch' num2str(cancerChannel)];
    if ~isdir(savePath2) mkdir(savePath2); end
    for iFile = 1:nFish
        s = sprintf('fish%04d.tif',fileList(iFile));
        imagetmp = fishImage_hwc{iFile}(:,:,cancerChannel);
        rigidImage_ch2(:,:,iFile) = imwarp(imagetmp,tformTotal{iFile},'OutputView',imref2d(size(RefImage)));
        imagetmp = rigidImage_ch2(:,:,iFile);
        imwrite(im2uint8(imagetmp), fullfile(savePath1, s));
        if any(isnan(reshape(dispField(:,:,:,iFile),[],1)))
            imagetmp = zeros(size(imagetmp));
            imwrite(im2uint8(imagetmp), fullfile(savePath2, s));
            continue
        end
        nonRigidImage_ch2(:,:,iFile) = imwarp(rigidImage_ch2(:,:,iFile), dispField(:,:,:,iFile),'interp', 'nearest');
        imagetmp = nonRigidImage_ch2(:,:,iFile);
        imwrite(im2uint8(imagetmp), fullfile(savePath2, s));
    end
end

% % save parameters
% save(fullfile(saveDirectory,'params.mat'), 'params');

% t = toc;
% save(fullfile(savePath,'processingTime.mat'),'t')

toc

end

disp('Finished fish registration!')
