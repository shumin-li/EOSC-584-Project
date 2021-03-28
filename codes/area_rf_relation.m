function area_rf_relation(SPMGD, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function simply makes a figure showing the correlation of river
% discharge and plume area. with the option to save the figure or not
%
% - 'save'
%   - 'yes': save the figure into the current directory
%   - 'no' or other string: do not save the figure
%
% Shumin Li, March 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% plot the figure

varargin = {'save','no'};
if strcmpi(varargin{1}, 'save')
    sav_str = varargin{2};
end


figure('Position', [100 100 1200 400],'color','w')
plot(SPMGD.RF, SPMGD.area, 'bx')
ylim([0 2000]);

% make a consolidated data with the torarence of 200 and function of median
[xg, yg] = consolidator(SPMGD.RF, SPMGD.area, @median, 200);

% plot the group medians in red circle
hold on
plot(xg, yg,'linestyle','none','marker','o','color','r','linewi',2)

% add a linear fit curve
hold on
p = polyfit(xg, yg, 1);
f = polyval(p, xg);
plot(xg, f, '-','color','r','linewi',2);

% add legend
legend('Individual Data Points','binned medians',...
    'linear fitting curve')

% set axes parameters
xlim([min(SPMGD.RF) max(SPMGD.RF)])
ax = gca;
set(ax, 'FontSize',14,'FontWeight','bold','linewi',2)

% add xlabel, ylabel and titles
xlabel('River Flow (m^3/s)')
ylabel('Area (km^2)')
title('Correlation of Fraser River Discharge and Plume Area',...
    'FontSize',20,'Fontwei','bold')

% save the figure if input option 'save' gives 'yes'
if strcmpi(sav_str,'yes')
    save_dir = '/users/shuminli/Nextcloud/study_prjs/EOSC584_Project/';
    save_fname = 'area_rf_correlation';
    export_fig([save_dir, save_fname],'-png','-r400');
end

end