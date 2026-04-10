classdef ImDImageProcessingProcess < Process
    %A class definition for a generic image processing process for ImageData. That is, a
    %process which takes in images and produces images of the same or diff
    %dimension and same number as output. These images may or may not overwrite
    %the original input images.
    %
    % Adapted from ImageProcessingProcess, but this super class is only for process with ImageData as owner.
    % note: all channel here are imFolder
    %
    % Qiongjing (Jenny) Zou, Feb 2026
    %
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
        
        function obj = ImDImageProcessingProcess(owner,name,funName,funParams,...
                                              inImagePaths,outImagePaths)
                                          
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
            
            if nargin > 4
              if ~isempty(inImagePaths) && numel(inImagePaths) ...
                      ~= numel(owner.imFolders_) || ~iscell(inImagePaths)
                 error('lccb:set:fatal','Input image paths must be a cell-array of the same size as the number of image channels!\n\n'); 
              end         
                obj.inFilePaths_ = inImagePaths;
            else
                %Default is to use raw images as input.
                obj.inFilePaths_ = owner.getImFolderPaths;
            end                        
            if nargin > 5               
                if ~isempty(outImagePaths) && numel(outImagePaths) ... 
                        ~= numel(owner.imFolders_) || ~iscell(outImagePaths)
                    error('lccb:set:fatal','Output image paths must be a cell-array of the same size as the number of image channels!\n\n'); 
                end
                obj.outFilePaths_ = outImagePaths;              
            else
                obj.outFilePaths_ = cell(1,numel(owner.imFolders_));
            end
            
        end
        
        function setOutImagePath(obj,chanNum,imagePath)
            
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
                   error('lccb:set:fatal',...
                       ['The directory specified for channel ' ...
                       num2str(chanNum(j)) ' is invalid!']) 
               else
                   obj.outFilePaths_{1,chanNum(j)} = imagePath{j};                
               end
            end
            
            
        end
        function clearOutImagePath(obj,chanNum)

            if ~obj.checkChanNum(chanNum)
                error('lccb:set:fatal','Invalid image channel number for image path!\n\n'); 
            end
            
            for j = 1:numel(chanNum)
                obj.outFilePaths_{1,chanNum(j)} = [];
            end
        end
        function setInImagePath(obj,chanNum,imagePath)
            
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
                if ~obj.owner_.isBF
                   if ~exist(imagePath{j},'dir')
                       error('lccb:set:fatal',...
                           ['The directory specified for channel ' ...
                           num2str(chanNum(j)) ' is invalid!']) 
                   else
                       obj.inFilePaths_{1,chanNum(j)} = imagePath{j};                
                   end                
                else
                    if ~exist(imagePath{j},'file')
                       error('lccb:set:fatal',...
                           ['The file specified for channel ' ...
                           num2str(chanNum(j)) ' is invalid!']) 
                    else
                       obj.inFilePaths_{1,chanNum(j)} = imagePath{j};                
                    end     
                end
            end                        
        end
        
        function fileNames = getOutImageFileNames(obj, iImFol, iOutput)
        % To overwrite ImageProcessingProcess.getOutImageFileNames, called in loadChannelOutput above.
            nChanTot = numel(obj.owner_.imFolders_);
            if nargin < 2 || isempty(iImFol), iImFol = 1:nChanTot; end
            if nargin < 3 || isempty(iOutput), iOutput = 1; end
            if obj.checkChannelOutput(iImFol, iOutput)
                fileNames = cellfun(@(x)(imDir(x)),obj.outFilePaths_(iOutput, iImFol),'UniformOutput',false);
                fileNames = cellfun(@(x)(arrayfun(@(x)(x.name),x,'UniformOutput',false)),fileNames,'UniformOutput',false);
                nIm = cellfun(@(x)(length(x)),fileNames);
                if ~all(nIm == obj.owner_.imFolders_(iImFol).nImages_)                    
                    error('Incorrect number of images found in one or more channels!')
                end                
            else
                error('Invalid channel numbers! Must be positive integers less than the number of image channels!')
            end 
        end

        function fileNames = getInImageFileNames(obj,iChan)
            nChanTot = numel(obj.owner_.channels_);
            if nargin < 2 || isempty(iChan), iChan = 1:nChanTot; end
            if obj.checkChanNum(iChan)
                fileNames = cellfun(@(x)(imDir(x)),obj.inFilePaths_(1,iChan),'UniformOutput',false);
                fileNames = cellfun(@(x)(arrayfun(@(x)(x.name),x,'UniformOutput',false)),fileNames,'UniformOutput',false);
                nIm = cellfun(@(x)(length(x)),fileNames);
                if ~all(nIm == obj.owner_.nFrames_)                    
                    error('Incorrect number of images found in one or more channels!')
                end                
            else
                error('Invalid channel numbers! Must be positive integers less than the number of image channels!')
            end    
            
            
        end
               
        function status = checkChannelOutput(obj, iChan, iOutput)
            
           %Checks if the selected channels have valid output images          
           nChanTot = numel(obj.owner_.imFolders_);
           if nargin < 2 || isempty(iChan), iChan = 1:nChanTot; end
           if nargin < 3 || isempty(iOutput), iOutput = 1; end
           assert(all(obj.checkChanNum(iChan)));
           status =  arrayfun(@(x) exist(obj.outFilePaths_{iOutput, x},'dir') && ...
               ~isempty(imDir(obj.outFilePaths_{iOutput, x})),iChan);
        end

        function status = checkChanNum(obj,iChan)
        % To overwrite Process.checkChanNum, called in checkChannelOutput above.
            assert(~isempty(iChan) && isnumeric(iChan),'Please provide a valid channel input');
            status = insequence(iChan, 1,numel(obj.getOwner().imFolders_));
        end
        
        function outIm = loadOutImage(obj, iChan, iFrame, varargin)
            outIm=obj.loadChannelOutput(iChan, iFrame, varargin{:});
        end

        function outStack = loadOutStack(obj, iChan, iFrame, varargin)            
            if obj.owner_.is3D()
                checkCompatible3DOutput = true;
                if ~isempty(obj.is3Dcompatible_) && ~obj.is3Dcompatible_
                    checkCompatible3DOutput = false;
                end
                if checkCompatible3DOutput
                    outStack = obj.loadChannelOutput(iChan, iFrame, ':', varargin{:});
                else
                    outStack = obj.loadOutImage(iChan, iFrame, varargin{:});
                end
            else
                outStack = obj.loadOutImage(iChan, iFrame, varargin{:});
            end
        end
        
        function outIm = loadChannelOutput(obj, iImFol, iFrame, varargin)
        % To overwrite ImageProcessingProcess.loadChannelOutput, called in Process.draw
             % Input check
            ip =inputParser;
            ip.addRequired('obj');
            ip.addRequired('iImFol', @obj.checkChanNum);
            ip.addRequired('iFrame', (@(x) obj.checkFrameNum(iImFol, x)));
            % Validator for optional is critical to avoid confusion with parameter
            if obj.owner_.is3D()
                ip.addOptional('iZ', ':', @(x) x(1) == ':' || obj.checkDepthNum(x));
            end
            
            ip.addParameter('iOutput', 1, @isnumeric);
            ip.addParameter('output',[],@ischar);            
            
            % In case ImageProcessing produces 2D projections, for example
            ip.addParameter('outputIs3D', false, @(x) islogical(x) || x == 1 || x == 0); 
            ip.parse(obj,iImFol,iFrame,varargin{:})
            
            iOutput = ip.Results.iOutput;
            imNames = obj.getOutImageFileNames(iImFol, iOutput);
            
            % QZ To make sure if the size of images are diff, the bigger ones won't get cropped.
            nYmax = obj.getOwner.getImFolder(iImFol).getReader.sizeYmax;
            nXmax = obj.getOwner.getImFolder(iImFol).getReader.sizeXmax;
            outIm = zeros([nYmax nXmax]);
            ny = obj.getOwner.getImFolder(iImFol).getReader.sizeY{iFrame,1};
            nx = obj.getOwner.getImFolder(iImFol).getReader.sizeX{iFrame,1};

            outIm(1:ny,1:nx) =imread([obj.outFilePaths_{iOutput, iImFol} filesep imNames{1}{iFrame}]);

        end

        function status = checkFrameNum(obj, iImFol, iFrame)
        % To overwrite Process.checkFrameNum, called in loadChannelOutput above.
            assert(~isempty(iFrame) && isnumeric(iFrame),'Please provide a valid frame input');
            status = insequence(iFrame, 1, obj.getOwner().imFolders_(iImFol).nImages_);
        end
        
        function drawImaris(obj,iceConn)
            
            dataSet = iceConn.mImarisApplication.GetDataSet;            
            nChanRaw = numel(obj.owner_.channels_);
            nFrames = obj.owner_.nFrames_;
            for iChan = 1:nChanRaw
                
                if obj.checkChannelOutput(iChan)
                                        
                    nChanDisp = dataSet.GetSizeC + 1;
                    dataSet.SetSizeC(nChanDisp)
                    dataSet.SetChannelName(nChanDisp-1,[ char(dataSet.GetChannelName(iChan-1)) ' ' obj.name_]);
                    dataSet.SetChannelColorRGBA(nChanDisp-1,dataSet.GetChannelColorRGBA(iChan-1));                    
                    datMin = Inf;
                    datMax = -Inf;
                    for iFrame = 1:nFrames
                        vol = obj.loadChannelOutput(iChan,iFrame);                        
                        datMin = min(min(vol(:)),datMin);
                        datMax = max(max(vol(:)),datMax);
                        iceConn.setDataVolume(vol,nChanDisp-1,iFrame-1);                       
                    end
                    dataSet.SetChannelRange(nChanDisp-1,datMin,datMax);                   
                end                
            end
            
        end
        
        
    end
    methods(Static)
        function output = getDrawableOutput()
            output(1).name='Images';
            output(1).var='';
            output(1).formatData=@mat2gray;
            output(1).type='image';
            output(1).defaultDisplayMethod=@ImageDisplay;
        end
        
    end
    
end
