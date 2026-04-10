function [rigidCoord, nonRigidCoord] = transformPointsWithField (pointCoord, transform,DispField)
% transform the 2D point coordinate with the rigid (transform) map and
% displacement field for correspoinding point coordinate. It is usually
% from an image. For fishAtlas, it is from vasculature channel
%INPUT
% pointCoord    n*2 matrix representing coordinate of n point in (x,y)
% transform     tfrom2D from rigid registration DispField     displacement
% field from nonrigid registration
%OUTPUT
% rigidCoord,   n*2 matrix representing coordinate after applying rigid
%               transform
% nonRigidCoord n*2 matrix representing coordinate after applying nonrigid
%               displacement field
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


% apply rigid registration
[rigidCoord(:,1) , rigidCoord(:,2) ]= transformPointsForward(transform,pointCoord(:,1),pointCoord(:,2)) ;

% nonrigid transportation for points
SZ = size(DispField(:,:,1));

% find the index of coordinate in the DF matrix most times you need to
% round the coordinate for having the pixels,
transformed_Coordtmp_round = round(rigidCoord);

ind = sub2ind(SZ, transformed_Coordtmp_round(:,2),transformed_Coordtmp_round(:,1));
%extract dX and dY for each point from the DF matrix
DF_c = DispField(:,:,1); % for columns
DF_r = DispField(:,:,2); % for rows
%determine the shift for point Coord based on the pixel index
dC = DF_c(ind);
dR = DF_r(ind);
dDF = [dC, dR];

% nonRigidTransformed_Coordtmp2 = transformed_Coordtmp + dDF;
nonRigidCoord = rigidCoord - dDF; %after debuging imwarp for DispField
