classdef  CancerDetectionProcess < ImLImageProcessingProcess & NonSingularProcess
    % Process Class for cancer detection and apply registration map on cancer image/dots
    % cancerDetectionWrap.m is the wrapper function
    % CancerDetectionProcess is part of new FishATLAS Package
    % 
    % Qiongjing (Jenny) Zou, Mar 2026
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
        function obj = CancerDetectionProcess(owner, varargin)
            
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
                super_args{2} = CancerDetectionProcess.getName;
                super_args{3} = @cancerDetectionWrap;
                if isempty(funParams)
                    funParams = CancerDetectionProcess.getDefaultParams(owner,outputDir);
                end
                super_args{4} = funParams;
            end
            obj = obj@ImLImageProcessingProcess(super_args{:});
            obj.is3Dcompatible_ = false; % outputs are 2D
        end


    end

    methods (Static)
        function name = getName()
            name = 'Cancer Detection';
        end

        function h = GUI(varargin)
            h = @noSettingsProcessGUI % @CancerDetectionProcessGUI;
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
            funParams.OutputDirectory = [outputDir  filesep 'CancerDetection'];
            funParams.ProcessIndex = []; % can use this parameter to set which previous process's output to be used as input for this process


            funParams.cancerChannel = 2; % was params.PreAlign.cancerChannel = 2 in Hanieh's script, only used in Step 4: Cancer Detection

            funParams.plotFlag = 1;
            funParams.intensityPerctile = 50;
            funParams.Sigma = 6;
            funParams.Alpha = 0.0005;
            funParams.maxIntensityRateThresh = 0.04; % ..% below max is discarded
            funParams.IntensityThresh = 10; % absolute value
            funParams.weightNThresh = 2;
            funParams.weightFlag = 1; % it can be the flag for the binary image. 
            funParams.Scale = [1 1]; % may need to scale coordinate if refImage is bigger/smaller than cancerimage
            funParams.plotFlag = 1; % create points on cancer channel for each fish and save it.

        end
    end
end
