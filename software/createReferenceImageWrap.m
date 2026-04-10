function createReferenceImageWrap(imageDataOrProcess, varargin)
% createReferenceImageWrap wrapper function for CreateReferenceImageProcess
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
[imageData, thisProc] = getOwnerAndProcess(imageDataOrProcess, 'CreateReferenceImageProcess', true);
p = parseProcessParams(thisProc, paramsIn); % If parameters are explicitly given, they should be used
% rather than the one stored in CreateReferenceImageProcess

% Parameters
% p

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
for i = p.ImFolderIndex
    inFilePaths{1,i} = imageData.getImFolderPaths{i};
end
thisProc.setInFilePaths(inFilePaths);

% QZ TODO: need to edit this when has algorithm 
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
% Do nothing, no algorithm yet in scriptFishAtlas4Jenny_QZ.m - QZ



disp('Finished fish reference image creation!')

