function river_seasonality(fraser,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function makes a plot of fraser river discharge seasonality from
% 2003 to 2019, and a mean river flow pattern was plot above all individual
% year line
%
% - 'save'
%   - 'yes': save the figure into the current directory
%   - 'no' or other string: do not save the figure
%
% Shumin Li, March 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmpi(varargin{1}, 'save')
    sav_str = varargin{2};
end

% start making the plot
figure('Position', [100 100 1200 400],'color','w')

% Getting the year, month and day values of the river flow data
time_idx = fraser.mtime >= datenum(2003,1,1) & ...
    fraser.mtime <= datenum(2019,12,31);
rf_time = fraser.mtime(time_idx);
rf_flow = fraser.flow(time_idx);
[year, month, day,~,~,~] = datevec(rf_time);

% make a matrix to store all river flow data from 2003 to 2019 
year_unique = unique(year);
rf_all = nan(numel(year_unique),365);
for i = 1: numel(year_unique)
    
    year_idx = year == year_unique(i);
    time_fake = datenum(0,month(year_idx), day(year_idx));
    year_flow = rf_flow(year_idx);
    
    plot(time_fake, year_flow)
    hold on
    
    rf_all(i,:) = year_flow(1:365);
    legend_str{i} = num2str(year_unique(i));
end

%% put the mean river flow pattern in a year

hold on
plot(1:365, nanmean(rf_all,1),'linewi',3,'color','k');

% set axis parameters
xlim([1 365]);
axdate(12);
ax = gca;
ax.XTickLabel{1} = 'Jan';
set(ax, 'FontSize',14,'FontWeight','bold','linewi',2)

% add the legend
legend_str{numel(year_unique)+1} = 'mean';
legend(legend_str,'Location','northeast','NumColumns',2)

grid on

% add ylabel and titles
ylabel('River Flow (m^3/s)')
title('Fraser River Discharge from 2003 to 2019',...
    'FontSize',20,'Fontwei','bold')

% save the figure if option of 'save' given as 'yes'
if strcmp(sav_str, 'yes')
    save_dir = '/users/shuminli/Nextcloud/study_prjs/EOSC584_Project/';
    save_fname = 'river_seasonality';
    export_fig([save_dir, save_fname],'-png','-r400');
end

end