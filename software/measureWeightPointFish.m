function [weight_points binaryImage binaryImage4Dots] = measureWeightPointFish(cancerImage,pointsCoord,binaryNThresh)
   % measureWeightPointFish calculates the area of binary image around each
   % point as the weight for that point. Some areas have no point so they
   % will be filterred out
    %normalize the image before thresholding
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
    binaryImage4Dots = zeros(size(cancerImage));
    %using multithreshold
    thresh = multithresh(cancerImage,binaryNThresh);

    binaryImage = cancerImage;
    binaryImage = single(cancerImage >= thresh(1)); 

    CC = bwconncomp(binaryImage);
    CC.PixelIdxList;
    
    pixelIdxLen = cellfun(@(x) length(x),CC.PixelIdxList ,'UniformOutput',false);
    pixelIdxLen = cell2mat(pixelIdxLen);
   
    ptCloudCoor = pointsCoord;
    weight_points = ones(size(ptCloudCoor,1),1); 
    % weight_points = ones(size(ptCloudCoor,1),1);  % this is better
    % because it keeps all points 
    
    %if a point is detected in the componnets, I will count the area as
    %weight
    for iCC = 1: length(CC.PixelIdxList)
        PXInd = CC.PixelIdxList{iCC};
        clear X IndPoint
        [X(:,1), X(:,2)] = ind2sub(size(cancerImage), PXInd);
        IndPoint = find(sum(ismember(ptCloudCoor,X),2) ==2); 
        if ~isempty(IndPoint)
          % only areas with dot  
            binaryImage4Dots(PXInd) = 1;
          GoodComponentID(iCC,1) = length(PXInd);
          weight_points(IndPoint) = length(PXInd)/length(IndPoint); 
         
        end
    end
end

