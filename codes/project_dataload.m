function [SPMGD, COD_GRID, coast_dir, river_dir, fraser, ...
    sandheads, bx, gridLon, gridLat, bath_lat, bath_lon, bath_z, ...
    sh, COD] = project_dataload

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function loads the data, directories and other information which
% will be used in Shumin Li's course project for EOSC 584: 
% Fraser River Plume Observation with Satellite Remote Sensing Data
%
% SPMGD: data struct of MODIS derived SPM (suspend particulate matters)
% COD_GRID: CODAR lon/lat grid and time
% coast_dir: directory of BC coast
% river_dir: directory of BC river and lake coastlines
% fraser: fraser river discharge data
% sh: surface winds from Sandheads lighthouse
% sandheads: locations of the Fraser River outreach at Sandheads
% bx: grid box used for plotting maps
% gridLon, gridLat: Longitude and Latitude for MODIS SPM grids
% bath_lat, bath_lon, bath_z: latitude, longitude and depthe of a fine
% scaled bathymetry in the Strait of Georgia

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





% Load the processed MODIS SPM data, only the good days (2731 images from 2003 to 2019)
% are included in the struct. Some import fileds in SPMGD are 
% val: [668×729×2731 double], 668*792 pixels each image, 2731 images total
% tiimePDT: [1×2731 double], time in PDT
% wspd: [1×2731 double], wind speed (m/s)
% wdir: [1×2731 double], wind direction in degrees
% RF: [1×2731 double], Fraser River Discharge (m^3/s)
% lag_min: [1×2731 double], tide lag time in minutes relative to the lower 
%          low tide of the day. (value between -7.5 and 17.5 hours)
% lag_h: [1×2731 double], tide lag time in hours relative to the lower 
%          low tide of the day. (value are -7:17 hours)
% percent_valid: [1×2731 double]. Percetage of pixels with valid data in
%          the Strait of Georgia. (over 50% are considered to be good)
% center_valid: [1×2731 double]. Percetage of pixels with valid data in
%          the center of plume region. (over 60% are good)
% area: [1×2731 double]. area with SPM >= 2 g/m^3, which is considered as
%          the plume area
% plume_ave: [1×2731 double]. averaged SPM value in the plume area. (g/m^3)
load('/users/shuminli/Nextcloud/study_prjs/front_propagation/SPMGD.mat');

% Load COD_GRID.mat, which include the longitude, latitude and time
% information of the CODAR derived surface currents
load /users/shuminli/Nextcloud/data/CODAR/COD_GRID.mat;

% directory of a fine scale BC coast data
coast_dir = '/users/shuminli/Nextcloud/data/others/BCcoast.mat';

% directory of a fine scaled river and lake contours
river_dir = '/users/shuminli/Nextcloud/data/others/PNWrivers.mat';

% Load daily fraser river discharge data 
load /users/shuminli/Nextcloud/data/river/Rich/FRASER.mat;

% Load wind data recorded from Sandhead Lighthouse
sh=load('/users/shuminli/Nextcloud/data/wind/sand.mat');

% locations of the Fraser River outreach at Sandheads
sandheads=[-123-[18.2 13.7 12]/60 ;...
            49+[6.4 8  7.6]/60 ];
        
% grid box used for plotting maps
bx=[-123.9 -122.9 48.8 49.4];

% generate the grids for MODIS SPM images, 
latMin=48.5;
latMax=50;
lonMin=-124.5;
lonMax=-122.;
[gridLon,gridLat] = meshgrid([lonMin:0.00343:lonMax], [latMin:0.002246:latMax]);

% Extract the find-scale bathymetry information from
% british_columbia_3_msl_2013.nc, mask out the unnecessary information for
% the area that we do not care, and leave a clean data for plotting the 20m
% bathymetry in the future maps
fname = '/users/shuminli/Nextcloud/data/others/british_columbia_3_msl_2013.nc';
load /users/shuminli/Nextcloud/study_prjs/front_propagation/spm_bath_mask_for20m.mat;

lat_lim = [48.8 49.4]; lon_lim = [-123.8 -122.9];
lat = ncread(fname,'lat');
lon = ncread(fname,'lon');

ilon = lon>= lon_lim(1) & lon<= lon_lim(2);
ilat = lat>= lat_lim(1) & lat<= lat_lim(2);
Z = ncread(fname,'Band1',[find((ilon),1,'first') find((ilat),1,'first')],...
    [sum(ilon) sum(ilat)], [1,1]);

bath_lat = repmat(flipud(lat(ilat)),[1,sum(ilon)]);
bath_lon = repmat(lon(ilon)',[sum(ilat),1]);
bath_z = flipud(Z'*(-1));
% bath_in: index of bathymetry data within a plygon around the river plume 
bath_in = inpolygon(bath_lon, bath_lat, spm_bath_mask_for20m(:,1),spm_bath_mask_for20m(:,2));
bath_z(~bath_in) = nan;


% Load the CODAR data and name it as COD. Some important fields in COD are:
% mtime: [40221×1 double], time in UTC
% lon/lat: [74×93 double], longitudes and latitudes
% u/v: [74×93×40221 double], zonal and meridional velocities in cm/s
CODa=load('/users/shuminli/Nextcloud/data/CODAR/SoG_radar_totals.mat');
COD=CODa.v2;
clear CODa
end