function p = chordPlot(groups, connectionTable)
%%% Plot chord diagram
%%% Inputs:
%%%			groups - One dimensional vector or cell array containing group names to be plotted around the chord diagram
%%%			connectionTable -   An n-by-2, or n-by-3, or n-by-4 table where columns one and two contain the groups to be connected and the
%%%								third column are the weights for each connection, which are converted to line weights. The 4th
%%%                             column is the sign of the relationship, used for creating a gradient line between
%%%                             node.
%%%								If you want all lines to be of equal weight, turn
%%%								third column into a column of ones. If you want all lines to be solid color, 4th column
%%%                             into a column of zeros. Use array2table
%%%								or cell2table to convert arrays or cells to
%%%								tables
%%%
%%% Plot properties can be changed after plotting by for example doing:
%%% p.MarkerSize = 5;
%%% p.NodeFontSize = 12;
%%%
%%%
%%% Example plot:
% % % groups = 1:10;
% % % connections(:,1) = randi(10,50,1);
% % % connections(:,2) = randi(10,50,1);
% % % connections(:,3) = 2*rand(50,1);
% % % connections(:,4) = sign((rand(50,1) > 0.5) - 0.5);
% % % connectionsT = array2table(connections);
% % % chordPlot(groups,connectionsT)
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

t = sym('t');
x = cos(t);
y = sin(t);
figure, fplot(x,y, 'k');
axis equal
axis off
hold on

G = graph(groups, groups, 'omitselfloops');
p = plot(G, 'layout', 'circle', 'MarkerSize',5); % HMF
p.NodeColor = [0 0 0];
% set(gca, 'FontSize', 30); % HMF doesn't work
if width(connectionTable) == 2
    connectionTable(:,3) = table(ones(height(connectionTable),1));
end

if width(connectionTable) == 3
    connectionTable(:,4) = table(zeros(height(connectionTable),1));
end

if width(connectionTable) > 4
    error('The table has too many columns (min: 2, max: 4)')
end

for n = 1:height(connectionTable)
    if connectionTable{n,1} == connectionTable{n,2}
        continue
    end
    plotConnection(p,G,connectionTable{n,1},connectionTable{n,2}, connectionTable{n,3}, connectionTable{n,4}, [0 0.4470 0.7410]);
end

    function plotConnection(plotFig,graph, node1, node2, strength, lineDirection, linestyle)
        N1 = graph.findnode(node1);
        N2 = graph.findnode(node2);
        lineWidth = strength;
        style = 'makima';
        sample_n = 1000;
        curve = 0.9;
        x1 = [plotFig.XData(N1), ...
            curve*mean([plotFig.XData(N1), plotFig.XData(N2)]), plotFig.XData(N2)];
        
        y1 = [plotFig.YData(N1), ...
            curve*mean([plotFig.YData(N1), plotFig.YData(N2)]), plotFig.YData(N2)];
        
        xx = [linspace(x1(1),x1(2),sample_n/2), linspace(x1(2),x1(end),sample_n/2)];
        if abs(x1(1) - x1(end)) < abs(y1(1) - y1(end))
            y2 = x1;
            x1 = y1;
            y1 = y2;
            xx = [linspace(x1(1),x1(2),sample_n/2), linspace(x1(2),x1(end),sample_n/2)];
            yy = interp1(x1, y1, xx, style);
            if any(yy.^2 + xx.^2 > 1)
                xx = linspace(x1(1), x1(end) ,sample_n);
                yy = linspace(y1(1), y1(end),sample_n);
            end
            l_plot = plot(yy, xx, 'Color', linestyle, 'LineWidth', lineWidth);
            
            %     plot(y1, x1, 'kx')
        else
            [x1, uniqIdx, ~] = unique(x1);
            y1 = y1(uniqIdx);
            yy = interp1(x1, y1, xx, style);
            if any(yy.^2 + xx.^2 > 1)
                xx = linspace(x1(1), x1(end), sample_n);
                yy = linspace(y1(1), y1(end), sample_n);
            end
            l_plot = plot(xx, yy, 'Color', linestyle, 'LineWidth', lineWidth);
            %     plot(x1, y1, 'kx')
        end
        red = [1 0 0];
        green = [0 0.8 0];
        if lineDirection == 1 % HMF
            % cd = [uint8(linspace(green(1),red(1),length(xx))*255)', uint8(linspace(green(2),red(2),length(xx))*255)', uint8(linspace(green(3),red(3),length(xx))*255)', uint8(ones(length(xx),1))]';
            cd = [uint8(linspace(green(1),green(1),length(xx))*255)', uint8(linspace(green(2),green(2),length(xx))*255)', uint8(linspace(green(3),green(3),length(xx))*255)', uint8(ones(length(xx),1))]';
            drawnow
            set(l_plot.Edge, 'ColorBinding','interpolated', 'ColorData',cd)
        elseif lineDirection == -1
            % cd = [uint8(linspace(red(1),green(1),length(xx))*255)', uint8(linspace(red(2),green(2),length(xx))*255)', uint8(linspace(red(3),green(3),length(xx))*255)', uint8(ones(length(xx),1))]';
            cd = [uint8(linspace(red(1),red(1),length(xx))*255)', uint8(linspace(red(2),red(2),length(xx))*255)', uint8(linspace(red(3),red(3),length(xx))*255)', uint8(ones(length(xx),1))]';
            drawnow
            set(l_plot.Edge, 'ColorBinding','interpolated', 'ColorData',cd)
        end
    end
end

