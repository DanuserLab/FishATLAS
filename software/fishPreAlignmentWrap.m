function fishPreAlignmentWrap(imageDataOrProcess, varargin)
% fishPreAlignmentWrap wrapper function for FishPreProcessingProcess
%
% INPUT
% imageDataOrProcess - either a ImageData (legacy)
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
ip.addRequired('ImD', @(x) isa(x,'ImageData') || isa(x,'Process') && isa(x.getOwner(),'ImageData'));
ip.addOptional('paramsIn',[], @isstruct);
ip.parse(imageDataOrProcess, varargin{:});
paramsIn = ip.Results.paramsIn;

%% Registration
% Get ImageData object and Process
[imageData, thisProc] = getOwnerAndProcess(imageDataOrProcess, 'FishPreProcessingProcess', true);
p = parseProcessParams(thisProc, paramsIn); % If parameters are explicitly given, they should be used
% rather than the one stored in FishPreProcessingProcess

% Parameters
% p

% Sanity Checks
nImFol = numel(imageData.imFolders_);
if max(p.ImFolderIndex) > nImFol || min(p.ImFolderIndex)<1 || ~isequal(round(p.ImFolderIndex), p.ImFolderIndex)
    error('Invalid imFolder numbers specified! Check ImFolderIndex input!!')
end

% precondition / error checking
% must have at least 2 imFolders_
if numel(imageData.imFolders_) < 2
    error('imageData.imFolders_ must contain at least 2 image folders!');
end

% nImages_ in each ImFolder must be the same
nImages = arrayfun(@(x) x.nImages_, imageData.imFolders_);
if ~all(nImages == nImages(1))
    error('Number of Images in each Image Folder needs to be the same! Check ImageData input!');
end

% QZ TODO - Do the fish file names in all channels need to be the same?

% logging input paths (bookkeeping)
inFilePaths = cell(1, numel(imageData.imFolders_));
for i = p.ImFolderIndex
    inFilePaths{1,i} = imageData.getImFolderPaths{i};
end
thisProc.setInFilePaths(inFilePaths);

% logging output paths.
mkClrDir(p.OutputDirectory);
outFilePaths = cell(1, numel(imageData.imFolders_));
for i = p.ImFolderIndex
    outFilePaths{1,i} = [p.OutputDirectory filesep 'ch' num2str(i)]; % save image output per chan
    outFilePaths{2,i} = [p.OutputDirectory]; % save .mat files for all channels
    mkClrDir(outFilePaths{1,i}); % no need to do mkClrDir(outFilePaths{2,i}) here.
end
thisProc.setOutFilePaths(outFilePaths);


%% Algorithm
% See module 1 loading and module 2 prepAlign: cropping, padding (resize), flipping in scriptFishAtlas4Jenny_QZ.m
% I rewrote the algorithm to the way how ImD handel paths and files. - QZ

%% module 1: loading
%load all channels for all fish
saveDirectory = p.OutputDirectory;

tic;

% directory read the number of fish from the folder
% newDir = dir(inFilePaths{1,1});
% foldername = {newDir.name};
% %remove hidden folders
% foldername (ismember(foldername,[{'.'}, {'..'}])) =[];
% % find the fish index from the folder automatically
% fileList = cellfun(@(x) str2double(regexp(x, '\d+', 'match')), foldername)';
for k = p.ImFolderIndex
    imFileNamesF = imageData.getImageFileNames(k);
    foldername{k,:} = imFileNamesF{1}'; % Rewrote so files name in ch1 and ch2 does not need to be the same. -QZ
end

% nFish = length(fileList);
nFish = imageData.imFolders_(1).nImages_;
nChannel = numel(imageData.imFolders_);
for iFile = 1: nFish
    clear imagetmp
    for iChannel = 1: nChannel
        filename = foldername{iChannel,1}(iFile);
        channelPath = inFilePaths{1,iChannel};
        % image are not exactly same size that is why I need to load as
        % cell array fishImage{iFile,iChannel} =
        % tiffreadVolume(fullfile(channelPath,filename));
        imagetmp(:,:,iChannel) = tiffreadVolume(fullfile(channelPath,filename));
    end
    fishImage{iFile,1} = imagetmp;
end

% t(1) = toc;

%% module 2: prepAlign: cropping, padding (resize), flipping
% tic;
maxSZ = [1 1];
for iFile = 1:nFish
    % step2-1: cropping the image in all channels, modify it to crop only
    % at the center
    [croppedImage_hwc imageLabeled] = autoCropFish2D(fishImage{iFile,1}, p.cropping_borderPX);

    %find the maximum size across the fish images to resize them for
    %alignment
    SZ(iFile,:) = size(croppedImage_hwc);
    maxSZ(1) = max(maxSZ(1),SZ(iFile,1));
    maxSZ(2) = max(maxSZ(2),SZ(iFile,2));
    croppedFishImage{iFile,1} = croppedImage_hwc;
end

%check if all fish haspointDetectionFish a minimum padding, if not add more
%padding to all
diffSZ = maxSZ - SZ(:,1:2);
if any(diffSZ < p.padding_minTickness )
    maxSZ = maxSZ + p.padding_minTickness ;
end

% step 2-2: padding
for iFile = 1:nFish
    image_hwc = croppedFishImage{iFile};
    diffSZ = maxSZ - SZ(iFile, 1:2);
    PaddingImage_hwc = addBlackBorder2D(image_hwc, diffSZ);
    paddingFishImage{iFile,1} = PaddingImage_hwc;
    SZ_padding(iFile, : ) = size(PaddingImage_hwc);
end

%step 2-3: flipping left/right or top/bottom
for iFile = 1:nFish
    image_hwc = paddingFishImage{iFile};
    FlippingImage_hwc = flippingFish2D(image_hwc);
    flippingFishImage{iFile,1} = FlippingImage_hwc;
end

fishImage_hwc = flippingFishImage;

%save all results,
savePath = saveDirectory;

save(fullfile(savePath,'fishImages.mat'),'fishImage', 'croppedFishImage','flippingFishImage');
save(fullfile(savePath,'fishImage_4Reg.mat'),'fishImage_hwc');

% QZ TODO: need to save fishImage_hwc as individual images in diff channel paths, i.e. outFilePaths{1,i}

% save parameters
% save(fullfile(saveDirectory,'params.mat'), 'params');
% t(2) = toc;
% save(fullfile(savePath,'processingTime.mat'),'t')

toc

disp('Finished fish images pre-processing!')

