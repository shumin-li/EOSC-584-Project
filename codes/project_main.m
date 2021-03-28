%% Project Main

% This is the main fuction for the project used for Course EOSC 584.
% Running this function in order will load and process the required data,
% and plot all the fiugres in the project report
%
% Shumin Li, March 2021
% -------------------------------------------------------------------------

% loading data
% detailed description of the this function see project_dataload.m
[SPMGD, COD_GRID, coast_dir, river_dir, fraser, ...
    sandheads, bx, gridLon, gridLat, bath_lat, bath_lon, bath_z, ...
    sh, COD] = project_dataload;

% add the path of the project, in which all the functions are kept 
addpath /Users/shuminli/Nextcloud/study_prjs/EOSC584_Project;

save_str = 'yes';
%% Comparison Plot
% plot comparison figures of sentinel-2, MODIS SPM images, 
% and CODAR surface currents 
comp_figure(sandheads, gridLon, coast_dir, gridLat, river_dir,...
    bath_lat, bath_z, bath_lon, COD)

%% Seasonality analysis 

% Seasonality analysis plots of plume shape, surface currents, plume area, 
% river discharge and wind speed/directions

% Plot the figures of plume pattern Seasonality
% using plume_subplots function, with 'option'->'spm' and 'type'->'season'
plume_subplots(sandheads, gridLon, gridLat, river_dir, ...
    coast_dir, bx, SPMGD, COD, fraser, sh,  'option','spm',...
    'type','season','save_fig',save_str);

% Plot of the figurers of surface currents seasonality
% using plume_subplots function, with 'option'->'codar' and 'type'->'season'
plume_subplots(sandheads, gridLon, gridLat, river_dir, ...
    coast_dir, bx, SPMGD, COD, fraser, sh,  'option','codar',...
    'type','season','save_fig',save_str);

% Boxchart of plume area seasonality
area_boxchart(SPMGD,'option','season','save',save_str)

% Fraser River Discharge Seasonality
river_seasonality(fraser,'save',save_str)

% Wind type seasonality for all wind data, and only for the time when SPM
% images are taken
wind_seasonality(sh,SPMGD,'save',save_str)

%% Wind and river influence analysis

% Plot the figures of plume patterns by different wind and river flow
% conditions, using plume_subplots function, with 'option'->'spm' 
% and 'type'->'wind_rf'
plume_subplots(sandheads, gridLon, gridLat, river_dir, ...
    coast_dir, bx, SPMGD, COD, fraser, sh,  'option','spm',...
    'type','wind_rf','save_fig',save_str);

% Plot of the figurers of surface currents variation with wind and river
% flow, using plume_subplots function, with 'option'->'codar' 
% and 'type'->'wind_rf'
plume_subplots(sandheads, gridLon, gridLat, river_dir, ...
    coast_dir, bx, SPMGD, COD, fraser, sh,  'option','codar',...
    'type','wind_rf','save_fig',save_str);

% Plot the correlation between plume area and river discharge 
area_rf_relation(SPMGD, 'save',save_str)


%% Tidal influence analysis

% Plot the figures of plume patterns under a tidal cycle
% conditions, using plume_subplots function, with 'option'->'spm' 
% and 'type'->'tide'
plume_subplots(sandheads, gridLon, gridLat, river_dir, ...
    coast_dir, bx, SPMGD, COD, fraser, sh,  'option','spm',...
    'type','tide','save_fig',save_str);

% Plot of the figurers of surface currents variation with wind and river
% flow, using plume_subplots function, with 'option'->'codar' 
% and 'type'->'tide'
plume_subplots(sandheads, gridLon, gridLat, river_dir, ...
    coast_dir, bx, SPMGD, COD, fraser, sh,  'option','codar',...
    'type','tide','save_fig',save_str);

% Boxchart of plume area over a tidal cycle
area_boxchart(SPMGD,'option','tide','save',save_str)

