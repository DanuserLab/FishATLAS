function inside = countPixelsMultiCircle(maskImage, pointPattern, radius)


[H, W] = size(maskImage);
N = size(pointPattern,1);

% Coordinate grid
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
[X, Y] = meshgrid(1:W, 1:H);

% Reshape for broadcasting
X = reshape(X, H, W, 1);
Y = reshape(Y, H, W, 1);

xc = reshape(pointPattern(:,1), 1, 1, N);
yc = reshape(pointPattern(:,2), 1, 1, N);

% Circle masks for ALL centers at once (H x W x N)
circleMask = (X - xc).^2 + (Y - yc).^2 <= radius^2; % three-dimensional matrix 

% Expand mask
mask3 = reshape(maskImage, H, W, 1);

% Inside counts
insideOnes  = squeeze(sum(sum(circleMask & mask3, 1), 2));
insideTotal = squeeze(sum(sum(circleMask, 1), 2));
insideZeros = insideTotal - insideOnes;
insideRatio = insideOnes./insideTotal; 

% Output struct
inside.ones   = insideOnes;
inside.zeros  = insideZeros;
inside.total  = insideTotal;
inside.ratio  = insideRatio;
