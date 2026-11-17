function varargout = CreateReferenceImageProcessGUI(varargin)
%CREATEREFERENCEIMAGEPROCESSGUI MATLAB code file for CreateReferenceImageProcessGUI.fig
%      CREATEREFERENCEIMAGEPROCESSGUI, by itself, creates a new CREATEREFERENCEIMAGEPROCESSGUI or raises the existing
%      singleton*.
%
%      H = CREATEREFERENCEIMAGEPROCESSGUI returns the handle to a new CREATEREFERENCEIMAGEPROCESSGUI or the handle to
%      the existing singleton*.
%
%      CREATEREFERENCEIMAGEPROCESSGUI('Property','Value',...) creates a new CREATEREFERENCEIMAGEPROCESSGUI using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to CreateReferenceImageProcessGUI_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      CREATEREFERENCEIMAGEPROCESSGUI('CALLBACK') and CREATEREFERENCEIMAGEPROCESSGUI('CALLBACK',hObject,...) call the
%      local function named CALLBACK in CREATEREFERENCEIMAGEPROCESSGUI.M with the given input
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

% Edit the above text to modify the response to help CreateReferenceImageProcessGUI

% Last Modified by GUIDE v2.5 14-Aug-2026 14:00:11

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CreateReferenceImageProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @CreateReferenceImageProcessGUI_OutputFcn, ...
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


% --- Executes just before CreateReferenceImageProcessGUI is made visible.
function CreateReferenceImageProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:});

% Parameter setup
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
funParams = userData.crtProc.funParams_;


% set GUI with Parameters (this section is different for each GUI)
set(handles.edit_rigid_RefImageID, 'String',num2str(funParams.rigid.RefImageID))
set(handles.edit_rigid_maxIter, 'String',num2str(funParams.rigid.maxIter))
set(handles.edit_rigid_FilterThreshold, 'String',num2str(funParams.rigid.FilterThreshold))
set(handles.edit_nonRigid_maxIter, 'String',num2str(funParams.nonRigid.maxIter))
set(handles.edit_nonRigid_GridRegularization, 'String',num2str(funParams.nonRigid.GridRegularization))
set(handles.edit_nonRigid_NumPyramidLevels, 'String',num2str(funParams.nonRigid.NumPyramidLevels))
set(handles.edit_nonRigid_FilterThreshold, 'String',num2str(funParams.nonRigid.FilterThreshold))

%Setup Rigid Transform Type pop up menu:
set(handles.popupmenu_rigid_tformType, 'String', CreateReferenceImageProcess.getValid_rigid_tformType);
parVal = funParams.rigid.tformType;
valSel  = find(ismember(CreateReferenceImageProcess.getValid_rigid_tformType, parVal));
if isempty(valSel), valSel = 1; end
set(handles.popupmenu_rigid_tformType, 'Value', valSel);

%Setup Rigid Modality pop up menu:
set(handles.popupmenu_rigid_regmodel, 'String', CreateReferenceImageProcess.getValid_rigid_regmodel);
parVal = funParams.rigid.regmodel;
valSel  = find(ismember(CreateReferenceImageProcess.getValid_rigid_regmodel, parVal));
if isempty(valSel), valSel = 1; end
set(handles.popupmenu_rigid_regmodel, 'Value', valSel);

%Setup Rigid Filter Metric pop up menu:
set(handles.popupmenu_rigid_FilterMetric, 'String', CreateReferenceImageProcess.getValid_rigid_FilterMetric);
parVal = funParams.rigid.FilterMetric;
valSel  = find(ismember(CreateReferenceImageProcess.getValid_rigid_FilterMetric, parVal));
if isempty(valSel), valSel = 1; end
set(handles.popupmenu_rigid_FilterMetric, 'Value', valSel);

%Setup Nonrigid Filter Metric pop up menu:
set(handles.popupmenu_nonRigid_FilterMetric, 'String', CreateReferenceImageProcess.getValid_nonRigid_FilterMetric);
parVal = funParams.nonRigid.FilterMetric;
valSel  = find(ismember(CreateReferenceImageProcess.getValid_nonRigid_FilterMetric, parVal));
if isempty(valSel), valSel = 1; end
set(handles.popupmenu_nonRigid_FilterMetric, 'Value', valSel);


% Update user data and GUI data
handles.output = hObject;
set(handles.figure1, 'UserData', userData);
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = CreateReferenceImageProcessGUI_OutputFcn(hObject, eventdata, handles)
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

rigidRefImageIDString = strtrim(get(handles.edit_rigid_RefImageID, 'String'));
if ~isempty(rigidRefImageIDString)
    rigidRefImageID = str2double(rigidRefImageIDString);
    if isnan(rigidRefImageID) || rigidRefImageID < 1 || ~isequal(round(rigidRefImageID), rigidRefImageID)
        errordlg('Please provide a valid input for ''Rigid Transform Image ID''.','Setting Error','modal');
        return;
    end
else
    rigidRefImageID = [];
end

rigidMaxIter = str2double(get(handles.edit_rigid_maxIter, 'String'));
if isnan(rigidMaxIter) || rigidMaxIter < 1 || ~isequal(round(rigidMaxIter), rigidMaxIter)
  errordlg('Please provide a valid input for ''Rigid Maximum Iteration''.','Setting Error','modal');
  return;
end

rigidFilterThreshold = str2double(get(handles.edit_rigid_FilterThreshold, 'String'));
if isnan(rigidFilterThreshold) || rigidFilterThreshold < 0
  errordlg('Please provide a valid input for ''Rigid Filter Threshold''.','Setting Error','modal');
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

nonRigidFilterThreshold = str2double(get(handles.edit_nonRigid_FilterThreshold, 'String'));
if isnan(nonRigidFilterThreshold) || nonRigidFilterThreshold < 0
  errordlg('Please provide a valid input for ''Nonrigid Filter Threshold''.','Setting Error','modal');
  return;
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
funParams.rigid.RefImageID = rigidRefImageID;
funParams.rigid.maxIter = rigidMaxIter;
funParams.rigid.FilterThreshold = rigidFilterThreshold;
funParams.nonRigid.maxIter = nonRigidMaxIter;
funParams.nonRigid.GridRegularization = nonRigidGridRegularization;
funParams.nonRigid.NumPyramidLevels = nonRigidNumPyramidLevels;
funParams.nonRigid.FilterThreshold = nonRigidFilterThreshold;

selType = get(handles.popupmenu_rigid_tformType, 'Value');
funParams.rigid.tformType = CreateReferenceImageProcess.getValid_rigid_tformType{selType};

selType = get(handles.popupmenu_rigid_regmodel, 'Value');
funParams.rigid.regmodel = CreateReferenceImageProcess.getValid_rigid_regmodel{selType};

selType = get(handles.popupmenu_rigid_FilterMetric, 'Value');
funParams.rigid.FilterMetric = CreateReferenceImageProcess.getValid_rigid_FilterMetric{selType};

selType = get(handles.popupmenu_nonRigid_FilterMetric, 'Value');
funParams.nonRigid.FilterMetric = CreateReferenceImageProcess.getValid_nonRigid_FilterMetric{selType};


% Set parameters and update main window
processGUI_ApplyFcn(hObject, eventdata, handles,funParams);


% --- Executes on key press with focus on pushbutton_done and none of its controls.
function pushbutton_done_KeyPressFcn(hObject, eventdata, handles)

if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end
