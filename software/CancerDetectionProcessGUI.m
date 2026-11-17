function varargout = CancerDetectionProcessGUI(varargin)
%CANCERDETECTIONPROCESSGUI MATLAB code file for CancerDetectionProcessGUI.fig
%      CANCERDETECTIONPROCESSGUI, by itself, creates a new CANCERDETECTIONPROCESSGUI or raises the existing
%      singleton*.
%
%      H = CANCERDETECTIONPROCESSGUI returns the handle to a new CANCERDETECTIONPROCESSGUI or the handle to
%      the existing singleton*.
%
%      CANCERDETECTIONPROCESSGUI('Property','Value',...) creates a new CANCERDETECTIONPROCESSGUI using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to CancerDetectionProcessGUI_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      CANCERDETECTIONPROCESSGUI('CALLBACK') and CANCERDETECTIONPROCESSGUI('CALLBACK',hObject,...) call the
%      local function named CALLBACK in CANCERDETECTIONPROCESSGUI.M with the given input
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

% Edit the above text to modify the response to help CancerDetectionProcessGUI

% Last Modified by GUIDE v2.5 25-Aug-2026 14:37:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CancerDetectionProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @CancerDetectionProcessGUI_OutputFcn, ...
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


% --- Executes just before CancerDetectionProcessGUI is made visible.
function CancerDetectionProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:});

% Parameter setup
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
funParams = userData.crtProc.funParams_;


% set GUI with Parameters (this section is different for each GUI)
set(handles.edit_Sigma, 'String',num2str(funParams.Sigma))
set(handles.edit_Alpha, 'String',num2str(funParams.Alpha))
set(handles.edit_maxIntensityRateThresh, 'String',num2str(funParams.maxIntensityRateThresh))
set(handles.edit_weightNThresh, 'String',num2str(funParams.weightNThresh))


% Update user data and GUI data
handles.output = hObject;
set(handles.figure1, 'UserData', userData);
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = CancerDetectionProcessGUI_OutputFcn(hObject, eventdata, handles)
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

Sigma = str2double(get(handles.edit_Sigma, 'String'));
if isnan(Sigma) || Sigma <= 0
  errordlg('Please provide a valid input for ''Sigma''.','Setting Error','modal');
  return;
end

Alpha = str2double(get(handles.edit_Alpha, 'String'));
if isnan(Alpha) || Alpha <= 0 || Alpha > 1
  errordlg('Please provide a valid input for ''Alpha''.','Setting Error','modal');
  return;
end

maxIntensityRateThresh = str2double(get(handles.edit_maxIntensityRateThresh, 'String'));
if isnan(maxIntensityRateThresh) || maxIntensityRateThresh < 0 || maxIntensityRateThresh > 1
  errordlg('Please provide a valid input for ''Internsity Threshold''.','Setting Error','modal');
  return;
end

weightNThresh = str2double(get(handles.edit_weightNThresh, 'String'));
if isnan(weightNThresh) || weightNThresh < 1 || ~isequal(round(weightNThresh), weightNThresh)
  errordlg('Please provide a valid input for ''Cancer Threshold''.','Setting Error','modal');
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
funParams.Sigma = Sigma;
funParams.Alpha = Alpha;
funParams.maxIntensityRateThresh = maxIntensityRateThresh;
funParams.weightNThresh = weightNThresh;


% Set parameters and update main window
processGUI_ApplyFcn(hObject, eventdata, handles,funParams);


% --- Executes on key press with focus on pushbutton_done and none of its controls.
function pushbutton_done_KeyPressFcn(hObject, eventdata, handles)

if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end
