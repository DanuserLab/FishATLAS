function varargout = FishStatsAnalysisProcessGUI(varargin)
%FISHSTATSANALYSISPROCESSGUI MATLAB code file for FishStatsAnalysisProcessGUI.fig
%      FISHSTATSANALYSISPROCESSGUI, by itself, creates a new FISHSTATSANALYSISPROCESSGUI or raises the existing
%      singleton*.
%
%      H = FISHSTATSANALYSISPROCESSGUI returns the handle to a new FISHSTATSANALYSISPROCESSGUI or the handle to
%      the existing singleton*.
%
%      FISHSTATSANALYSISPROCESSGUI('Property','Value',...) creates a new FISHSTATSANALYSISPROCESSGUI using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to FishStatsAnalysisProcessGUI_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      FISHSTATSANALYSISPROCESSGUI('CALLBACK') and FISHSTATSANALYSISPROCESSGUI('CALLBACK',hObject,...) call the
%      local function named CALLBACK in FISHSTATSANALYSISPROCESSGUI.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
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

% Edit the above text to modify the response to help FishStatsAnalysisProcessGUI

% Last Modified by GUIDE v2.5 03-Sep-2026 14:51:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FishStatsAnalysisProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @FishStatsAnalysisProcessGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
   gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before FishStatsAnalysisProcessGUI is made visible.
function FishStatsAnalysisProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:});

% Parameter setup
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
funParams = userData.crtProc.funParams_;


% set GUI with Parameters (this section is different for each GUI)
set(handles.edit_Rigid_maxIter, 'String',num2str(funParams.Rigid.maxIter))
set(handles.edit_nonRigid_maxIter, 'String',num2str(funParams.nonRigid.maxIter))
set(handles.edit_nonRigid_GridRegularization, 'String',num2str(funParams.nonRigid.GridRegularization))
set(handles.edit_nonRigid_NumPyramidLevels, 'String',num2str(funParams.nonRigid.NumPyramidLevels))
set(handles.edit_nonRigid_AccumulatedFieldSmoothing, 'String',num2str(funParams.nonRigid.AccumulatedFieldSmoothing))
set(handles.edit_nonRigid_FilterThreshold, 'String',num2str(funParams.nonRigid.FilterThreshold))
set(handles.checkbox_VisPointRefImageFish,'Value',funParams.VisPointRefImageFish);

%Setup Rigid Transform Type pop up menu:
set(handles.popupmenu_Rigid_tformType, 'String', FishStatsAnalysisProcess.getValid_Rigid_tformType);
parVal = funParams.Rigid.tformType;
valSel  = find(ismember(FishStatsAnalysisProcess.getValid_Rigid_tformType, parVal));
if isempty(valSel), valSel = 1; end
set(handles.popupmenu_Rigid_tformType, 'Value', valSel);

%Setup Rigid Modality pop up menu:
set(handles.popupmenu_Rigid_regmodel, 'String', FishStatsAnalysisProcess.getValid_Rigid_regmodel);
parVal = funParams.Rigid.regmodel;
valSel  = find(ismember(FishStatsAnalysisProcess.getValid_Rigid_regmodel, parVal));
if isempty(valSel), valSel = 1; end
set(handles.popupmenu_Rigid_regmodel, 'Value', valSel);

%Setup Nonrigid Filter Metric pop up menu:
set(handles.popupmenu_nonRigid_FilterMetric, 'String', FishStatsAnalysisProcess.getValid_nonRigid_FilterMetric);
parVal = funParams.nonRigid.FilterMetric;
valSel  = find(ismember(FishStatsAnalysisProcess.getValid_nonRigid_FilterMetric, parVal));
if isempty(valSel), valSel = 1; end
set(handles.popupmenu_nonRigid_FilterMetric, 'Value', valSel);

set(handles.checkbox_usefishBodyImage,'Value',funParams.usefishBodyImage);
if funParams.usefishBodyImage
    set(get(handles.uipanel_usefishBodyImage,'Children'),'Enable','on');
else
    set(get(handles.uipanel_usefishBodyImage,'Children'),'Enable','off');
