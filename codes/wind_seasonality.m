function wind_seasonality(sh,SPMGD,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function will make two figures of seasonality of wind type from Sand
% Heads (calm, northwesterly, southeasterly), one for all possible wind 
% data from 2003 to 2019, and the second only for the times when SPM images
% are taken among those years
%
% - 'save'
%   - 'yes': save the figure into the current directory
%   - 'no' or other string: do not save the figure
%
% Shumin Li, March 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% making plots
month_str_short = {'Jan','Feb','Mar','Apr','May','Jun',...
    'Jul','Aug','Sep','Oct','Nov','Dec'};

if strcmpi(varargin{1}, 'save')
    sav_str = varargin{2};
end

% k = 1: making the first figure of wind seasonality of all wind data
% k = 2: making the second figure of wind seasonality for only SPM data
for k = 1:2

    figure('Position', [100 100 1200 400],'color','w')
    
    % find the data indices for calm wind, northwesterly and southeasterly
    
    if k == 1
        time_idx = sh.wtime >= datenum(2003,1,1) & ...
            sh.wtime <= datenum(2019,12,31);
        w_time = sh.wtime(time_idx);
        w_spd = sh.wspd(time_idx);
        w_dir = sh.wdir(time_idx);
        
    elseif k == 2
        w_time = SPMGD.timeUTC;
        w_spd = SPMGD.wspd;
        w_dir = SPMGD.wdir;
        
    end
    
    calm_idx = w_spd < 4;
    strong_nw_idx = w_dir >= 270 & w_dir <= 360 & ~calm_idx;
    strong_se_idx = w_dir >= 90 & w_dir <= 180 & ~calm_idx;
    
    
    % get the month of each recorded data time
    [~, month, ~, ~ ,~,~] = datevec(w_time);
    time_month = datenum(0, month, 0);
    
    
    clear calm_n nw_n se_n
    
    % get the number of each type of wind in each month
    time_unique = unique(time_month);
    for i = 1:numel(time_unique)
        
        loop_idx = time_month == time_unique(i);
        calm_n(i) = sum (loop_idx & calm_idx);
        nw_n(i) = sum (loop_idx & strong_nw_idx);
        se_n(i) = sum (loop_idx & strong_se_idx);
        
    end
    
    % plot the lines with markers for each type of wind
    if k == 2
        plot(1:numel(time_unique), (calm_n + nw_n +se_n)/17,...
            'Marker','v',...
            'color','#0072BD','linesty','-','linewi',2,'MarkerSize',15)
        hold on
    end
    plot(1:numel(time_unique), calm_n/17,'Marker','o',...
        'color','#D95319','linesty','-','linewi',2,'MarkerSize',15)
    hold on
    plot(1:numel(time_unique), nw_n/17,'Marker','s',...
        'color','#EDB120','linesty','-','linewi',2,'MarkerSize',15)
    hold on
    plot(1:numel(time_unique), se_n/17,'Marker','^',...
        'color','#7E2F8E','linesty','-','linewi',2,'MarkerSize',15)
    
    % set the axis parameters
    xlim([0.5 12.5]);
    ax = gca;
    ax.XTick = (1:12);
    ax.XTickLabel = month_str_short;
    set(ax, 'FontSize',14,'FontWeight','bold','linewi',2)
    
    grid on
    
    
    % add labels, legends and titles
    if k == 1
        ylabel('Averaged Number of Data')
        legend('Calm (< 4 m/s)','Northwesterly','Southeasterly')
        title('Seasonality of Wind Types at Sand Heads from 2003 to 2019',...
            'FontSize',20,'FontWeight','bold')
        save_fname = 'wind_seasonality';
        
    elseif k == 2
        ylabel('Averaged Number of Images')
        legend('All Images','Calm (< 4 m/s)','Northwesterly','Southeasterly')
        title('Seasonality of Wind Types at Sand Heads for Selected SPM Images',...
            'FontSize',20,'FontWeight','bold')
        save_fname = 'wind_seasonality_spm';
    end

    if strcmpi(sav_str, 'yes')
        save_dir = '/users/shuminli/Nextcloud/study_prjs/EOSC584_Project/';
        export_fig([save_dir, save_fname],'-png','-r400');
    end
    
end

   
end