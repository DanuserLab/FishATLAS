function  [regions_Coordinates, regions_FishID, regions_ROICorners,regions_PointArea] = computeRegionPointFeatures(pointPattern,fishID,pointArea,BinaryRefImage,boxSize,useBoundingFish)
% computeRegionPointFeatures defines the boxes and saved as a cell array
% the features within each box. The features include the coordinate & fish
% ID for each point
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

% if ~exist('boxSize','var')
%     boxSize = round(region_size/10);
% end

if ~exist('useBoundingFish', 'var')
    useBoundingFish = 1; % it creates a box grid around the fish, indepedence of the image size
end
padPercent = 15;  % in pixels, padding around the fish body to generate a box grid

% set the parameters
region_size = size(BinaryRefImage); % divide the whole refimage in pieces.
X_topCorner = [ 1 1 ]; 
dRow = region_size(1); % this can be improved 
dCol = region_size(2); 

%define regions (inputs, boxSize, imageSize, accumulation
if useBoundingFish
    %find the topleft corner for the bounding box
    [row col] = find(BinaryRefImage); 
    dRow = max(row(:)) - min(row);
    dCol =  max(col) - min(col); 
    % make an offset for finding the topleft corner for making grid on fish
    Offset = round( max(dRow,dCol) /padPercent);
    % find the topcorner but check whether offset is too much then consider
    % the image size 
    X_topCorner = [ max(min(col)-Offset, 1) max(min(row)-Offset, 1) ];
    dRow = dRow + 2*Offset;
    dCol = dCol + 2*Offset; 
end
if ~exist('boxSize','var')
    boxSize = round(region_size/10);
end


%define the grid of boxes from row to row
numRegion_row = ceil(dRow./boxSize(1)); % 1st element in the metric of image
numRegion_col = ceil(dCol./boxSize(2)); % 2nd element in the metric of image
n = 1; %count the number of region

for iRow = 1:numRegion_row
    for iCol = 1: numRegion_col

        %define the border of each region (topleft corner) and
        row_corner = (iRow - 1)*boxSize(1) +  X_topCorner(1);  %up down +1 is necessary for iRow = 1 when X_top is [0 0]
        col_corner = (iCol - 1)*boxSize(2) +  X_topCorner(2); %right left
        
        if row_corner >= X_topCorner(1) + dRow  || col_corner >=  X_topCorner(2) + dCol  
            continue
        end 

        % define regions of each box based on the pixels
        ROI_cornerstmp = [row_corner, min(row_corner+boxSize(1), region_size(1));...
            col_corner, min(col_corner+boxSize(2),region_size(2))];

        %make a matric of the box in the image (or for distribution) that
        %belongs to this region
        indCoord = find(pointPattern(:,2) >= ROI_cornerstmp(1) & pointPattern(:,2) < ROI_cornerstmp(3) & ...
            pointPattern(:,1) >= ROI_cornerstmp(2) & pointPattern(:,1) < ROI_cornerstmp(4)); % row relates to 2nd col of dist
        Coordtmp = pointPattern(indCoord,:);
        fishIDtmp = fishID(indCoord);
        pointAreatmp = pointArea(indCoord);
        regions_Coordinates {n,1} = Coordtmp;
        regions_FishID{n,1} = fishIDtmp;
        regions_ROICorners{n,1} = ROI_cornerstmp;
        regions_PointArea{n,1} = pointAreatmp;
        n = n+1;
    end

end
