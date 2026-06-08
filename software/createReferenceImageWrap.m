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

    % precondition / error checking
    % % must have at least 2 imFolders_
    % if numel(imageData.imFolders_) < 2
    %     error('imageData.imFolders_ must contain at least 2 image folders!');
    % end

    % % nImages_ in each ImFolder must be the same
    % nImages = arrayfun(@(x) x.nImages_, imageData.imFolders_);
    % if ~all(nImages == nImages(1))
    %     error('Number of Images in each Image Folder needs to be the same! Check ImageData input!');
    % end

    % logging input paths (bookkeeping)
    inFilePaths = cell(1, numel(imageData.imFolders_));
    for iImFolder = p.ImFolderIndex
        inFilePaths{1,iImFolder} = imageData.getImFolderPaths{iImFolder};
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
% QZ TODO: need to edit this when has algorithm

for iImD = imageDataIndex
    imageData = ImDs{1, iImD};
    inFilePaths = allInFilePaths{1,iImD};
    outFilePaths = allOutFilePaths{1,iImD};


%% Algorithm
% Package process mapping:
% Process 2 CreateReferenceImageProcess wraps module 3 from
% scriptFishAtlas4Jenny_QZ.m:
%   module 3: create refimage
%
% QZ TODO: module 3 is imageList/cross-condition level in Hanieh's script.
% Decide whether this ImageData process should create a reference image from
% only the current imageData, or whether this should become an ImageList-level
% process before moving the full algorithm here.



end

disp('Finished fish reference image creation!')
