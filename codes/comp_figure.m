function comp_figure(sandheads, gridLon, coast_dir, gridLat, river_dir, ...
    bath_lat, bath_z, bath_lon, COD)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function makes 4 comprison plots between Sentinel-2 Image, MODIS
% Aqua derived SPM (Suspended Particulte Matters) images, and HF Radar 
% derived surface currents on July 29th, 2020
%
% Sentinel-2 image is taken at 29-July-2020 11:09 a.m. (PDT)
%
% MODIS took 2 images on the same day at:
% 29-July-2020 12:10 p.m. and 29-July-2020 13:50 p.m. (pdt)
%
% HF Radar (CODAR) currents are chose at 29-July-2020 14:00 p.m. (pdt)
%
% Shumin Li, 2021, March
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Prepare data and address

% Address for the .nc file of Sentinel-2 data
address = strcat('/users/shuminli/Nextcloud/data/satellite/sentinel-2/',...
    'S2A_MSIL2A_20200729T190921_N0214_R056_T10UDV_20200729T233117_resampled.nc');
ncid = netcdf.open(address);

% longitude and latitude infor mation of sentinel-2 data
sentinel_lon = ncread(address,'lon');
sentinel_lat = ncread(address,'lat');

% extract bands with optical frequecy of red, gree and blue. and rescale it
% to the range of 0 to 1;
R = transpose(im2double(netcdf.getVar(ncid,4)));    % Red channel
G = transpose(im2double(netcdf.getVar(ncid,3)));    % Green channel
B = transpose(im2double(netcdf.getVar(ncid,2)));    % Blue channel
R = rescale(R,0,1);
G = rescale(G,0,1);
B = rescale(B,0,1);


% Remove the overexposure data (wich is usually found to be > 0.18),
% concatenate R, G and B into a [1098x1098x3 double] sized RGB array, and
% rescle it to [0 255];
R(abs(R)>0.18) = NaN;
G(abs(G)>0.18) = NaN;
B(abs(B)>0.18) = NaN;
RGB = cat(3, R, G, B);
RGB = uint8(rescale(RGB, 0, 255));

% addpath to use function tide_hrs, and the t_tide toolbox
addpath /Users/shuminli/Nextcloud/study_prjs/front_propagation;
addpath /Users/shuminli/Nextcloud/codes/t_tide


% 2 addresses for the SPM data files in 2020 July 29th
spm_add1 = '/Users/shuminli/Nextcloud/data/SPM/SPM_new_download/A2020211201000.mat';
spm_add2 = '/Users/shuminli/Nextcloud/data/SPM/SPM_new_download/A2020211215000.mat';

% extract spm data from the two files
spm_struct_1 = load(spm_add1,'data');
spm_data_1 = spm_struct_1.data.gridSPM;
spm_data_1(spm_data_1 <= 0) = nan;
spm_struct_2 = load(spm_add2,'data');
spm_data_2 = spm_struct_2.data.gridSPM;
spm_data_2(spm_data_2 <= 0) = nan;

% UTC times for the 2 SPM data and 1 Sentinel-2 data
t1 = datenum(2020,7,29,12,10,00) + 8/24;
t2 = datenum(2020,7,29,13,50,00) + 8/24;
t_sentinel = datenum(2020, 7, 29, 11, 9, 0) + 8/24;

%% Start Ploting the figure


figure('Position',[100 0 800 900],'color','w')
% making 2x2 subplot
ha = tight_subplot(2,2,[0.06 0.03],[ 0.04 0.11],[0.05 0.02]);

% a title above all subplots
sgtitle('Comparison of Sentinel-2 Image, MODIS SPM Image and HF Radar Currents',...
    'FontSize',20,'FontWeight','bold')

% grid box for m_map
bx=[-123.9 -122.9 48.8 49.4];

