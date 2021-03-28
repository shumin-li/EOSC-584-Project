function build_SPMindex(varargin)
%% build the struct of SPMGD.mat data struct from scratch
% 'save': save the SPMGD.mat into the given folder
%        - 'no': don't save
%        - a directory with file names
%             e.g. '/users/shuminli/Nextcloud/study_prjs/front_propagation/SPMGD2.mat'
%             then the SPMGD variable will be saved as SPMGD2.mat in the
%             given directory.
% 
% Shumin Li, February 2021

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% loading necessary data and directories

% load wind data from sand heads
sh=load('/users/shuminli/Nextcloud/data/wind/sand.mat');

% load a reprocessed wind data in the Strait of Georgia using EOF
sh_re = load('/users/shuminli/Nextcloud/data/wind/SoGwinds.mat');

% load fraser river discharge data
load /users/shuminli/Nextcloud/data/river/river_new/fraser.mat;

% spm_plume_ginput.mat conatians two matrix: 
% spm_plume_input and spm_center_input:
%
% - spm_plume_input: a polygon inside the strait of georgia, (where the plume
%   is likely to appear)
% - spm_center_input: a ploygon near the river mouth, where the core of the
%   plume is most like to be.
%
% Then we can use these two box as a standard to automatically picking up
% the possible good spm images (e.g. the coverage in the strait is over 50%
% or the coverage in the plume center is over 60%)
% 
% And spm_in and spm_center_in are the indices inside each polygon
load('/users/shuminli/Nextcloud/study_prjs/front_propagation/spm_plume_ginput.mat');
spm_in = inpolygon(gridLon,gridLat,spm_plume_ginput(:,1),spm_plume_ginput(:,2));
spm_centerin = inpolygon(gridLon,gridLat,spm_center_ginput(:,1),spm_center_ginput(:,2));

% Making the long/lat grid of SPM images
latMin=48.5;
latMax=50;
lonMin=-124.5;
lonMax=-122.;
[gridLon,gridLat] = meshgrid([lonMin:0.00343:lonMax], [latMin:0.002246:latMax]);

%% begin to build the struct file

% This folder contains 11,000+ individual .mat file for daily spm pictures
% (twice a day from 2003 to 2019). All filenames are like
% 'A2018144204500.mat', where 'A' mean MODIS Aqua Satellite, '2018' is
% year, '144' is the day of the year, '204500' are the hour, minutes and
% seconds in UTC
SPM_folder = '/users/shuminli/Nextcloud/data/SPM/SPM_mat/';
SPM_dir = dir([SPM_folder, '*.mat']);

% extract the time information from the filenames 
SPM_name_num = nan(size(SPM_dir));
for i = 1:numel(SPM_name_num)
    SPM_name_num(i) = str2num(SPM_dir(i).name(4:12));
end


% build the date number and date strings
SPM_datenum = nan(size(SPM_dir));
SPM_datestr = cell(size(SPM_dir));
% 3 seconds for this loop
for i = 1:length(SPM_name_num)
    yy = str2num(SPM_dir(i).name(2:5));
    % ddd2mmdd is a simple fuction that converts 3-digit day to month and
    % day, the function of ddd2mmdd is as follows:
    %--------------------------------------------------
    % function [mm,dd] = ddd2mmdd(year, ddd) 
    % v = datevec(datenum(year, ones(size(year)), ddd)); 
    % mm = v(:,2); dd = v(:,3);
    %--------------------------------------------------
    [mm,dd] = ddd2mmdd(yy,str2num(SPM_dir(i).name(6:8)));
    if mm < 10 && dd<10
        SPM_datestr{i} = [num2str(yy),'-0',num2str(mm),'-0',num2str(dd),' ',SPM_dir(i).name(9:10),':',SPM_dir(i).name(11:12),':',SPM_dir(i).name(13:14)];
    elseif mm < 10 && dd >= 10
        SPM_datestr{i} = [num2str(yy),'-0',num2str(mm),'-',num2str(dd),' ',SPM_dir(i).name(9:10),':',SPM_dir(i).name(11:12),':',SPM_dir(i).name(13:14)];
    elseif mm >= 10 && dd < 10
        SPM_datestr{i} = [num2str(yy),'-',num2str(mm),'-0',num2str(dd),' ',SPM_dir(i).name(9:10),':',SPM_dir(i).name(11:12),':',SPM_dir(i).name(13:14)];
    else
        SPM_datestr{i} = [num2str(yy),'-',num2str(mm),'-',num2str(dd),' ',SPM_dir(i).name(9:10),':',SPM_dir(i).name(11:12),':',SPM_dir(i).name(13:14)];
    end
    formatIn = 'yyyy-mm-dd HH:MM:SS';
    SPM_datenum(i) = datenum(SPM_datestr{i},formatIn);
end

%% making the SPM struct for good days from 03 to 19

% generate the hourly tidal elevation from 2003 to 2019 from t_xtide
% function (about 1 sencond to run)
hour_time = SPM_datenum(1)-2:1/24:max(SPM_datenum(:))+2; % UTC time
hour_tide = t_xtide('Point Atkinson (2)',hour_time-8/24);


