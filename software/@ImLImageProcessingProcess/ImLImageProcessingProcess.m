classdef ImLImageProcessingProcess < Process
    % Generic image processing process for ImageList owners.
    %
    % This follows ImDImageProcessingProcess, but the process owner is an
    % ImageList. Channel/image-folder information is taken from the first
    % contained ImageData, so ImageList-native packages can still expose the
    % usual image-processing display and output helpers.
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

    methods (Access = public)
        function obj = ImLImageProcessingProcess(owner, name, funName, funParams, ...
                inImagePaths, outImagePaths)

            if nargin == 0
                super_args = {};
            else
                super_args{1} = owner;
                super_args{2} = name;
            end

            obj = obj@Process(super_args{:});

            if nargin > 2
                obj.funName_ = funName;
            end
            if nargin > 3
                obj.funParams_ = funParams;
            end

            if nargin == 0
                return
            end

            sampleImD = ImLImageProcessingProcess.getSampleImageData(owner);
            nImFolders = numel(sampleImD.imFolders_);

            if nargin > 4
                if ~isempty(inImagePaths) && numel(inImagePaths) ~= nImFolders || ~iscell(inImagePaths)
                    error('lccb:set:fatal','Input image paths must be a cell-array of the same size as the number of image channels!\n\n');
                end
                obj.inFilePaths_ = inImagePaths;
            else
                obj.inFilePaths_ = sampleImD.getImFolderPaths;
            end

            if nargin > 5
                if ~isempty(outImagePaths) && numel(outImagePaths) ~= nImFolders || ~iscell(outImagePaths)
                    error('lccb:set:fatal','Output image paths must be a cell-array of the same size as the number of image channels!\n\n');
                end
                obj.outFilePaths_ = outImagePaths;
            else
                obj.outFilePaths_ = cell(1,nImFolders);
            end
        end

        function setOutImagePath(obj, chanNum, imagePath)
            if ~obj.checkChanNum(chanNum)
                error('lccb:set:fatal','Invalid image channel number for image path!\n\n');
            end

            if ~iscell(imagePath)
                imagePath = {imagePath};
            end
            nChan = length(chanNum);
            if nChan ~= length(imagePath)
                error('lccb:set:fatal','You must specify a path for every channel!')
            end

            for j = 1:nChan
                if ~exist(imagePath{j},'dir')
                    error('lccb:set:fatal', ...
                        ['The directory specified for channel ' ...
                        num2str(chanNum(j)) ' is invalid!'])
                else
                    obj.outFilePaths_{1,chanNum(j)} = imagePath{j};
                end
            end
        end

        function clearOutImagePath(obj, chanNum)
            if ~obj.checkChanNum(chanNum)
                error('lccb:set:fatal','Invalid image channel number for image path!\n\n');
            end

            for j = 1:numel(chanNum)
                obj.outFilePaths_{1,chanNum(j)} = [];
            end
        end

        function setInImagePath(obj, chanNum, imagePath)
            if ~obj.checkChanNum(chanNum)
                error('lccb:set:fatal','Invalid image channel number for image path!\n\n');
            end

            if ~iscell(imagePath)
                imagePath = {imagePath};
            end
            nChan = length(chanNum);
            if nChan ~= length(imagePath)
                error('lccb:set:fatal','You must specify a path for every channel!')
            end

            sampleImD = obj.getSampleImageData(obj.owner_);
            for j = 1:nChan
                if ~sampleImD.isBF
                    if ~exist(imagePath{j},'dir')
                        error('lccb:set:fatal', ...
                            ['The directory specified for channel ' ...
                            num2str(chanNum(j)) ' is invalid!'])
                    else
                        obj.inFilePaths_{1,chanNum(j)} = imagePath{j};
                    end
                else
                    if ~exist(imagePath{j},'file')
                        error('lccb:set:fatal', ...
                            ['The file specified for channel ' ...
                            num2str(chanNum(j)) ' is invalid!'])
                    else
                        obj.inFilePaths_{1,chanNum(j)} = imagePath{j};
                    end
                end
            end
        end

        function fileNames = getOutImageFileNames(obj, iImFol, iOutput)
            sampleImD = obj.getSampleImageData(obj.owner_);
            nChanTot = numel(sampleImD.imFolders_);
            if nargin < 2 || isempty(iImFol), iImFol = 1:nChanTot; end
            if nargin < 3 || isempty(iOutput), iOutput = 1; end
            if obj.checkChannelOutput(iImFol, iOutput)
                fileNames = cellfun(@(x)(imDir(x)),obj.outFilePaths_(iOutput, iImFol),'UniformOutput',false);
                fileNames = cellfun(@(x)(arrayfun(@(x)(x.name),x,'UniformOutput',false)),fileNames,'UniformOutput',false);
                nIm = cellfun(@(x)(length(x)),fileNames);
                if ~all(nIm == sampleImD.imFolders_(iImFol).nImages_)
                    error('Incorrect number of images found in one or more channels!')
                end
            else
                error('Invalid channel numbers! Must be positive integers less than the number of image channels!')
            end
        end

        function fileNames = getInImageFileNames(obj, iImFol)
            sampleImD = obj.getSampleImageData(obj.owner_);
            nChanTot = numel(sampleImD.imFolders_);
            if nargin < 2 || isempty(iImFol), iImFol = 1:nChanTot; end
            if obj.checkChanNum(iImFol)
                fileNames = cellfun(@(x)(imDir(x)),obj.inFilePaths_(1,iImFol),'UniformOutput',false);
                fileNames = cellfun(@(x)(arrayfun(@(x)(x.name),x,'UniformOutput',false)),fileNames,'UniformOutput',false);
                nIm = cellfun(@(x)(length(x)),fileNames);
                if ~all(nIm == sampleImD.imFolders_(iImFol).nImages_)
                    error('Incorrect number of images found in one or more channels!')
                end
            else
                error('Invalid channel numbers! Must be positive integers less than the number of image channels!')
            end
        end

        function status = checkChannelOutput(obj, iImFol, iOutput)
            sampleImD = obj.getSampleImageData(obj.owner_);
            nChanTot = numel(sampleImD.imFolders_);
            if nargin < 2 || isempty(iImFol), iImFol = 1:nChanTot; end
            if nargin < 3 || isempty(iOutput), iOutput = 1; end
            assert(all(obj.checkChanNum(iImFol)));
            status = arrayfun(@(x) exist(obj.outFilePaths_{iOutput, x},'dir') && ...
                ~isempty(imDir(obj.outFilePaths_{iOutput, x})),iImFol);
        end

        function status = checkChanNum(obj, iImFol)
            assert(~isempty(iImFol) && isnumeric(iImFol),'Please provide a valid channel input');
            sampleImD = obj.getSampleImageData(obj.owner_);
            status = insequence(iImFol, 1,numel(sampleImD.imFolders_));
        end

        function outIm = loadOutImage(obj, iImFol, iFrame, varargin)
            outIm = obj.loadChannelOutput(iImFol, iFrame, varargin{:});
        end

        function outStack = loadOutStack(obj, iImFol, iFrame, varargin)
            sampleImD = obj.getSampleImageData(obj.owner_);
            if sampleImD.is3D()
                checkCompatible3DOutput = true;
                if ~isempty(obj.is3Dcompatible_) && ~obj.is3Dcompatible_
                    checkCompatible3DOutput = false;
                end
                if checkCompatible3DOutput
                    outStack = obj.loadChannelOutput(iImFol, iFrame, ':', varargin{:});
                else
                    outStack = obj.loadOutImage(iImFol, iFrame, varargin{:});
                end
            else
                outStack = obj.loadOutImage(iImFol, iFrame, varargin{:});
            end
        end

        function outIm = loadChannelOutput(obj, iImFol, iFrame, varargin)
            sampleImD = obj.getSampleImageData(obj.owner_);

            ip = inputParser;
            ip.addRequired('obj');
            ip.addRequired('iImFol', @obj.checkChanNum);
            ip.addRequired('iFrame', @(x) obj.checkFrameNum(iImFol, x));
            if sampleImD.is3D()
                ip.addOptional('iZ', ':', @(x) x(1) == ':' || sampleImD.checkDepthNum(x));
            end

            ip.addParameter('iOutput', 1, @isnumeric);
            ip.addParameter('output', [], @ischar);
            ip.addParameter('outputIs3D', false, @(x) islogical(x) || x == 1 || x == 0);
            ip.parse(obj,iImFol,iFrame,varargin{:})

            iOutput = ip.Results.iOutput;
            imNames = obj.getOutImageFileNames(iImFol, iOutput);

            nYmax = sampleImD.getImFolder(iImFol).getReader.sizeYmax;
            nXmax = sampleImD.getImFolder(iImFol).getReader.sizeXmax;
            outIm = zeros([nYmax nXmax]);
            ny = sampleImD.getImFolder(iImFol).getReader.sizeY{iFrame,1};
            nx = sampleImD.getImFolder(iImFol).getReader.sizeX{iFrame,1};

            outIm(1:ny,1:nx) = imread([obj.outFilePaths_{iOutput, iImFol} filesep imNames{1}{iFrame}]);
        end

        function status = checkFrameNum(obj, iImFol, iFrame)
            assert(~isempty(iFrame) && isnumeric(iFrame),'Please provide a valid frame input');
            sampleImD = obj.getSampleImageData(obj.owner_);
            status = insequence(iFrame, 1, sampleImD.imFolders_(iImFol).nImages_);
        end

        function ofigure = folderDisplay(obj)
            ofigure = [];
            outputDir = '';
            if isfield(obj.funParams_, 'OutputDirectory')
                outputDir = obj.funParams_.OutputDirectory;
            elseif ~isempty(obj.outFilePaths_)
                outputPaths = obj.outFilePaths_;
                if iscell(outputPaths{1})
                    outputDir = outputPaths{1}{1};
                else
                    outputDir = outputPaths{1};
                end
            end

            if isempty(outputDir)
                msgbox('No output folder is registered for this process.');
                return
            end

            if ispc
                winopen(outputDir);
            elseif ismac
                system(sprintf('open "%s"', outputDir));
            elseif isunix
                status = system(sprintf('gio open "%s"', outputDir));
                if status
                    msgbox(sprintf('Results can be found under %s', outputDir));
                end
            else
                msgbox(sprintf('Results can be found under %s', outputDir));
            end
        end
    end

    methods (Static)
        function output = getDrawableOutput()
            output(1).name = 'Images';
            output(1).var = '';
            output(1).formatData = @mat2gray;
            output(1).type = 'image';
            output(1).defaultDisplayMethod = @ImageDisplay;
        end

        function sampleImD = getSampleImageData(owner)
            assert(isa(owner,'ImageList'), 'Owner must be an ImageList');
            sampleImD = owner.getImage(1);
        end
    end
end
