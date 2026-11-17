function  [regionMatrixCount Population PopulationNorm] = countInRegions(regionsCoord, regionsFishID,figureFlag)
%count the number of point for each point pattern in each region, and create
%the region matrix for population. 
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
if ~exist('figureFlag','var')
    figureFlag = 0; 
end 

nRegion = length(regionsCoord);
nFish = max(cell2mat(regionsFishID));

% calculate the regions that has nonzero population. it might be zero for
% one but not for other, so I might need to be inclusive for both!

Population = cellfun(@length, regionsCoord, 'UniformOutput', true);
PopulationNorm = Population/nFish; 
%find the nonzero regions
RegionID_nonzero = find(Population);

regionMatrixCount = nan(nRegion,nFish); 
% only scan through non-zero regions
for iRegion1 = 1:length(RegionID_nonzero)
      ROI_ID1 = RegionID_nonzero(iRegion1);

      X = zeros(nFish, 1);
        % recognize fish ID for these regions
        fishID_Region1 = regionsFishID{ROI_ID1};

        % recognize the coord for each region
        Coord_Region1 = regionsCoord{ROI_ID1};

        % fill elements in X,Y based on the fish ID
        fishList = unique(fishID_Region1); 
        for iFish = 1: length(fishList)
            Ind = find(fishID_Region1 == fishList(iFish));
            coordTmp = Coord_Region1(Ind,:);
            X(fishList(iFish)) = size(coordTmp,1);
        end
        % replace the number of points per fish in each region  
        regionMatrixCount (ROI_ID1,:) = X; 

        
end
if figureFlag
figure; 
heatmap(regionMatrixCount);
xlabel('Fish ID')
ylabel('Region ID')
title('Number of Site Per Region for Each Fish')


% visulaize non NaN regionMatrix
RegionMatrix_eff = regionMatrixCount; 
RegionMatrix_eff(isnan(RegionMatrix_eff)) = []; 
RegionMatrix_eff = reshape(RegionMatrix_eff, [length(RegionID_nonzero) nFish ]);

figure;
h = heatmap(RegionMatrix_eff);
h.YDisplayLabels = num2cell (RegionID_nonzero);
xlabel('Fish ID')
ylabel('Region ID')

title('Number of Site Per Region for Each Fish')
end 