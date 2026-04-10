classdef  CreateReferenceImageProcess < ImDImageProcessingProcess & NonSingularProcess
    % Process Class for create reference image
    % createReferenceImageWrap.m is the wrapper function
    % CreateReferenceImageProcess is part of new FishATLAS Package
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
        function obj = CreateReferenceImageProcess(owner, varargin)
            
            if nargin == 0
                super_args = {};
            else
                % Input check
                ip = inputParser;
                ip.CaseSensitive = false;
                ip.KeepUnmatched = true;
                ip.addRequired('owner',@(x) isa(x,'ImageData'));
                ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
                ip.addOptional('funParams',[],@isstruct);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                funParams = ip.Results.funParams;

				% Define arguments for superclass constructor
                super_args{1} = owner;
                super_args{2} = CreateReferenceImageProcess.getName;
                super_args{3} = @createReferenceImageWrap;
                if isempty(funParams)
                    funParams = CreateReferenceImageProcess.getDefaultParams(owner,outputDir);
                end
                super_args{4} = funParams;
            end
            obj = obj@ImDImageProcessingProcess(super_args{:});
            obj.is3Dcompatible_ = false; % outputs are 2D
        end


    end

    methods (Static)
        function name = getName()
            name = 'Reference Image Creation';
        end

        function h = GUI(varargin)
            h = @noSettingsProcessGUI % @CreateReferenceImageProcessGUI;
        end
        
        function funParams = getDefaultParams(owner, varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'ImageData'));
            ip.addOptional('outputDir', owner.outputDirectory_, @ischar);
            ip.parse(owner, varargin{:})
            outputDir = ip.Results.outputDir;
            
            % Set default parameters
            funParams.ImFolderIndex = 1:numel(owner.imFolders_);
            funParams.OutputDirectory = [outputDir  filesep 'CreateRefImage'];
            funParams.ProcessIndex = []; % can use this parameter to set which previous process's output to be used as input for this process



        end
    end
end