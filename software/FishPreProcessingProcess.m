classdef  FishPreProcessingProcess < ImLImageProcessingProcess & NonSingularProcess
    % Process Class for loading the fish & prepAlign: cropping, padding (resize), flipping
    % fishPreAlignmentWrap.m is the wrapper function
    % FishPreProcessingProcess is part of new FishATLAS Package
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

    methods (Access = public)
        function obj = FishPreProcessingProcess(owner, varargin)
            
            if nargin == 0
                super_args = {};
            else
                % Input check
                ip = inputParser;
                ip.CaseSensitive = false;
                ip.KeepUnmatched = true;
                ip.addRequired('owner',@(x) isa(x,'ImageList'));
                ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
                ip.addOptional('funParams',[],@isstruct);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                funParams = ip.Results.funParams;

				% Define arguments for superclass constructor
                super_args{1} = owner;
                super_args{2} = FishPreProcessingProcess.getName;
                super_args{3} = @fishPreAlignmentWrap;
                if isempty(funParams)
                    funParams = FishPreProcessingProcess.getDefaultParams(owner,outputDir);
                end
                super_args{4} = funParams;
            end
            obj = obj@ImLImageProcessingProcess(super_args{:});
            obj.is3Dcompatible_ = false; % outputs are 2D
        end

        % function status = checkChannelOutput(obj, iChan, iOutput)
        % % To overwrite ImageProcessingProcess.checkChannelOutput, called in imageDataViewer.m
            
        %    %Checks if the selected channels have valid output images          
        %    nChanTot = numel(obj.owner_.imFolders_);
        %    if nargin < 2 || isempty(iChan), iChan = 1:nChanTot; end
        %    if nargin < 3 || isempty(iOutput), iOutput = 1; end
        %    assert(all(obj.checkChanNum(iChan)));
        %    status =  arrayfun(@(x) exist(obj.outFilePaths_{iOutput, x},'dir') && ...
        %        ~isempty(imDir(obj.outFilePaths_{iOutput, x})),iChan);
        % end

        % function status = checkChanNum(obj,iChan)
        % % To overwrite Process.checkChanNum, called in checkChannelOutput above.
        %     assert(~isempty(iChan) && isnumeric(iChan),'Please provide a valid channel input');
        %     status = insequence(iChan, 1,numel(obj.getOwner().imFolders_));
        % end

%         function outIm = loadChannelOutput(obj, iImFol, iFrame, varargin)
%         % To overwrite ImageProcessingProcess.loadChannelOutput, called in Process.draw
%              % Input check
%             ip =inputParser;
%             ip.addRequired('obj');
%             ip.addRequired('iImFol', @obj.checkChanNum);
%             ip.addRequired('iFrame', (@(x) obj.checkFrameNum(iImFol, x)));
%             % Validator for optional is critical to avoid confusion with parameter
%             if obj.owner_.is3D()
%                 ip.addOptional('iZ', ':', @(x) x(1) == ':' || obj.checkDepthNum(x));
%             end
            
%             ip.addParameter('iOutput', 1, @isnumeric);
%             ip.addParameter('output',[],@ischar);            
            
%             % In case ImageProcessing produces 2D projections, for example
%             ip.addParameter('outputIs3D', false, @(x) islogical(x) || x == 1 || x == 0); 
%             ip.parse(obj,iImFol,iFrame,varargin{:})
            
%             iOutput = ip.Results.iOutput;
%             imNames = obj.getOutImageFileNames(iImFol, iOutput);
            
% % QZ comment out below 3D feature            
% %             if obj.getOwner().is3D() && ip.Results.outputIs3D 
% %                     iZ = ip.Results.iZ;
% %                     if ischar(iZ) && iZ(1) == ':'
% %                         % Default if 3D is to load the whole stack
% %                         outIm = tif3Dread([obj.outFilePaths_{iOutput, iChan} filesep imNames{1}{iFrame}]);
% %                     else 
% %                         % Load first image
% %                         outIm =imread([obj.outFilePaths_{iOutput, iChan} filesep imNames{1}{iFrame}], iZ(1));
% %                         % If this is a RGB image, then make RGB the 4th dimension
% %                         if ndims(outIm) > 2
% %                             sz = size(outIm);
% %                             outIm = reshape(outIm,[sz(1) sz(2) 1 sz(3:end)]);
% %                         end
% %                         % Initialize rest of stack, does nothing if length(iZ) == 1
% %                         outIm(:,:,2:length(iZ),:) = 0;
% %                         % Load rest of stack
% %                         for iiZ = 2:length(iZ)
% %                             outIm(:,:,iiZ) =imread([obj.outFilePaths_{iOutput, iChan} filesep imNames{1}{iFrame}], iZ(iiZ));
% %                         end
% %                     end
% %             else

