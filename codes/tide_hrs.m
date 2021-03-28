function  [H, L, T, V]= tide_hrs(tideh, tidet, tt, is_fig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function mainly help us to find the tdial lag hours relative to the
% lower low tide of the day
% it will export the following variables:
%
% - H: the thide lag hours
% - L: the low tide height
% - T: the low tide time
% - V: the array of the tidal elevation for 2 days before/after the given
% time
%
% it requires the following input:
% - tideh: tidal elevation vector for a certain amount of time
% - tidet: the times corresponding to tideh
% - tt: the time you putin to get [H, L, T, V].
% - is_fig: 'yes' for ploting an example figure, 'no' for not plotting
%
% Shumin Li, February 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for k = 1:numel(tt)
    t = tt(k);
    
    timest = t - 1.5 ;
    timeed = t + 1.5 ;
    
    timei = find(tidet >= timest & tidet <= timeed);
    
    % interp the input hourly data into per-minite data
    timen = timest:1/24/60:timeed;
    tiden = interp1(tidet(timei),tideh(timei),timen,'spline');
    
    % finding the regional minimum points in the curve
    n = length(timen);
    
    c = [];
    d = [];
    
    for ii = 2:n-1
        if tiden(ii) - tiden(ii-1) < 0 && tiden(ii) - tiden(ii+1) < 0
            c = [c; ii];
            d = [d;tiden(ii)];
        end
        
    end
    
    % sort these regional minimum points from low to high, as long as
    % lowest point falls in the range of [-7.6 17.6] hrs, the choose it as
    % the lower-low tide point of the day, and output its tide lag time in 
    % minutes, height, time, an array of it daily tidal elevation for plot
    
    [B,I] = sort(d);
    time_diff = 24*(t - timen(c));
    
    for i = 1:numel(I)
        if -7.6 < time_diff(I(i)) && time_diff(I(i)) < 17.6
            H(k) = time_diff(I(i));
            L(k) = B(i);
            T(k) = timen(c(I(i)));
            [~,bb] = min(abs(timen - T(k)));
            if numel(tt) > 1
                V(k,:) = tiden(bb - 7.5*60: bb+17.5*60);
            else
                V = tiden(bb - 7.5*60: bb+17.5*60);
            end
            
            break
        end
    end
    
end

% if the last input from the function is 'yes', then plot an example figure
if strcmp(is_fig,'yes') && numel(tt) == 1
    figure('Position',[100 100 800 200])
    
    clf
    plot(timen, tiden,'-r','linewi',2)
    xline(t,'linewi',2,'color','k')
    hold on
    xline(T,'color','k','linewi',2,'linest','--')
    axdate(12);
    hold on
    set(gca, 'FontSize',14)
    plot(timen(c),d, 'go','linewi',2)
    title(['Tide Lag = ',num2str(H(1)),' (h); Low Tide Height = ', num2str(L(1)),' (m); ', ...
        'Low Tide Time = ', datestr(T(1))])
end

end


