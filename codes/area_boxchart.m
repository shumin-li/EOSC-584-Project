function area_boxchart(SPMGD,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function makes a nice boxchart plot of plume area variation
% according to seasonality or tidal cycle for the given options
%
% - 'option'
%   - 'season': plume area binned into a yearly cycle (default)
%   - 'tide': plume area binned into a tidal cycle
% - 'save'
%   - 'yes': save the figure into current directory
%   -  'no' or other string: don't save (default)
%
% Shumin Li, March 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Extrat option information from vargarin

k=1;
while k<=length(varargin)
    switch lower(varargin{k}(1:3))
        case 'opt'
            opt_str = varargin{k+1};
        case 'sav'
            sav_str = varargin{k+1};
    end
    k = k+2;
end


if ~any(opt_str)
    disp("default plotting option: 'season'")
    disp("to plot tidal cycle, add 'option','tide' ")
    opt_str = 'season';
end
   
if ~any(sav_str)
    disp("default: not saving the figure")
    disp("to save to plot, add 'save','yes' ")
    sav_str = 'no';
end

%% plot the seasonal variation of the plume area 

if strcmpi(opt_str,'season')
    
    % get the new time series with only the number of the day in the year
    [~,month,day,~,~,~] = datevec(SPMGD.timeUTC);
    time_day = datenum(0,month,day,0,0,0);
    
    % make the boxchart figure
    figure('Position',[100 100 1200 400],'color','w')
    boxchart(time_day,SPMGD.area,'BoxWidth',1)
    

    % set limits for x and y axes
    xlim([0 366])
    ylim([0 2000])
    
    % set the xticklabels to be month strings using function axdate
    axdate(12);
    ax = gca;
    ax.XTickLabel{1} = 'Jan';
    set(ax, 'FontSize',14,'FontWeight','bold','linewi',2)
    grid on
    
    % add the title and ylabels
    ylabel('Area (km^2)')
    title('Seasonal Variation of Fraser River Plume Area',...
        'FontSize',20,'Fontwei','bold')
    
    % save the figure if sav_str is 'yes';
    if strcmpi(sav_str, 'yes')
        save_dir = '/users/shuminli/Nextcloud/study_prjs/EOSC584_Project/';
        save_fname = 'area_seasonality';
        export_fig([save_dir, save_fname],'-png','-r400');
    end
    
end

%% area boxchart in a tidal cycle
% similar to the boxchart for the seasonal variation above

if strcmpi(opt_str,'tide')
    
    figure('Position',[100 100 1200 400],'color','w')
    
    % devide tide lag minutes into 10-minute groups
    lag_new = round(SPMGD.lag_min * 10)/10;
    
    % making the boxchart and set y axis limits
    boxchart(lag_new, SPMGD.area,'boxwidth',0.1)
    ylim([0 2000])
    
    % find the meadian values for every 30 minutes in the tidal cycle, and
    % plot them as red circles
    [xg, yg] = consolidator(SPMGD.lag_min, SPMGD.area, @median, 0.5);
    hold on
    plot(xg, yg,'linestyle','none','marker','o','color','r','linewi',2)
    
    % calculate a polynomial fit of the red circles and plot it onto the
    % boxchart
    hold on
    p = polyfit(xg,yg,6);
    
    % if we want a more tide-like fit (starting point and ending point at
    % almost the same elevation, then we can copy some data at the end of
    % the cycle and put it before the beginning of the cycle, and vise
    % versa to add beging part of data on to the end.
    %
    %     p = polyfit(cat(1,xg(end-5:end)- 25.36,xg,xg(1:5) + 25.36), ...
    %         cat(1,yg(end-5:end),yg,yg(1:5)), 6);
    
    f = polyval(p, xg);
    plot(xg, f, '-','color','r','linewi',2);
    
    % add legend
    legend('6-minute binned Boxchart','30-minutes binned median',...
        'polynomial curve fitting')
    
    % set axis parameters, add labels and titles
    xlim([-7.6 17.7])
    ax = gca;
    ax.XTick = linspace(-6,16,12);
    set(ax, 'FontSize',14,'FontWeight','bold','linewi',2)    
    ylabel('Area (km^2)')
    xlabel('Tide Lag Hours')
    title('Tidal Variation of Fraser River Plume Area',...
        'FontSize',20,'Fontwei','bold')
    
    % save the figure if sav_str is 'yes';
    if strcmpi(sav_str, 'yes')
        save_dir = '/users/shuminli/Nextcloud/study_prjs/EOSC584_Project/';
        save_fname = 'area_tidal';
        export_fig([save_dir, save_fname],'-png','-r400');
    end
    
end
end