%                 % QZ To make sure if the size of images are diff, the bigger ones won't get cropped.
%                 nYmax = obj.getOwner.getImFolder(iImFol).getReader.sizeYmax;
%                 nXmax = obj.getOwner.getImFolder(iImFol).getReader.sizeXmax;
%                 outIm = zeros([nYmax nXmax]);
%                 ny = obj.getOwner.getImFolder(iImFol).getReader.sizeY{iFrame,1};
%                 nx = obj.getOwner.getImFolder(iImFol).getReader.sizeX{iFrame,1};

%                 outIm(1:ny,1:nx) =imread([obj.outFilePaths_{iOutput, iImFol} filesep imNames{1}{iFrame}]);
% %             end
%         end

     %    function status = checkFrameNum(obj, iImFol, iFrame)
    	% % To overwrite Process.checkFrameNum, called in loadChannelOutput above.
     %        assert(~isempty(iFrame) && isnumeric(iFrame),'Please provide a valid frame input');
     %        status = insequence(iFrame, 1, obj.getOwner().imFolders_(iImFol).nImages_);
     %    end
        
     %    function fileNames = getOutImageFileNames(obj, iImFol, iOutput)
     %    % To overwrite ImageProcessingProcess.getOutImageFileNames, called in loadChannelOutput above.
     %        nChanTot = numel(obj.owner_.imFolders_);
     %        if nargin < 2 || isempty(iImFol), iImFol = 1:nChanTot; end
     %        if nargin < 3 || isempty(iOutput), iOutput = 1; end
     %        if obj.checkChannelOutput(iImFol, iOutput)
     %            fileNames = cellfun(@(x)(imDir(x)),obj.outFilePaths_(iOutput, iImFol),'UniformOutput',false);
     %            fileNames = cellfun(@(x)(arrayfun(@(x)(x.name),x,'UniformOutput',false)),fileNames,'UniformOutput',false);
     %            nIm = cellfun(@(x)(length(x)),fileNames);
     %            if ~all(nIm == obj.owner_.imFolders_(iImFol).nImages_)                    
     %                error('Incorrect number of images found in one or more channels!')
     %            end                
     %        else
     %            error('Invalid channel numbers! Must be positive integers less than the number of image channels!')
     %        end 
     %    end
    end

    methods (Static)
        function name = getName()
            name = 'Pre-processing';
        end

        function h = GUI(varargin)
            h = @noSettingsProcessGUI % @FishPreProcessingProcessGUI;
        end
        
        function funParams = getDefaultParams(owner, varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'ImageList'));
            ip.addOptional('outputDir', owner.outputDirectory_, @ischar);
            ip.parse(owner, varargin{:})
            outputDir = ip.Results.outputDir;
            
            % Set default parameters
            images = owner.getImages(1);
            sampleImD = images{1};
            funParams.ImageDataIndex = 1:owner.getSize();
            funParams.ImFolderIndex = 1:numel(sampleImD.imFolders_);
            funParams.OutputDirectory = [outputDir  filesep 'PreProcessing'];


            % funParams.vasChannel = 1; % only used in Step 3: Registration
            % funParams.cancerChannel = 2; % only used in Step 4: Cancer Detection
            % funParams.prolifChannel = 3; % did not use this param
            % funParams.nChannel = 2; % or three for Vasanth's data % same as numel(owner.imFolders_), we do not need this param - QZ
            funParams.cropping_borderPX = 100; % add borderPX to the segmented region before cropping
            funParams.padding_minTickness = 50;

        end
    end
end