%% Plot SPM Images
% plot the two spm image in axes ha(2) and ha(3)
for i = 2:3
    
    %  assign data address and time for the 2 SPM data
    switch i
        case 2
            spm_data = spm_data_1;
            t = t1;
        case 3
            spm_data = spm_data_2;
            t = t2;
    end
    
   
    axes(ha(i));
    
    % Plot spm data with a "m_jet" colormap, and with a log colorscale
    % within the range of [0.1 30] SPM (g/m^3)
    m_proj('lambert','lon',bx(1:2),'lat',bx(3:4));
    m_pcolor(gridLon, gridLat, spm_data);
    caxis([0.1,30]);
    colormap(m_colmap('jet','step',15));
    set(gca,'colorscale','log');
    
    % adding the line of river channel outreach at Sand Heads
    m_line(sandheads(1,:),sandheads(2,:),'linewi',1,'color','cyan');
    
    % adding coastlines, river lines, and grids
    m_usercoast(coast_dir,'patch',[.7 .7 .7],'edgecolor','none');
    m_usercoast(river_dir,'patch',[.7 .7 .7],'edgecolor','none');
    m_grid('linestyle','-','gridcolor','w','tickdir','out','box','on','FontSize',15);
    
    % title for the subplots
    title(['MODIS SPM Image at ',datestr(t - 8/24) ,' p.m.'],'fontsize',15)
    
    % Adding a log-scale colorbar inside the map using m_contfbar, draw a
    % line at SPM = 2 g/m^3, which will be the same value as the contour 
    % in the map
    [ax,~]=m_contfbar(.8,[.5 .95],[0.1 30],(0.1:0.03:30),...
        'edgecolor','none','endpiece','yes',...
        'colorscale','log','YScale','log');
    ax.YAxisLocation = 'right';
    ax.YTick = [0.1 0.5 1 2 5 10 20 30];
    ax.YLabel.String = 'SPM (g/m^3)';
    ax.YLabel.FontWeight = 'bold';
    ax.FontSize = 10;
    ax.TickLength = [0.02 0.02];
    yline(ax, 2,'linewi',2,'color','k')
    
    % Adding the 20-m isobath line, which indicated the boundary of
    % mudflats
    hold on
    [c2,h2] = m_contour(bath_lon,bath_lat,bath_z,[20 20],...
        'linestyle','-','color','g',...
        'ShowText','on','LabelSpacing',300);
    clabel(c2,h2,'color','g')
    
    % Adding a contour line with SPM = 2 g/m^3, which indicated the
    % boundary of plume region
    hold on
    v = [2, 2];
    m_contour(gridLon, gridLat,spm_data,v,'color','k','linewi',2)
    
    
    sub_position = ha(i).Position;
    
    % Adding a new axis at the lower left corner to show the tidal
    % elevation within a tidal cycle and the current tidal elevation
    ax_tide = axes ('box', 'off' );
    ax_tide.Position = sub_position + [0.028 0.005 -0.22, -0.35];
    % create a hourly time array of +/- 5 days since the give time
    hour_time = t-5:1/24:t+5; % UTC time
    
    % using t_xide function (from t_tide toolbox) to get the tidal
    % elevations of the given time array
    hour_tide = t_xtide('Point Atkinson (2)',hour_time-8/24); % PDT
    
    % getting tide lag hours (which is define as the time relative to the
    % lower low tide of the day) in minutes. tideval is an array for
    % plotting a smooth tidal cycle plot later. Look atAppendix of more
    % information of tide_hrs function
    [lag_min, ~, ~, tideval] = ...
        tide_hrs(hour_tide, hour_time - 8/24,t - 8/24,'no');
    
    % plot the tidal elevation figure at lower left corner.
    minilag = -7.5:1/60:17.5;
    plot(minilag, tideval, 'b','Linewi',2);
    hold on
    xline(lag_min,'color','r','linewi',2)
    xlim([-7.5 17.5]);
    ylim([0 5]);
    set(ax_tide, 'box','off','XAxisLocation','top','YAxisLocation',...
        'right','FontWeight', 'bold','FontSize',10)
    xticks(-7:3:17);
    xlabel('Tide Lag Hours (h)');
    ylabel('(m)');
    grid on
end


%% Plot the Sentinel-2 Image

% Start plotting Setinel-2 image in the left subplot
axes(ha(1));
m_proj('lambert','lon',bx(1:2),'lat',bx(3:4));

% plot the RGB color onto the map using m_image function
m_image(sentinel_lon(:,6000), sentinel_lat(7500,:),RGB);
m_grid('linestyle','-','gridcolor',[1 1 1],'tickdir','out','box','on','FontSize',15);
hold on

% Adding the the contours where SPM = 2 g/m^3 in the SPM plot on to the
% sentinel plot as a comparison. yellow for 12:10 p.m. and red for 13:50 p.m.  
v = [2, 2];
m_contour(gridLon, gridLat,spm_data_1,v,'color','y','linewi',2,'linest','-')
hold on
m_contour(gridLon, gridLat,spm_data_2,v,'color','r','linewi',2,'linest','-')


% adding Sand Heads locations
hold on
m_line(sandheads(1,:),sandheads(2,:),'linewi',1,'color','cyan');

% adding 20-m isobath contour
hold on
[c2,h2] = m_contour(bath_lon,bath_lat,bath_z,[20 20],...
    'linestyle','-','color','g',...
    'ShowText','on','LabelSpacing',300);
clabel(c2,h2,'color','g')

% title of the subplot
t = t_sentinel;
title(['Sentinel-2 Image at ',datestr(t - 8/24),' a.m.'],'fontsize',15)

% make some legend labels at the upper left corner
hold on
m_line([-123.85, -123.65],[49.35, 49.35],'linewi',2,'color','y')
m_text(-123.85, 49.33,'12:10 p.m.','color','y',...
    'Fontsize',12,'fontweight','bold')