end
set(handles.edit_fishBodyfilePath, 'String', funParams.fishBodyfilePath)

set(handles.edit_NN_Radius, 'String',num2str(funParams.NN.Radius))
set(handles.edit_NN_densityBin, 'String',num2str(funParams.NN.densityBin))

set(handles.edit_TopRankRegion_Radius, 'String',num2str(funParams.TopRankRegion.Radius))
set(handles.edit_TopRankRegion_randSelection, 'String',num2str(funParams.TopRankRegion.randSelection))
set(handles.edit_TopRankRegion_DownSampleNFish, 'String',num2str(funParams.TopRankRegion.DownSampleNFish))
set(handles.edit_TopRankRegion_densityBin, 'String',num2str(funParams.TopRankRegion.densityBin))
set(handles.edit_TopRankRegion_overlapCutoff, 'String',num2str(funParams.TopRankRegion.overlapCutoff))

set(handles.edit_Dispersion_randNum, 'String',num2str(funParams.Dispersion.randNum))
set(handles.edit_Dispersion_Radius, 'String',num2str(funParams.Dispersion.Radius))

set(handles.checkbox_ManualRegion_Flag,'Value',funParams.ManualRegion.Flag);
if funParams.ManualRegion.Flag
    set(get(handles.uipanel_ManualRegion,'Children'),'Enable','on');
else
    set(get(handles.uipanel_ManualRegion,'Children'),'Enable','off');
end
set(handles.edit_ManualRegion_nMark, 'String',num2str(funParams.ManualRegion.nMark))
set(handles.edit_ManualRegion_randNum, 'String',num2str(funParams.ManualRegion.randNum))
set(handles.checkbox_ManualRegion_useRegionMask,'Value',funParams.ManualRegion.useRegionMask);
if funParams.ManualRegion.Flag && funParams.ManualRegion.useRegionMask
    set(handles.pushbutton_ManualRegion_fishBodyImagePath,'Enable','on');
    set(handles.edit_ManualRegion_fishBodyImagePath,'Enable','on');
else
    set(handles.pushbutton_ManualRegion_fishBodyImagePath,'Enable','off');
    set(handles.edit_ManualRegion_fishBodyImagePath,'Enable','off');
end
set(handles.edit_ManualRegion_fishBodyImagePath, 'String', funParams.ManualRegion.fishBodyImagePath)

set(handles.checkbox_BoxGrid_Flag,'Value',funParams.BoxGrid.Flag);
if funParams.BoxGrid.Flag
    set(get(handles.uipanel_BoxGrid,'Children'),'Enable','on');
else
    set(get(handles.uipanel_BoxGrid,'Children'),'Enable','off');
end
set(handles.edit_BoxGrid_boxSize, 'String',num2str(funParams.BoxGrid.boxSize))
set(handles.checkbox_BoxGrid_useBoundingFish,'Value',funParams.BoxGrid.useBoundingFish);
set(handles.checkbox_BoxGrid_DominantRegionFlag,'Value',funParams.BoxGrid.DominantRegionFlag);
set(handles.edit_BoxGrid_CoexistThresh, 'String',num2str(funParams.BoxGrid.CoexistThresh))
set(handles.checkbox_BoxGrid_useAutoCoExistThresh,'Value',funParams.BoxGrid.useAutoCoExistThresh);
set(handles.edit_BoxGrid_CoExistRandNum, 'String',num2str(funParams.BoxGrid.CoExistRandNum))

% Update user data and GUI data
handles.output = hObject;
set(handles.figure1, 'UserData', userData);
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = FishStatsAnalysisProcessGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)

userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end

if isfield(userData, 'helpFig') && ishandle(userData.helpFig)
   delete(userData.helpFig)
end

set(handles.figure1, 'UserData', userData);
guidata(hObject,handles);


% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)

if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end


% --- Executes on button press in pushbutton_cancel.
function pushbutton_cancel_Callback(hObject, eventdata, handles)

delete(handles.figure1);


% --- Executes on button press in pushbutton_done.
function pushbutton_done_Callback(hObject, eventdata, handles)

% Call back function of 'Apply' button
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end

