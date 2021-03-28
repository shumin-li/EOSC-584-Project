function plume_subplots(sandheads, gridLon, gridLat, river_dir, ...
    coast_dir, bx, SPMGD, COD, fraser, sh,  varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This fuction makes a figure with subplots of Fraser River plume patterns
% or HF radar derived surface currents with the following input and options
%
% Options:
% - 'option'
%   - 'spm': making plots of plume pattern based MODIS derived SPM Images
%   - 'codar': making plots of HF radar derived surface currents
%
% - 'type'
%   - 'season': devide into each month and make a 4*3 subplot
%   - 'wind_rf': devide into different wind (northwesterly, calm and
%   southeasterly) and river discharge (low, medium and high) conditions,
%   and make a 3*3 subplot
%   - 'tide': devide into tide lag hours relative to the lower low tide of
%   the day. 5*5 subplots
%
% - 'save_fig'
%   - 'yes': export the figure into the project directory
%   - (and other string): do not save the figure
%
% Other input variables in order:
% - sandheads: locations of Sand Heads lighthouse, which indicates the
% river channel outreach.
% - gridLon/gridLat: longitude and latitude grids of SPM images
% - river_dir: data directory for a fine-scale river coastlines information
% - coast_dir: directory for fine-scale BC coastline
% - bx: box size used in m_proj function
% - SPMGD: data struct of selected good SPM images, for more information
% see the annotation in project_dataload fuction
% - COD: data struct for HF radar surface currents
% - fraser: daily fraser river discharge
% - sh: data struct for wind records from Sand Heads lighthouse station
%
% Shumin Li, 2021 March
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% initialize the data and prarameters

varargin = {'option','codar_at_spm','type','wind_rf','save_fig','no'};

% extract the option inputs from varargin (variable argument input)
k=1;
while k<=length(varargin)
    switch lower(varargin{k}(1:3))
        case 'opt'
            opt_str = varargin{k+1};
        case 'typ'
            typ_str = varargin{k+1};
        case 'sav'
            save_str = varargin{k+1};
    end
    k = k+2;
end


% since there are only two legal oprtions (spm / codar), we can call
% opt_bool as option boolean value. if opt_bool = true, plot the figure of
% spm image, otherwize, plot surface currents. report error for illegal
% input
if strcmpi(opt_str, 'spm')
    opt_bool = true;
elseif strcmpi(opt_str(1:5), 'codar')
    opt_bool = false;
else
    error("'option' has to be either 'spm' or 'codar' ")
end


% report error for illegal 'type' input
if ~ any(strcmpi(typ_str,{'season','wind_rf','tide'}))
    error("'type' has to be either 'season', 'wind_rf' or 'tide'")
end


% assign different initial values for spm plots and codar plots
if opt_bool
    % color of the plume boundary contour (SPM = 2g/m^3)
    contour_col = 'k';
    % string in the big title above all subplots, part 1
    sg_title_1 = 'Fraser River Plume Patterns';
    % string as the filename for saving the fiugre, part 1
    save_str_1 = 'spm';
    % margin width of the subplots, (leave some extra space on the righ to
    % put the colorbar.
    marg_w = [0.06 0.1]; 
else
    contour_col = 'k';
    marg_w = [0.08 0.08];
    
    switch opt_str
        case 'codar'
            sg_title_1 = 'Mean HF Radar Surface Currents';
            save_str_1 = 'codar';
            
            codar_wu = nan(size(COD.mtime));
            codar_wv = nan(size(COD.mtime));
            
            for  k = 1:numel(COD.mtime)
                [sh_idx1, sh_idx2] = min(abs(sh.wtime - COD.mtime(k)));
                
                if sh_idx1 < 1/24
                    codar_wu(k) = sh.wu(sh_idx2);
                    codar_wv(k) = sh.wv(sh_idx2);
                end
                
            end
            
        case 'codar_at_spm'
            
            sg_title_1 = 'Mean HF Radar Surface Currents (t = SPM)';
            save_str_1 = 'codar_at_spm';
            
            codar_wu = nan(size(COD.mtime));
            codar_wv = nan(size(COD.mtime));
            codar_at_spm_idx = false(size(COD.mtime));
            
            for k = 1:numel(COD.mtime)
                [spm_idx1, spm_idx2] = min(abs(SPMGD.timeUTC - COD.mtime(k)));
                
                better_index = SPMGD.percent_valid > 0.4 & SPMGD.center_valid > 0.5;

                if spm_idx1 < 1/24 && better_index(spm_idx2)
                codar_at_spm_idx(k) = true;
                codar_wu(k) = SPMGD.wspd(spm_idx2)*cosd(SPMGD.wdir(spm_idx2));
                codar_wv(k) = SPMGD.wspd(spm_idx2)*sind(SPMGD.wdir(spm_idx2));
                end
                
            end
            
    end
    
end



% assign variables for each type of the plot
switch typ_str
    
    % subplots in each month
    case 'season'
        % legend_idx: which subplot to put the legend (length/vector scale)
        legend_idx = 6;
        % save_str_2: part 2 of the filename string
        save_str_2 = '_by_month';
        % fig_pos: position of the figure
        fig_pos = [100 100 630 900];
        % row: number of rows of the subplots
        row = 4;
        % col: number of columns of the subplots
        col = 3;
        % gap: [gap_h gap_w] gaps in height and width between subplots
        gap = [0.01 0];
        % marg_h: [lower upper] lower and upper margins for subplots
        marg_h = [0.05 0.09];
        % sg_title_2: part 2 of the string in the sg_title
        sg_title_2 = ' in Each Month';
        % sgt_FS: sg_title FrontSize
        sgt_FS = 18;
        % cbar_pos: colorbar position
        cbar_pos = [0.91 0.048 0.025 0.863];
        % cod_thr: surface currents threshold, above which arrows are not
        % shown
        cod_thr = 30;
        % vec_scale: scale factor of m_vec funtion to plot arrows
        vec_scale = 250;
        % cod_gap: every 3 data points in row and colum of the data grid is
        % shown
        cod_gap = 2;
        % ruler_y: the Y Position of the m_rule, which indicates the length
        % scale in the subplot No. legend_idx
        ruler_y = 0.76;
        % ruler_FS: FontSize of the ruler above
        ruler_FS = 10;
        % vec_leg_FS: arrow length scale FontSize in the subplot No.
        % legend_idx
        vec_leg_FS = 10;
        
        wind_legend_idx = 3;
        wind_leg_FS = 12;
        
        if opt_bool
            wvec_scale = 5;
            wvec_hl = 6;
            wvec_sw = 1;
            
        else
            wvec_scale = 12;
            wvec_hl = 2;
            wvec_sw = 0.4;
        end
        
        
    
    % subplots in different wind and river flow conditions    
    case 'wind_rf'
        legend_idx = 6;
        save_str_2 = '_by_wind_rf';
        fig_pos = [100 100 800 800];
        row = 3;
        col = 3;
        gap = [0.005 0.005];
        marg_h = [0.05 0.105];
        sg_title_2 = ' under Various Wind and RF Conditions';
        sgt_FS = 20;
        cbar_pos = [0.91 0.048 0.025 0.846];
        cod_thr = 50;
        vec_scale = 400;
        cod_gap = 2;
        ruler_y = 0.76;
        ruler_FS = 10;
        vec_leg_FS = 10;
        
        wind_legend_idx = 3;
        wind_leg_FS = 12;
        
        if opt_bool
            wvec_scale = 5;
            wvec_hl = 6;
            wvec_sw = 1;
            
        else
            wvec_scale = 12;
            wvec_hl = 2;
            wvec_sw = 0.4;
        end
        
        
        % Some specific data index calculation for type 'wind_rf'
        %
        % Finding the SPM indices of calm wind (< 4 m/s), strong
        % northwesterlies, and strong southeasterlies
        w_spd = SPMGD.wspd;
        w_dir = SPMGD.wdir;
        
        calm_idx = w_spd < 4;
        strong_nw_idx = w_dir >= 270 & w_dir <= 360 & ~calm_idx;
        strong_se_idx = w_dir >= 90 & w_dir <= 180 & ~calm_idx;
        
        % Finding the SPM indices of calm low river flow (< 3000 m^3/s),
        % median river flow (3000 < SPMGD.RF < 5000), and high river flow
        rf_low = SPMGD.RF < 3000;
        rf_med = SPMGD.RF >= 3000 & SPMGD.RF <= 5000;
        rf_high = SPMGD.RF > 5000;
        
        % cell of the indices for wind and river conditions
        wind_idx = {strong_nw_idx, calm_idx, strong_se_idx};
        river_idx = {rf_low, rf_med, rf_high};
        
        % if option is codar, then we need data indices for COD
        if ~opt_bool
            cod_rf_low(size(COD.mtime)) = false;
            cod_rf_med(size(COD.mtime)) = false;
            cod_rf_high(size(COD.mtime)) = false;
            
            cod_sh_calm(size(COD.mtime)) = false;
            cod_sh_nw(size(COD.mtime)) = false;
            cod_sh_se(size(COD.mtime)) = false;
            
            
            for k = 1: numel(COD.mtime)
                % finding the indices of difference river flow conditions 
                % of COD data
                [fraser_idx1, fraser_idx2] = ...
                    min(abs(fraser.mtime - COD.mtime(k)));
                
                if fraser_idx1 < 1
                    if fraser.flow(fraser_idx2) < 3000
                        cod_rf_low(k) = true;
                    elseif fraser.flow(fraser_idx2) >= 3000 && ...
                            fraser.flow(fraser_idx2) <= 5000
                        cod_rf_med(k) = true;
                    else
                        cod_rf_high(k) = true;
                    end
                end
                
                % finding the indices of difference wind conditions of
                % COD data
                [sh_idx1, sh_idx2] = min(abs(sh.wtime - COD.mtime(k)));
                
                if sh_idx1 < 1/24
                    if sh.wspd(sh_idx2) < 4
                        cod_sh_calm(k) = true;
                    elseif sh.wspd(sh_idx2) >= 4 && ...
                            sh.wdir(sh_idx2) >= 270 && ...
                            sh.wdir(sh_idx2) <= 360
                        cod_sh_nw(k) = true;
                    elseif sh.wspd(sh_idx2) >= 4 && ...
                            sh.wdir(sh_idx2) >= 90 && ...
                            sh.wdir(sh_idx2) <= 180
                        cod_sh_se(k) = true;
                    end
                end
            end
            
            cod_rf_idx = {cod_rf_low, cod_rf_med, cod_rf_high};
            cod_sh_idx = {cod_sh_nw, cod_sh_calm, cod_sh_se};
            
        end
        
        % strings used for xlabels and ylabels
        wind_str = {'Northwesterly','Calm Wind','Southeasterly'};
        river_str = {'Low RF','Medium RF', 'High RF'};
        
        % indices used later in the loop to tell which data indices should
        % a subplot draw
        rf_loop = [1 1 1 2 2 2 3 3 3];
        wind_loop = [1 2 3 1 2 3 1 2 3];
        
        
        
    % subplots under a tidal cycle    
    case 'tide'
        legend_idx = 15;
        save_str_2 = '_by_tide';
        fig_pos = [100 100 650 600];
        row = 5;
        col = 5;
        gap = [0.005 0.005];
        marg_h = [0.05 0.09];
        sg_title_2 = ' over a Tidal Cycle';
        sgt_FS = 20;
        cbar_pos = [0.91 0.048 0.025 0.863];
        cod_thr = 50;
        vec_scale = 500;
        cod_gap = 3;
        ruler_y = 0.86;
        ruler_FS = 7;
        vec_leg_FS = 7;
        
        wind_legend_idx = 10;
        wind_leg_FS = 9;
        
        if opt_bool
            wvec_scale = 6;
            wvec_hl = 5;
            wvec_sw = 1;
            
        else
            wvec_scale = 15;
            wvec_hl = 2;
            wvec_sw = 0.4;
        end
        
        
        % Here is the function for generating tide lag hours of each
        % recorded HF radar time. it took about 6 seconds to calculate. So
        % here, in order to save time, we will save the data in advance and
        % use it when we need it. (tide_hrs is a function I wrote, it will
        % be fully explained somewhere else in the documents, and t_xtide
        % was from t_tide toolbox)
        %    |
        %    |
        %    v
        %
        %     tidet = COD.mtime(1)-2:1/24:COD.mtime(end)+2;
        %     tideh = t_xtide('Point Atkinson (2)',tidet - 8/24);
        % for k = 1: numel(COD.mtime)
        %     [m, l, ~,~] = ...
        %         tide_hrs(tideh, tidet - 8/24, COD.mtime(k) - 8/24, 'no');
        %     cod_tide_l(k) = l;
        %     cod_tide_min(k) = m;
        %
        % end
        % save('/Users/shuminli/Nextcloud/study_prjs/EOSC584_Project/cod_lag_data.mat',...
        %             'cod_tide_l','cod_tide_min')
        
        load('/Users/shuminli/Nextcloud/study_prjs/EOSC584_Project/cod_lag_data.mat')
        
        
end

month_str_short = {'Jan','Feb','Mar','Apr','May','Jun',...
    'Jul','Aug','Sep','Oct','Nov','Dec'};


%% start making the plot

clf

vec_color = m_colmap('jet',6);
vec_step = round(linspace(0, cod_thr, 6));

% initialize figure size, subplot numbers and margins, and m_map projections
% f = figure('color','w','Position',fig_pos);
ha = tight_subplot(row,col,gap,marg_h,marg_w);
m_proj('lambert','lon',bx(1:2),'lat',bx(3:4));

% Loop for row*col subplots
for i = 1:row*col
    
    % making data idx (finding the indices to average the spm image or
    % codar surface currents)
    
    % better_index is trying to find the images with over 40% coverage in
    % the Strait of Georgia and over 50% valid data in the plume region.
    % (to some degree, this is a simple quality control index)
    better_index = SPMGD.percent_valid > 0.4 & SPMGD.center_valid > 0.5;
    
    
    switch typ_str
        
        case 'season'
            % finding the month for each spm image time
            [~,spm_month,~,~,~,~] = datevec(SPMGD.timePDT);
            % find the indices of the month in looping (i.e. i)
            month_idx = spm_month == i;
            
            % put the above two indices together
            data_idx =  month_idx & better_index;
            
            % finding the data indices for codar data
            [~,cod_month,~,~,~,~] = datevec(COD.mtime);
            cod_idx = cod_month == i;
            
        case 'wind_rf'
            % finding the indices for corresponded wind and river flow
            % conditions
            data_idx =  river_idx{rf_loop(i)} & ...
                wind_idx{wind_loop(i)} & better_index;
            if ~opt_bool
                cod_idx =  cod_rf_idx{rf_loop(i)} & cod_sh_idx{wind_loop(i)};
            end
            
        case 'tide'
            
            % tide_idx and cod_tide_idx are trying to filter out the days 
            % of weak tidal variations (if the lower low tide of the day is
            % even higher than 2.1 m in Pt. Atkinson, there we would
            % consider that day does not have a "big ebb")
            tide_idx = SPMGD.LowTide < 2.1;
            cod_tide_idx = cod_tide_l < 2.1;
            
            % find the images which are taken +/- 1 hour within the given 
            % tide lag hour
            j = i - 8;
            lag_2h =  SPMGD.lag_min > j-1 & SPMGD.lag_min < j+1;
            cod_lag_2h = cod_tide_min > j-1 & cod_tide_min < j+1;
            
            % Count tide lag hours from 17h to 18h into "-7h" segment,
            % and also count the -8h to -7h period as part of "17h" segment
            if j == -7
                lag_2h =  SPMGD.lag_min > 17 | SPMGD.lag_min < -6;
                cod_lag_2h = cod_tide_min > 17 | cod_tide_min < -6;
            elseif j == 17
                lag_2h =  SPMGD.lag_min > 16 | SPMGD.lag_min < -7;
                cod_lag_2h =  cod_tide_min > 16 | cod_tide_min < -7;
                
            end
            
            % put the earlier creterion together
            data_idx =  lag_2h & better_index & tide_idx;
            cod_idx = cod_lag_2h & cod_tide_idx;
            
    end
    
    if strcmpi(opt_str,'codar_at_spm')
        if size(cod_idx,1) == size(codar_at_spm_idx,1)
            cod_idx = cod_idx & codar_at_spm_idx;
        elseif size(cod_idx,1) == size(codar_at_spm_idx,2)
            cod_idx = cod_idx & codar_at_spm_idx';
        end
    end
    

    % extract zonal and meridional velocity vectors of given indices
    spm_u = COD.u(:,:,cod_idx);
    spm_v = COD.v(:,:,cod_idx);
    
    % calculate the mean value of each component
    u_data = nanmean(spm_u,3);
    v_data = nanmean(spm_v,3);
    
    % eliminate the outliers (speed greater than the threshold -- cod_thr)
    cod_spd = sqrt(u_data.^2 + v_data.^2);
    u_data(cod_spd > cod_thr) = nan;
    v_data(cod_spd > cod_thr) = nan;
    
    
    % find the pixel medians for images of the data indices
    spm_median = nanmedian(SPMGD.val(:,:,data_idx),3);
    
    % apply a 2-D median filter with 5x5 window size to make the plot look
    % smoother while maintaining the plume boundary correctly
    spm_data = medfilt2(spm_median,[5,5]);
    
    
    % get into each subplot within the loop
    axes(ha(i));
    

    if opt_bool
        
        % plot the spm data with log colorscale using m_pcolor and a m_jet 
        % colormap with 15 'step'
        m_pcolor(gridLon, gridLat, spm_data);
        caxis([0.1,30]);
        colormap(m_colmap('jet','step',15));
        set(gca,'colorscale','log');
        
        
    end
    
    % adding coastline and river coast
    m_usercoast(coast_dir,'patch',[.7 .7 .7],'edgecolor','none');
    m_usercoast(river_dir,'patch',[.7 .7 .7],'edgecolor','none');
    
    % add the contour of SPM = 2 g/m^3
    hold on
    v = [2, 2];
    m_contour(gridLon, gridLat,spm_data,v,'color',contour_col,'linewi',1.5);
    
    
    
     % calculate the number of images/currents used in this subplot, and
    % transfer it from number into string, for the use of next step
    if opt_bool
        str_n = num2str(sum(data_idx));
    else
        str_n = num2str(size(spm_u,3));
    end
    
    
    switch typ_str
        case 'season'
            % put the month string onto the upper left corner
            m_text(-123.85, 49.32, month_str_short{i},'FontSize',12,...
                'FontWeight','bold','edgecolor','none','backgroundcolor','w');
            
            % adding a text box at the lower left corner showing how many
            % images/currents data are used in this subplot (str_n)
            m_text(-123.85, 48.86,['n = ',str_n],'FontSize',12,...
                'FontWeight','bold','edgecolor','none','backgroundcolor','w');
            
        case 'wind_rf'
            % adding a text box at the lower left corner showing how many
            % images/currents data are used in this subplot (str_n)
            m_text(-123.85, 48.86,['n = ',str_n],'FontSize',12,...
                'FontWeight','bold','edgecolor','none','backgroundcolor','w');
            
        case 'tide'
            if opt_bool
                % put tide lag hour onto upper left of each subplot for spm
                % plot
                m_text(-123.85, 49.33, ['h = ', num2str(i-8)],...
                    'FontSize',9,'FontWeight','bold',...
                    'edgecolor','none','backgroundcolor','w');
            else
                % same number but different locations for codar plot
                m_text(-123.15, 49.33, ['h = ', num2str(i-8)],...
                    'FontSize',9,'FontWeight','bold',...
                    'edgecolor','none','backgroundcolor','w');
            end
            
            % put a text about the number of used data at lower left corner
            m_text(-123.85, 48.86,['n = ',str_n],'FontSize',...
                9,'FontWeight','bold',...
                'edgecolor','none','backgroundcolor','w');
    end
    
    
    
    
    
    
    if opt_bool
        % if plotting spm image, put a length scale using m_ruler onto 
        % subplot in the middle right (No. legend_idx)
        if i == legend_idx
            m_ruler([0.69, 0.97],ruler_y,'FontSize',ruler_FS);
        end
        
    else
        
        lon = COD.lon(1:cod_gap:end, 1:cod_gap:end);
        lat = COD.lat(1:cod_gap:end, 1:cod_gap:end);
        u = u_data(1:cod_gap:end, 1:cod_gap:end);
        v = v_data(1:cod_gap:end, 1:cod_gap:end);
        spd = sqrt(u.^2 + v.^2);
            
        for j = 1:numel(vec_step)-1
            uv_idx = spd > vec_step(j) & spd <= vec_step(j+1);
        
        % if plotting codar currents, then plot the arrows with appropriate
        % vec_scale and cod_gap
        m_vec(vec_scale,lon(uv_idx),lat(uv_idx),...
            u(uv_idx),v(uv_idx), vec_color(j,:),'headlength',1,...
            'shaftwidth',0.2,'headangle',40);
        
        % put a vector length scale (how big arrow does 20 cm/s represent)
        % on the middle right subplot (No. legend_idx)
        end
        
        if i == legend_idx
            
            bndry_lon=[-123.16 -123.16 -122.92 -122.92 -123.16];
            bndry_lat=[49.13   49.38   49.38   49.13   49.13];
            
            m_line(bndry_lon, bndry_lat, 'linewi',1, 'color','k');
            m_patch(bndry_lon, bndry_lat,'w');
            
            for j = 1:5
            m_vec(vec_scale, -123.06, 49.4 - 0.04*j, vec_step(j+1), 0, ...
                vec_color(j,:), 'headlength',1,...
                'shaftwidth',0.2,'headangle',40)
            m_text(-123.14, 49.4 - 0.04*j, num2str(vec_step(j+1)), ...
                'color',vec_color(j,:),'FontSize',...
                vec_leg_FS, 'FontWeight','bold')
            end
            
            
            
            
            m_text(-123.14, 49.4 - 0.04*(j+1), 'cm/s', ...
                'color','k','FontSize',...
                vec_leg_FS, 'FontWeight','bold')
            
        end
        
        
        
    end
    
    
    % adding the line showing sandheads (river outreach)
    hold on
    m_line(sandheads(1,:),sandheads(2,:),'linewi',1,'color','cyan');
    
    
    
    % add the wind vector onto the sandheads
    if opt_bool
        data_wu = nanmean(SPMGD.wspd(data_idx).*cosd(SPMGD.wdir(data_idx)));
        data_wv = nanmean(SPMGD.wspd(data_idx).*sind(SPMGD.wdir(data_idx)));
        
    else
        data_wu = nanmean(codar_wu(cod_idx));
        data_wv = nanmean(codar_wv(cod_idx));
        
    end
    
    
    
%     hold on
    wvec_lon = -123.14;
    wvec_lat = 49.35;
    
    
    % option: spm, type: season (wind_legend_idx = 3)
    % wind_leg_FS = 12
    
%     wvec_scale = 5;
%     wvec_hl = 6;
%     wvec_sw = 1;
    
    % option: codar, type: season (wind_legend_idx = 3)
    % wind_leg_FS = 12
%     wvec_scale = 12;
%     wvec_hl = 2;
%     wvec_sw = 0.4;

    % option: spm, type: tide (wind_legend_idx = 10)
%     wind_leg_FS = 9;
%     wvec_scale = 15;
%     wvec_hl = 2;
%     wvec_sw = 0.4;
    
    if (~ opt_bool && strcmpi(typ_str,'tide')) || strcmpi(typ_str,'wind_rf')
            
       wvec_lat = 49.25;
    end
    
    m_vec(wvec_scale, sandheads(1,1),sandheads(2,1),data_wu, data_wv,'k', ...
        'headlength', wvec_hl, 'shaftwidth', wvec_sw,'headangle',40)
   if i == wind_legend_idx      
        m_vec(wvec_scale, wvec_lon, wvec_lat, 2, 0, 'k', 'headlength', wvec_hl, ...
            'shaftwidth', wvec_sw,'headangle',40)
        m_text(wvec_lon, wvec_lat - 0.05,{'2 m/s'},'FontSize',wind_leg_FS,...
            'FontWeight','bold','color','k')
    end
    
    
    
    
   
    
    
    
    
    
    
    switch typ_str
        case {'season','tide'}
            % only show the logitude and latitude labels in the left column and
            % bottom row
            
            
            % both ytick and xtick for the lower-left one are kept
            if i == (row-1)*col +1
                m_grid('linestyle','none','tickdir','out','box','on',...
                    'FontSize',12);
                
            % delete xticks for the leftmost column (except the lower-left one)
            elseif mod(i,col) == 1
                m_grid('linestyle','none','tickdir','out','box','on',...
                    'FontSize',12, 'xtick',[]);
                
            % delete yticks for the bottom row
            elseif i > (row-1)*col +1
                m_grid('linestyle','none','tickdir','out','box','on',...
                    'FontSize',12, 'ytick',[]);
                
            % delete both xticks and yticks for all other subplots
            else
                m_grid('linestyle','none','tickdir','out','box','on',...
                    'FontSize',12, 'ytick',[],'xtick',[]);
            end
            
        case 'wind_rf'
            
            % put ylabels for the leftmost column
            if mod(i,col) == 1
                ylabel(river_str{rf_loop(i)},'FontSize',18,...
                    'FontWeight','bold');
                ha(i).YLabel.Position(1:2) = [-0.0060 0];
                
            end
            
            % put xlabels on top for the top row
            if i <= col
                xlabel(wind_str{wind_loop(i)},'FontSize',18,...
                    'FontWeight','bold');
                set(ha(i),'XAxisLocation','top');
                ha(i).XLabel.Position(1:2) = [0 0.0054];
            end
            
            % delete all xticks and yticks for the subplots
            m_grid('linestyle','none','tickdir','out','box','on',...
                'FontSize',12, 'ytick',[],'xtick',[]);
            
    end
    
    
    % A title above all subplots
    sgtitle([sg_title_1,sg_title_2],'FontSize',sgt_FS,'FontWeight','bold');
    
end


% Making a colorbar at the right side of the figure if the 'option' is
% 'spm'
if opt_bool
    % set position and make axes
    cbar = axes('Position',cbar_pos,'box','on');
    % cy: y values for filling out the colors in colorbar. (a log-scale
    %   spaced array)
    cy = 10.^(linspace(-1,log10(30),200));
    cy = flipud(cy');
    % cx: values for the x axis (it could be anything)
    cx = [0,1];
    % Y: a meshgrid data for cx and cy
    [~, Y] = meshgrid(cx, cy);
    % make a pcolor plot into the axes box as the colorbar
    pcolor(cx, cy, Y); shading flat;
    % reset some properties of the colorbar
    set(cbar,'colorscale','log','yscale','log','YAxisLocation','right');
    % make a same colormap as we did in the subplots
    colormap(m_colmap('jet','step',15));
    % only show some certain YTick labels
    cbar.YTick = [0.1 0.2 0.5 1 2 5 10 20 30];
    cbar.TickLength = [0.028 0.02];
    % delete XTick labels
    cbar.XTick = [];
    cbar.FontSize = 12;
    ylim([0.1 30]);
    cbar.FontWeight = 'bold';
    hold on
    % draw a horizonal line at SPM = 2 g/m^3
    yline(2,'linewi',2,'color','k')
    ylabel('SPM (g/m^3)','FontSize',14,'FontWeight','bold',...
        'Position',[1.8 1.7321 -1])
end

% directory and filenames for saving the gigure
save_dir = '/users/shuminli/Nextcloud/study_prjs/EOSC584_Project/';
save_fname = strcat(save_str_1, save_str_2);

% if 'save_fig' input is 'yes', then use function export_fig to export
% a nice high-resolution figure
if strcmpi(save_str,'yes')
    export_fig([save_dir, save_fname],'-png','-r400');
end


end