function varargout = AccumulationProcessGUI(varargin)
%ACCUMULATIONPROCESSGUI MATLAB code file for AccumulationProcessGUI.fig
%      ACCUMULATIONPROCESSGUI, by itself, creates a new ACCUMULATIONPROCESSGUI or raises the existing
%      singleton*.
%
%      H = ACCUMULATIONPROCESSGUI returns the handle to a new ACCUMULATIONPROCESSGUI or the handle to
%      the existing singleton*.
%
%      ACCUMULATIONPROCESSGUI('Property','Value',...) creates a new ACCUMULATIONPROCESSGUI using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to AccumulationProcessGUI_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      ACCUMULATIONPROCESSGUI('CALLBACK') and ACCUMULATIONPROCESSGUI('CALLBACK',hObject,...) call the
%      local function named CALLBACK in ACCUMULATIONPROCESSGUI.M with the given input
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

% Edit the above text to modify the response to help AccumulationProcessGUI

% Last Modified by GUIDE v2.5 26-Aug-2026 14:32:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AccumulationProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @AccumulationProcessGUI_OutputFcn, ...
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


% --- Executes just before AccumulationProcessGUI is made visible.
function AccumulationProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:});

% Parameter setup
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
funParams = userData.crtProc.funParams_;


% set GUI with Parameters (this section is different for each GUI)
set(handles.checkbox_usefishBodyImage,'Value',funParams.usefishBodyImage);
if funParams.usefishBodyImage
    set(get(handles.uipanel_usefishBodyImage,'Children'),'Enable','on');
else
    set(get(handles.uipanel_usefishBodyImage,'Children'),'Enable','off');
end

set(handles.edit_fishBodyImageDir, 'String', funParams.fishBodyImageDir)


% Update user data and GUI data
handles.output = hObject;
set(handles.figure1, 'UserData', userData);
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = AccumulationProcessGUI_OutputFcn(hObject, eventdata, handles)
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

usefishBodyImage = get(handles.checkbox_usefishBodyImage,'Value');
fishBodyImageDir = strtrim(get(handles.edit_fishBodyImageDir, 'String'));
if usefishBodyImage
    [~,~,fishBodyImageExt] = fileparts(fishBodyImageDir);
    isFullPath = ~isempty(regexp(fishBodyImageDir, '(^[A-Za-z]:[\\/])|(^[/\\]{2})|(^/)', 'once'));
    if isempty(fishBodyImageDir) || ~isFullPath || exist(fishBodyImageDir,'file') ~= 2 ...
            || ~ismember(lower(fishBodyImageExt), {'.tif', '.tiff'})
        errordlg('Please provide a valid full path to a binary TIFF fish body image.','Setting Error','modal');
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
funParams.usefishBodyImage = usefishBodyImage;
funParams.fishBodyImageDir = fishBodyImageDir;


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


% --- Executes on button press in pushbutton_fishBodyImageDir.
function pushbutton_fishBodyImageDir_Callback(hObject, eventdata, handles)

[filename, pathname] = uigetfile({'*.tif;*.tiff', 'TIFF Files (*.tif, *.tiff)'}, ...
    'Select a file of the fish body image');

if isequal(filename, 0)
    return;
end

set(handles.edit_fishBodyImageDir, 'String', fullfile(pathname, filename));