% -------- Check user input --------  (this section is different for each GUI)

RigidMaxIter = str2double(get(handles.edit_Rigid_maxIter, 'String'));
if isnan(RigidMaxIter) || RigidMaxIter < 1 || ~isequal(round(RigidMaxIter), RigidMaxIter)
  errordlg('Please provide a valid input for ''Rigid Maximum Iteration''.','Setting Error','modal');
  return;
end

nonRigidMaxIter = str2double(get(handles.edit_nonRigid_maxIter, 'String'));
if isnan(nonRigidMaxIter) || nonRigidMaxIter < 1 || ~isequal(round(nonRigidMaxIter), nonRigidMaxIter)
  errordlg('Please provide a valid input for ''Nonrigid Maximum Iteration''.','Setting Error','modal');
  return;
end

nonRigidGridRegularization = str2double(get(handles.edit_nonRigid_GridRegularization, 'String'));
if isnan(nonRigidGridRegularization) || nonRigidGridRegularization < 0
  errordlg('Please provide a valid input for ''Nonrigid Grid Regularization''.','Setting Error','modal');
  return;
end

nonRigidNumPyramidLevels = str2double(get(handles.edit_nonRigid_NumPyramidLevels, 'String'));
if isnan(nonRigidNumPyramidLevels) || nonRigidNumPyramidLevels < 1 || ~isequal(round(nonRigidNumPyramidLevels), nonRigidNumPyramidLevels)
  errordlg('Please provide a valid input for ''Nonrigid Pyramid Level''.','Setting Error','modal');
  return;
end

nonRigidAccumulatedFieldSmoothing = str2double(get(handles.edit_nonRigid_AccumulatedFieldSmoothing, 'String'));
if isnan(nonRigidAccumulatedFieldSmoothing) || nonRigidAccumulatedFieldSmoothing < 0
  errordlg('Please provide a valid input for ''Nonrigid Accumulated Field Smoothing''.','Setting Error','modal');
  return;
end

nonRigidFilterThreshold = str2double(get(handles.edit_nonRigid_FilterThreshold, 'String'));
if isnan(nonRigidFilterThreshold) || nonRigidFilterThreshold < 0
  errordlg('Please provide a valid input for ''Nonrigid Filter Threshold''.','Setting Error','modal');
  return;
end

usefishBodyImage = get(handles.checkbox_usefishBodyImage,'Value');
fishBodyfilePath = strtrim(get(handles.edit_fishBodyfilePath, 'String'));
if usefishBodyImage
    [~,~,fishBodyImageExt] = fileparts(fishBodyfilePath);
    isFullPath = ~isempty(regexp(fishBodyfilePath, '(^[A-Za-z]:[\\/])|(^[/\\]{2})|(^/)', 'once'));
    if isempty(fishBodyfilePath) || ~isFullPath || exist(fishBodyfilePath,'file') ~= 2 ...
            || ~ismember(lower(fishBodyImageExt), {'.tif', '.tiff'})
        errordlg('Please provide a valid full path to a binary TIFF fish body image.','Setting Error','modal');
        return;
    end
end

NNRadius = str2double(get(handles.edit_NN_Radius, 'String'));
if isnan(NNRadius) || NNRadius <= 0
  errordlg('Please provide a valid input for ''Radius for NN Analysis''.','Setting Error','modal');
  return;
end

NNDensityBin = str2num(get(handles.edit_NN_densityBin, 'String')); %#ok<ST2NM>
if isempty(NNDensityBin) || ~isnumeric(NNDensityBin) || any(isnan(NNDensityBin(:))) || any(NNDensityBin(:) < 0)
  errordlg('Please provide a valid input for ''Population Class''.','Setting Error','modal');
  return;
end

TopRankRegionRadius = str2double(get(handles.edit_TopRankRegion_Radius, 'String'));
if isnan(TopRankRegionRadius) || TopRankRegionRadius <= 0
  errordlg('Please provide a valid input for ''Radius for Top Ranked Region Analysis''.','Setting Error','modal');
  return;
end