m_line([-123.85, -123.65],[49.29, 49.29],'linewi',2,'color','r')
m_text(-123.85, 49.27,'13:50 p.m.','color','r',...
    'Fontsize',12,'fontweight','bold')


sub_position = ha(1).Position;
% adding a similar tidal elevation plot at the lower left corner for
% the time when Sentinel-2 image is taken
ax_tide = axes ('box', 'off' );
ax_tide.Position = sub_position + [0.028 0.005 -0.22, -0.35];

hour_time = t-5:1/24:t+5;
hour_tide = t_xtide('Point Atkinson (2)',hour_time-8/24); % PDT
[lag_min, ~, ~, tideval] = ...
    tide_hrs(hour_tide, hour_time - 8/24,t - 8/24,'no');
minilag = -7.5:1/60:17.5;
plot(minilag, tideval, 'b','Linewi',2);
hold on
xline(lag_min,'color','r','linewi',2)
xlim([-7.5 17.5]);
ylim([0 5]);
grid on
xticks(-7:3:17);
xlabel('Tide Lag Hours (h)','color','w');
ylabel('(m)','color','w');
set(ax_tide, 'box','off','XAxisLocation','top','YAxisLocation',...
    'right','FontWeight', 'bold','FontSize',10,'XColor',...
    'w','YColor','w','GridColor',[.15 .15 .15])


%% Plot HF Radar (CODAR) surface currents

axes(ha(4));
m_proj('lambert','lon',bx(1:2),'lat',bx(3:4));
% finding the index of the codar data which is closest to the time of the 
% second SPM image
[~,cod_idx] = min(abs(COD.mtime - t2));

% adding the plume contour from the second SPM image
v = [2, 2];
hold on
m_contour(gridLon, gridLat,spm_data_2,v,'color','r','linewi',2,'linest','-')

% coastlines and grids
m_usercoast(coast_dir,'patch',[.7 .7 .7],'edgecolor','none');
m_usercoast(river_dir,'patch',[.7 .7 .7],'edgecolor','none');
m_grid('linestyle','-','gridcolor','w','tickdir','out','box','on','FontSize',15);

% surface current arrows
m_vec(300,COD_GRID.lon,COD_GRID.lat,COD.u(:,:,cod_idx),...
    COD.v(:,:,cod_idx),'headlength',3,'shaftwidth',0.5,'facecolor','k');

% put a vector length scale legend at upper right of the subplot
m_vec(300, -123.1, 49.25, 50, 0, 'headlength',3,'shaftwidth',0.5)
m_text(-123.1, 49.23,'50 cm/s', 'FontSize',10, 'FontWeight','bold')

% put a legend of the plume region contour at upper left
m_line([-123.85, -123.65],[49.29, 49.29],'linewi',2,'color','r')
m_text(-123.85, 49.27,'13:50 p.m.','color','r',...
    'Fontsize',12,'fontweight','bold')

% adding sand heads locaitons
hold on
m_line(sandheads(1,:),sandheads(2,:),'linewi',1,'color','cyan');

% adding 20-m isobath contour
hold on
[c2,h2] = m_contour(bath_lon,bath_lat,bath_z,[20 20],...
    'linestyle','-','color','g',...
    'ShowText','on','LabelSpacing',300);
clabel(c2,h2,'color','g')

% title of the subplot
title(['HF Radar Currents at ',...
    datestr(COD.mtime(cod_idx) - 8/24), ' p.m.'],...
    'FontSize',15,'FontWeight','bold');

% put a similar tidal elevation axes at lower left corner
sub_position = ha(4).Position;
t = COD.mtime(cod_idx);
ax_tide = axes ('box', 'off' );
ax_tide.Position = sub_position + [0.028 0.005 -0.22, -0.35];

% getting tide lag hours
[lag_min, ~, ~, tideval] = ...
    tide_hrs(hour_tide, hour_time - 8/24, t - 8/24,'no');

% plot the tidal elevation figure at lower left corner.
minilag = -7.5:1/60:17.5;
plot(minilag, tideval, 'b','Linewi',2);
hold on
xline(lag_min,'color','r','linewi',2)
xlim([-7.5 17.5]);
ylim([0 5]);
set(ax_tide, 'box','off','XAxisLocation','top','YAxisLocation',...
    'right','FontWeight', 'bold','FontSize',10)
xticks(-7:3:17);
xlabel('Tide Lag Hours (h)');
ylabel('(m)');
grid on

% export the high resolution figure using fuction export_fig
save_dir = '/users/shuminli/Nextcloud/study_prjs/EOSC584_Project/';
save_fname = 'comp_fig';
export_fig([save_dir, save_fname],'-png','-r400');

end