% building the SPMGD struct (about 3 minutes to run the loop)
SPMGD.filename = {};
j = 1;
for i = 1:numel(SPM_dir)
    name = SPM_dir(i).name;
    
    % 'A2018144204500.mat' is a bad data which cases some unknown error, so
    % we just skip it
    if strcmp(name,'A2018144204500.mat')
        continue
    end
    
    % load data
    data = load([SPM_folder,SPM_dir(i).name]);
    data_mat = data.data.gridSPM;
    
    % calculate the percentage of valida data within the strait and within
    % the center of the plume region
    percent_valid = sum(isfinite(data_mat(spm_in)),'all')/sum(spm_in(:));
    center_valid = sum(isfinite(data_mat(spm_centerin)),'all')/sum(spm_centerin(:));
    clear data
    
    
    if percent_valid >= 0.5 || center_valid >= 0.6
        % filenames, values, time in UTC and PDT, and timestring in PDT
        SPMGD.filename{j} = name;
        SPMGD.val(:,:,j) = data_mat;
        SPMGD.timeUTC(j) = SPM_datenum(i);
        SPMGD.timePDT(j) = SPM_datenum(i) - 8/24;
        SPMGD.timePDTstr{j} = datestr(SPM_datenum(i) - 8/24);
        
        % find the index of corresponding wind data and river flow data
        [w1, n1] = min(abs(SPM_datenum(i) - sh_re.it));
        [w2, n2] = min(abs(SPM_datenum(i) - sh.wtime));
        [ff, rr] = min(abs(SPM_datenum(i) - fraser.mtime));
        
        
        
        % fill in the wind speed and direction data. (Primarily use the
        % origional data from sandheads (i.e. sh), and use the EOF
        % reprocessed data (i.e. sh_re) as a compensate.
        if w1 < 1/24
            SPMGD.wspd(j) = abs(sh_re.TS(n1,1));
            wd = atan2d(imag(sh_re.TS(n1,1)),real(sh_re.TS(n1,1)));
            if wd< 0
                wd = wd + 360;
            end
            SPMGD.wdir(j) = wd;
            
        elseif w2 < 1/24
            SPMGD.wspd(j) = sh.wspd(n2);
            SPMGD.wdir(j) = sh.wdir(n2);
        else
            SPMGD.wspd(j) = nan;
            SPMGD.wdir(j) = nan;
        end
        
        % fill in the river discharge data
        if ff < 1
            SPMGD.RF(j) = fraser.flow(rr);
        else
            SPMGD.RF(j) = nan;
        end
        
        % calcute and record the tidal lag hours and other tidal
        % information using function tide_hrs
        [SPMGD.lag_min(j), SPMGD.LowTide(j),...
            SPMGD.LowTideTimePDT(j),SPMGD.TideVal(j,:)] = ...
            tide_hrs(hour_tide, hour_time - 8/24,SPM_datenum(i) - 8/24,'no');
        SPMGD.lag_h(j) = round(SPMGD.lag_min(j));
        SPMGD.percent_valid(j) = percent_valid;
        SPMGD.center_valid(j) = center_valid;
        j = j+1;

    end
end

SPMGD.lag_h(SPMGD.lag_h == -8) = -7;
SPMGD.lag_h(SPMGD.lag_h == 18) = 17;


% calculating the approximate area of a pixel at the center plume:
% longitude -123.3 at gridLon(:,351);
% latitude 49.1 at gridLat(272,:);
A = [272, 351];

% 4 edge points of the grid in the central plume area
B(1) = m_idist(gridLon(A(1),A(2)), gridLat(A(1),A(2)),...
    gridLon(A(1)+1,A(2)),gridLat(A(1)+1,A(2)));
B(2) = m_idist(gridLon(A(1),A(2)), gridLat(A(1),A(2)),...
    gridLon(A(1),A(2)+1),gridLat(A(1),A(2)+1));
B(3) = m_idist(gridLon(A(1)+1,A(2)), gridLat(A(1)+1,A(2)),...
    gridLon(A(1)+1,A(2)+1),gridLat(A(1)+1,A(2)+1));
B(4) = m_idist(gridLon(A(1),A(2)+1), gridLat(A(1),A(2)+1),...
    gridLon(A(1)+1,A(2)+1),gridLat(A(1)+1,A(2)+1));

% the four side length are almost identical, so it is almost a perfect
% square, so we will calculate the area of the pixel (parea) as a square
C = nanmean(B);
parea = C*C;

% calculate area of the plume region, the averaged spm level inside this 
% region and returen the new SPMGD struct.
for i = 1: numel(SPMGD.filename)
    spm_data = SPMGD.val(:,:,i);
    npixel = sum(spm_data > 2, 'all');
    SPMGD.area(i) = parea * npixel / 1000000;
    SPMGD.plume_ave(i) = nanmean(spm_data(spm_data > 2));
end

%% save the .mat file depending on input

save_idx=find(strcmpi('save',varargin),1);
if isempty(save_idx) || strncmpi(varargin{save_idx+1},'no',1)
    
else
    save_dir = varargin{save_idx+1};
    save(save_dir,'SPMGD','-v7.3');
end

end