TopRankRegionRandSelection = str2double(get(handles.edit_TopRankRegion_randSelection, 'String'));
if isnan(TopRankRegionRandSelection) || TopRankRegionRandSelection < 1 || ~isequal(round(TopRankRegionRandSelection), TopRankRegionRandSelection)
  errordlg('Please provide a valid input for ''Random Number''.','Setting Error','modal');
  return;
end

TopRankRegionDownSampleNFish = str2double(get(handles.edit_TopRankRegion_DownSampleNFish, 'String'));
if isnan(TopRankRegionDownSampleNFish) || TopRankRegionDownSampleNFish < 1 || ~isequal(round(TopRankRegionDownSampleNFish), TopRankRegionDownSampleNFish)
  errordlg('Please provide a valid input for ''Downsample Fish Number''.','Setting Error','modal');
  return;
end

TopRankRegionDensityBin = str2num(get(handles.edit_TopRankRegion_densityBin, 'String')); %#ok<ST2NM>
if isempty(TopRankRegionDensityBin) || ~isnumeric(TopRankRegionDensityBin) || any(isnan(TopRankRegionDensityBin(:))) || any(TopRankRegionDensityBin(:) < 0)
  errordlg('Please provide a valid input for ''Population Class''.','Setting Error','modal');
  return;
end

TopRankRegionOverlapCutoff = str2double(get(handles.edit_TopRankRegion_overlapCutoff, 'String'));
if isnan(TopRankRegionOverlapCutoff) || TopRankRegionOverlapCutoff < 0 || TopRankRegionOverlapCutoff > 1
  errordlg('Please provide a valid input for ''Overlap Threshold''.','Setting Error','modal');
  return;
end

DispersionRandNum = str2double(get(handles.edit_Dispersion_randNum, 'String'));
if isnan(DispersionRandNum) || DispersionRandNum < 1 || ~isequal(round(DispersionRandNum), DispersionRandNum)
  errordlg('Please provide a valid input for ''Random Number''.','Setting Error','modal');
  return;
end

DispersionRadius = str2double(get(handles.edit_Dispersion_Radius, 'String'));
if isnan(DispersionRadius) || DispersionRadius <= 0
  errordlg('Please provide a valid input for ''Radius for Dispersion Analysis''.','Setting Error','modal');
  return;
end

ManualRegionFlag = get(handles.checkbox_ManualRegion_Flag,'Value');
ManualRegionNMark = str2double(get(handles.edit_ManualRegion_nMark, 'String'));
ManualRegionUseRegionMask = get(handles.checkbox_ManualRegion_useRegionMask,'Value');
ManualRegionFishBodyImagePath = strtrim(get(handles.edit_ManualRegion_fishBodyImagePath, 'String'));
ManualRegionRandNum = str2double(get(handles.edit_ManualRegion_randNum, 'String'));
if ManualRegionFlag % only check validation when this is ture
if isnan(ManualRegionNMark) || ManualRegionNMark < 1 || ~isequal(round(ManualRegionNMark), ManualRegionNMark)
  errordlg('Please provide a valid input for ''Number of Clicks''.','Setting Error','modal');
  return;
end

if ManualRegionFlag && ManualRegionUseRegionMask
    [~,~,ManualRegionFishBodyImageExt] = fileparts(ManualRegionFishBodyImagePath);
    isFullPath = ~isempty(regexp(ManualRegionFishBodyImagePath, '(^[A-Za-z]:[\\/])|(^[/\\]{2})|(^/)', 'once'));
    if isempty(ManualRegionFishBodyImagePath) || ~isFullPath || exist(ManualRegionFishBodyImagePath,'file') ~= 2 ...
            || ~ismember(lower(ManualRegionFishBodyImageExt), {'.tif', '.tiff'})
        errordlg('Please provide a valid full path to a binary TIFF manual region mask.','Setting Error','modal');
        return;
    end
end

if isnan(ManualRegionRandNum) || ManualRegionRandNum < 1 || ~isequal(round(ManualRegionRandNum), ManualRegionRandNum)
  errordlg('Please provide a valid input for ''Random Number''.','Setting Error','modal');
  return;
end
end

