function [NN_idx NN_dist img_clipped img] = computeNNMetric(pointPattern1,pointPattern2,varargin)
% compute_nn_metric computes nearest neighbor diatnce between two point
% patterns
%INPUT
% pointPattern1 
% pointPattern2 
% NN_number         
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

% Parse inputs
ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('pointPattern1', @isnumeric);
ip.addRequired('pointPattern2', @isnumeric);
ip.addParamValue('Metric', 'NN_num', @ischar);
ip.addParamValue('NN_number', 2,@isscalar);
ip.addParamValue('prctileCuttoff', 99, @isscalar);
ip.addParamValue('Sigma', 3, @isscalar);
ip.addParamValue('Radius', 40,@isscalar); % in pixel. It could be variable based on biological questions
ip.addParamValue('figureFlag', 0,@isscalar);
ip.addParamValue('edgeCorr', 1,@isscalar);
ip.addParamValue('image_size', [],@isnumeric);

ip.KeepUnmatched = true;
ip.parse(pointPattern1,pointPattern2, varargin{:});
Metric = ip.Results.Metric;
NN_number = ip.Results.NN_number;
prctileCuttoff = ip.Results.prctileCuttoff;
Sigma = ip.Results.Sigma;
Radius = ip.Results.Radius;
figureFlag = ip.Results.figureFlag;
image_size = ip.Results.image_size;


% add the gaussian kernel based on Sigma --> heatmap
switch Metric
    case 'Dist'
        [NN_idx, NN_dist] = knnsearch(pointPattern2, pointPattern1, 'K', NN_number);
        img = test_weighted_gaussian_filter(pointPattern1,  mean(NN_dist(:,2:end),2), image_size, Sigma);
        clip_val = prctile(img(:), prctileCuttoff);  % 99th percentile
        img_clipped = min(img, clip_val);
        if figureFlag
            imagesc(img_clipped); colormap hot; axis image; title(['Gaussian Smoothed Points for ' Metric ' - Sigma = ' num2str(Sigma)]);
            set(gcf, 'Position',[50 50 image_size(2) image_size(1)])
        end
        % % add the gaussian kernel based on Sigma --> heatmap img =
        % test_weighted_gaussian_filter(pointPattern1,
        % mean(NN_dist(:,2:end),2), image_size, pointArea); figure;
        % imagesc(img); colormap hot; axis image; title('Weighted Gaussian
        % Smoothed Points');
    case 'invDist'
        [NN_idx, NN_dist] = knnsearch(pointPattern2, pointPattern1, 'K', NN_number);
        score = 1./mean(NN_dist(:,2:end),2); % exclude self distance
        %remove zero distance or inf score
        ind = find(score ==Inf);
        score(ind ) = [];
        %update the coordinate
        pointPattern1_update = pointPattern1;
        pointPattern1_update(ind,:) = [];
        img = test_weighted_gaussian_filter(pointPattern1_update, score, image_size, Sigma);
        clip_val = prctile(img(:), prctileCuttoff);  % 99 percentile
        img_clipped = min(img, clip_val);
        if figureFlag
            imagesc(img_clipped); colormap hot; axis image; title(['Gaussian Smoothed Points for ' Metric ' - Sigma = ' num2str(Sigma)]);
            set(gcf, 'Position',[50 50 image_size(2) image_size(1)])
        end
    case 'NN_num'
        [NN_idx NN_dist]= KDTreeBallQuery(pointPattern2, pointPattern1, Radius);
        score = cellfun(@length, NN_idx) - 1;
        img = test_weighted_gaussian_filter(pointPattern1, score, image_size, Sigma);
             clip_val = prctile(img(:), prctileCuttoff);  % 99 percentile
             img_clipped = min(img, clip_val);
     
           
        if figureFlag
              imagesc(img_clipped); colormap hot; axis image; title(['Gaussian Smoothed Points for ' Metric ' - Sigma = ' num2str(Sigma)]);
            set(gcf, 'Position',[50 50 image_size(2) image_size(1)])
        end
        % if edgeCorr == 1
        %     % for each point, calculate the ratio of the area around each
        %     % points 
        %     % round points
        %    inside = countPixelsMultiCircle(MaskImg, pointPattern1, Radius)
        %    inside.ratio = NN_idx 
        % end 
    otherwise
        error('Choose the visualization metric')
end
