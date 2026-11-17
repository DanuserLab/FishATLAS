function [markerCoord, markedImage] = genLandmarkImage(Image2D, nMark, radius)

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

if ~exist('nMark','var')
    nMark = 10;
end

if ~exist('radius','var')
    radius = 5;
end

satisfied = 0;

while ~satisfied

    hFig = figure;
    imshow(255 - Image2D, [0 300]);
    % imshow(255 - Image2D);
    % imshow(Image2D);
    set(hFig,'Position',[120 120 1500 600]);
    [xClick, yClick] = ginput(nMark);
    markerCoord = [xClick yClick];
    hold on
    plot(markerCoord(:,1) ,markerCoord(:,2),'r.','MarkerSize',15);

    nSelectedMarks = size(markerCoord,1);
    if nSelectedMarks ~= nMark
        uiwait(errordlg(['Selected ' num2str(nSelectedMarks) ' points, but ' num2str(nMark) ...
            ' points are required. Please re-click all points.'], 'Incorrect Number of Points'));
        if ishandle(hFig)
            close(hFig);
        end
        markerCoord = [];
        continue;
    end

    choice = questdlg('Are the selected points OK?', ...
        'Confirm Points', ...
        'Yes','Redo','Cancel','Yes');
    if ishandle(hFig)
        close(hFig);
    end

    markerCoordtmp = cat(2,round(markerCoord), radius * ones(nMark,1));
    markedImage = insertShape(Image2D, "filled-circle",markerCoordtmp, 'Color','red');

    if strcmp(choice, 'Yes')
        satisfied = 1;
    elseif strcmp(choice, 'Cancel')
        markerCoord = []; % user quit without saving
        break;
    end 
end 