BoxGridFlag = get(handles.checkbox_BoxGrid_Flag,'Value');
BoxGridBoxSize = str2num(get(handles.edit_BoxGrid_boxSize, 'String')); %#ok<ST2NM>
BoxGridCoexistThreshString = strtrim(get(handles.edit_BoxGrid_CoexistThresh, 'String'));
BoxGridCoexistThreshIsEmpty = isempty(BoxGridCoexistThreshString) || strcmp(BoxGridCoexistThreshString, '[]');
if BoxGridCoexistThreshIsEmpty
    BoxGridCoexistThresh = [];
else
    BoxGridCoexistThresh = str2num(BoxGridCoexistThreshString); %#ok<ST2NM>
end
BoxGridCoExistRandNum = str2double(get(handles.edit_BoxGrid_CoExistRandNum, 'String'));
if BoxGridFlag % only check validation when this is ture
if isempty(BoxGridBoxSize) || ~isnumeric(BoxGridBoxSize) || numel(BoxGridBoxSize) ~= 2 ...
        || any(isnan(BoxGridBoxSize(:))) || any(BoxGridBoxSize(:) <= 0)
  errordlg('Please provide a valid input for ''Box Size''.','Setting Error','modal');
  return;
end

if ~BoxGridCoexistThreshIsEmpty
    if isempty(BoxGridCoexistThresh) || ~isnumeric(BoxGridCoexistThresh) ...
            || any(isnan(BoxGridCoexistThresh(:))) || any(BoxGridCoexistThresh(:) < 0) || any(BoxGridCoexistThresh(:) > 1)
        errordlg('Please provide a valid input for ''Coexist Thresh''.','Setting Error','modal');
        return;
    end
end

if isnan(BoxGridCoExistRandNum) || BoxGridCoExistRandNum < 1 || ~isequal(round(BoxGridCoExistRandNum), BoxGridCoExistRandNum)
  errordlg('Please provide a valid input for ''Co-existence Random Number''.','Setting Error','modal');
  return;
end
end

% -------- Process Sanity check --------
% ( only check underlying data )
try
    userData.crtProc.sanityCheck;
catch ME
    errordlg([ME.message 'Please double check your data.'],...
                'Setting Error','modal');
    return;
end

% Retrieve GUI-defined parameters  (this section is different for each GUI)
funParams.Rigid.maxIter = RigidMaxIter;
funParams.nonRigid.maxIter = nonRigidMaxIter;
funParams.nonRigid.GridRegularization = nonRigidGridRegularization;
funParams.nonRigid.NumPyramidLevels = nonRigidNumPyramidLevels;
funParams.nonRigid.AccumulatedFieldSmoothing = nonRigidAccumulatedFieldSmoothing;
funParams.nonRigid.FilterThreshold = nonRigidFilterThreshold;
funParams.VisPointRefImageFish = get(handles.checkbox_VisPointRefImageFish,'Value');

selType = get(handles.popupmenu_Rigid_tformType, 'Value');
funParams.Rigid.tformType = FishStatsAnalysisProcess.getValid_Rigid_tformType{selType};

selType = get(handles.popupmenu_Rigid_regmodel, 'Value');
funParams.Rigid.regmodel = FishStatsAnalysisProcess.getValid_Rigid_regmodel{selType};

selType = get(handles.popupmenu_nonRigid_FilterMetric, 'Value');
funParams.nonRigid.FilterMetric = FishStatsAnalysisProcess.getValid_nonRigid_FilterMetric{selType};

