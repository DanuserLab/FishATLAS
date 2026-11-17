function [RegionMatrix pvalueMatrix RegionID_nonzero] = regionCorrelation(regionsCoord, regionsFishID,typeCorr)

if ~exist('typeCorr','var')
    typeCorr = 'Kendall';
end 

nRegion = length(regionsCoord);
nFish = max(cell2mat(regionsFishID));

% find the nonzero region to save time
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
Population = cellfun(@length, regionsCoord, 'UniformOutput', true)';
RegionID_nonzero = find(Population);


%initialize the matrix
RegionMatrix = nan(nRegion); 
pvalueMatrix = nan(nRegion); 

% only scan through non-zero regions
for iRegion1 = 1:length(RegionID_nonzero)
    for iRegion2 = 1:length(RegionID_nonzero)
        ROI_ID1 = RegionID_nonzero(iRegion1);
        ROI_ID2 = RegionID_nonzero(iRegion2);
        % create the X, Y for each region based on the featType and fishID
        % initialize the
        X = zeros(nFish, 1);
        Y = zeros(nFish, 1);
        % recognize fish ID for these regions
        fishID_Region1 = regionsFishID{ROI_ID1};
        fishID_Region2 = regionsFishID{ROI_ID2};

        % recognize the coord for each region
        Coord_Region1 = regionsCoord{ROI_ID1};
        Coord_Region2 = regionsCoord{ROI_ID2};

        % fill elements in X,Y based on the fish ID
        fishList = unique(fishID_Region1); 
        for iFish = 1: length(fishList)
            Ind = find(fishID_Region1 == fishList(iFish));
            coordTmp = Coord_Region1(Ind,:);
            X(fishList(iFish)) = size(coordTmp,1);
        end
      
        fishList = unique(fishID_Region2); 
        for iFish = 1: length(fishList)
            Ind = find(fishID_Region2 == fishList(iFish));
            coordTmp = Coord_Region2(Ind,:);
            Y(fishList(iFish)) = size(coordTmp,1);
        end
       
        % now do the pearson correlation analysis for X, Y 
        switch typeCorr
            case 'Jaccard'
                bx = X ~= 0;
                by = Y ~= 0;
            	J = sum(bx & by) / sum(bx | by); % between zero and one
                RegionMatrix (ROI_ID1,ROI_ID2) = J;
                pvalueMatrix (ROI_ID1,ROI_ID2) = 1;
            otherwise
                % you may need to somehow exclude the
                % bx = X ~= 0;
                % by = Y ~= 0;
                % [phi pvalue ]= corr(double(bx)', double(by)','type',typeCorr);
                % cooccur_rate = sum(idx) / numel(x);

                [R pvalue] = corr(X,Y, 'type',typeCorr);
                RegionMatrix (ROI_ID1,ROI_ID2) = R;
                pvalueMatrix (ROI_ID1,ROI_ID2) = pvalue;
        end 
    end
end

