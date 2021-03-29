function tide_spm_histogram(SPMGD, varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This fuction simply makes a figure of 5*5 subplots showing the valid SPM
% image distributed in each month under a tidal cycle. mainly demenstrating
% some bias in analyzing the MODIS SPM images.
%
% - 'save'
%   - 'yes': export the figure into the project directory
%   - 'no' (or any other string): do not save the figure
%
% Shumin Li, March 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmpi(varargin{1}, 'save')
    sav_str = varargin{2};
end

%%
marg_w = [0.08 0.08];
fig_pos = [100 100 650 600];
row = 5;
col = 5;
gap = [0.005 0.005];
marg_h = [0.05 0.09];
sgt_FS = 20;

figure('color','w','Position',fig_pos);
ha = tight_subplot(row,col,gap,marg_h,marg_w);

[~,spm_month,~,~,~,~] = datevec(SPMGD.timePDT);
better_index = SPMGD.percent_valid > 0.4 & SPMGD.center_valid > 0.5;
sgtitle('Histograms of the No. SPM images in a tidal cycle',...
    'FontSize',sgt_FS,'FontWeight','bold');



for i = 1:row*col
    
axes(ha(i));

tide_idx = SPMGD.LowTide < 2.1;

j = i - 8;
lag_2h =  SPMGD.lag_min > j-1 & SPMGD.lag_min < j+1;

% Count tide lag hours from 17h to 18h into "-7h" segment,
% and also count the -8h to -7h period as part of "17h" segment
if j == -7
    lag_2h =  SPMGD.lag_min > 17 | SPMGD.lag_min < -6;
elseif j == 17
    lag_2h =  SPMGD.lag_min > 16 | SPMGD.lag_min < -7;    
end

% put the earlier creterion together
data_idx =  lag_2h & better_index & tide_idx;

hist_edges = linspace(0.5, 12.5, 13);
histogram(spm_month(data_idx),hist_edges)

ylim([0 90]);

ax = gca;
ax.XTick = (1:12);
ax.XTickLabel = {'Jan','','','Apr','','','Jul','','','Oct','',''};
ax.YTick = (0:10:90);
ax.YTickLabel = {'0','','20','','40','','60','','80',''};
grid on
text(0.5, 80,['h = ', num2str(j)],'FontSize',12,'FontWeight',"bold")

if i <= (row-1)*col
    set(gca,'XTickLabel',[])
end

if ~(mod(i,col) == 1)
    set(gca,'YtickLabels',[])
else
    ylabel('n (images)','FontSize',12,'FontWeight',"bold")
end

set(gca, 'FontWeight',"bold")
end

if strcmpi(sav_str, 'yes')
    save_dir = '/users/shuminli/Nextcloud/study_prjs/EOSC584_Project/';
    save_fname = 'SPM_histogram';
    export_fig([save_dir, save_fname],'-png','-r400');
end


end