funParams.usefishBodyImage = usefishBodyImage;
funParams.fishBodyfilePath = fishBodyfilePath;
funParams.NN.Radius = NNRadius;
funParams.NN.densityBin = NNDensityBin;
funParams.TopRankRegion.Radius = TopRankRegionRadius;
funParams.TopRankRegion.randSelection = TopRankRegionRandSelection;
funParams.TopRankRegion.DownSampleNFish = TopRankRegionDownSampleNFish;
funParams.TopRankRegion.densityBin = TopRankRegionDensityBin;
funParams.TopRankRegion.overlapCutoff = TopRankRegionOverlapCutoff;
funParams.Dispersion.randNum = DispersionRandNum;
funParams.Dispersion.Radius = DispersionRadius;
funParams.ManualRegion.Flag = ManualRegionFlag;
funParams.ManualRegion.nMark = ManualRegionNMark;
funParams.ManualRegion.useRegionMask = ManualRegionUseRegionMask;
funParams.ManualRegion.fishBodyImagePath = ManualRegionFishBodyImagePath;
funParams.ManualRegion.randNum = ManualRegionRandNum;
funParams.BoxGrid.Flag = BoxGridFlag;
funParams.BoxGrid.boxSize = BoxGridBoxSize;
funParams.BoxGrid.useBoundingFish = get(handles.checkbox_BoxGrid_useBoundingFish,'Value');
funParams.BoxGrid.DominantRegionFlag = get(handles.checkbox_BoxGrid_DominantRegionFlag,'Value');
funParams.BoxGrid.CoexistThresh = BoxGridCoexistThresh;
funParams.BoxGrid.useAutoCoExistThresh = get(handles.checkbox_BoxGrid_useAutoCoExistThresh,'Value');
funParams.BoxGrid.CoExistRandNum = BoxGridCoExistRandNum;


% Set parameters and update main window
processGUI_ApplyFcn(hObject, eventdata, handles,funParams);


% --- Executes on key press with focus on pushbutton_done and none of its controls.
function pushbutton_done_KeyPressFcn(hObject, eventdata, handles)

if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end




% --- Executes on button press in checkbox_usefishBodyImage.
function checkbox_usefishBodyImage_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
    set(get(handles.uipanel_usefishBodyImage,'Children'),'Enable','on');
else
    set(get(handles.uipanel_usefishBodyImage,'Children'),'Enable','off');
end




% --- Executes on button press in pushbutton_fishBodyfilePath.
function pushbutton_fishBodyfilePath_Callback(hObject, eventdata, handles)

[filename, pathname] = uigetfile({'*.tif;*.tiff', 'TIFF Files (*.tif, *.tiff)'}, ...
    'Select a file of the fish body image');

if isequal(filename, 0)
    return;
end

set(handles.edit_fishBodyfilePath, 'String', fullfile(pathname, filename));




% --- Executes on button press in checkbox_ManualRegion_Flag.
function checkbox_ManualRegion_Flag_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
    set(get(handles.uipanel_ManualRegion,'Children'),'Enable','on');
    checkbox_ManualRegion_useRegionMask_Callback(handles.checkbox_ManualRegion_useRegionMask, eventdata, handles);
else
    set(get(handles.uipanel_ManualRegion,'Children'),'Enable','off');
end



% --- Executes on button press in checkbox_useRegionMask.
function checkbox_ManualRegion_useRegionMask_Callback(hObject, eventdata, handles)

if get(handles.checkbox_ManualRegion_Flag,'Value') && get(hObject,'Value')
    set(handles.pushbutton_ManualRegion_fishBodyImagePath,'Enable','on');
    set(handles.edit_ManualRegion_fishBodyImagePath,'Enable','on');
else
    set(handles.pushbutton_ManualRegion_fishBodyImagePath,'Enable','off');
    set(handles.edit_ManualRegion_fishBodyImagePath,'Enable','off');
end



% --- Executes on button press in pushbutton_ManualRegion_fishBodyImagePath.
function pushbutton_ManualRegion_fishBodyImagePath_Callback(hObject, eventdata, handles)

[filename, pathname] = uigetfile({'*.tif;*.tiff', 'TIFF Files (*.tif, *.tiff)'}, ...
    'Select a file of the manual region mask');

if isequal(filename, 0)
    return;
end

set(handles.edit_ManualRegion_fishBodyImagePath, 'String', fullfile(pathname, filename));


% --- Executes on button press in checkbox_BoxGrid_Flag.
function checkbox_BoxGrid_Flag_Callback(hObject, eventdata, handles)

if get(hObject,'Value')
    set(get(handles.uipanel_BoxGrid,'Children'),'Enable','on');
else
    set(get(handles.uipanel_BoxGrid,'Children'),'Enable','off');
end
