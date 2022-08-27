% This program analyze the dcb beam profile.
% 1) Calculate each bar smiling in px
% 2) Calculate relative distance between each bar.
% 3) Calculate the entire beam width. (95%)

clear; 
close all;
 
img_fld = 'D:\Matlab_program\Matlab_AppDesign\20190719_ProdLM_BeamAnalysis\data_prod\LM600_12_E';
full_name = fullfile(img_fld, '*.jpg');
fl_names = ls(full_name);

camrel = 23*1e-3; % cam resolution in mm;
bar_num = 12; % how many bars in the module
current = 100;  % input the test current value

[beamstruc_out] = fld_im_porcess(img_fld, fl_names, bar_num, camrel, num2str(current));
save('BeamParameter', 'beamstruc_out');
close all;

function [beamstruc_out] = fld_im_porcess(img_fld, fl_names, bar_num, camrel, current_str)

% THIS FUNCTION ANALYZE THE IMAGES IN THE INPUT FOLDER
% Img_fld is the image folder directory
% Img_num is the total image number is the folder
    

    % Initilization
    % Initilize the FAxis beam centroid;
    img_num = size(fl_names, 1);
    beamstruc_out.F_beam_cen = zeros(1,img_num); % Fast axis beam centroid in pixel
    beamstruc_out.F_beam_wid = zeros(1,img_num); % Fast axis 95% beam width in pixel
    
    beamstruc_out.emt_num = zeros(1,img_num); % Emitter number at differt current value
    beamstruc_out.F_beam_indFWHM = zeros(bar_num, img_num); % Only for max 12 emitters
    beamstruc_out.F_beam_indPekPos = zeros(bar_num, img_num); % Record the individual bar peak position
    beamstruc_out.F_beam_ind95 = zeros(bar_num, img_num);
    
    % Change to subfld direcotry and make processed folder
    cd(img_fld);
    mkdir('Processed');    
    cd('Processed');
    
    % Create plot figure;
    fh_pkpos = figure('Name', 'Smiling & relative peak distance', 'Color', 'w', 'Position', [2151, 8, 1198, 861]);
    ax1_pkpos = subplot(2,1,1); hold on;
    ax2_pkpos = subplot(2,1,2); hold on;
    line_color = linspecer(img_num);
  
    for n = 1: img_num

    img_file = fullfile(img_fld, fl_names(n,:)); % Save image files with current value
    img_full_flname = img_file;
    im_data = imread(img_full_flname);
    
    dcb_sn_str = strsplit(fl_names(n,:), '_');
    dcb_sn_str = dcb_sn_str{1};
    
    %1) show the raw image and plot roi on top of it.
    fh_raw = figure('Name', 'Raw image', 'Color', 'w', 'Position', [2151, 8, 1198, 861]);
    imshow(im_data, []); hold on; 
    roi_pos = [161, 157, 648, 400];
    rectangle('Position', roi_pos, 'LineWidth', 2, 'EdgeColor', 'c');
    hold off;
    text(455, 125, 'ROI', 'FontSize', 16, 'FontWeight', 'b', 'Color', 'c');
    saveas(fh_raw, [dcb_sn_str, '_', 'rawroi'], 'png');
    saveas(fh_raw, [dcb_sn_str, '_', 'rawroi'], 'fig');
    %2) calculate each bar smiling
    im_data_crop = im_data(roi_pos(2):roi_pos(2) + roi_pos(4), roi_pos(1): roi_pos(1)+roi_pos(3));
    im_bw = imbinarize(im_data_crop, 'global');    
    se = strel('square', 4);
    im_cl = imclose(im_bw, se); % connect split dots on the edge 
    se = strel('square', 2);
    im_out = imopen(im_cl, se); % remove the small pixels
    
    % flg = app.RotateImageby90DegreeSwitch.Value;
    %     if strcmpi(flg, 'Yes')
    %         im_data = rot90(im_data); 
    %     end
    % Define image X, Y ragne. 
    
    img_xr = [0, camrel*size(im_out,2)];
    img_yr = [camrel*size(im_out,1), 0]; % FOV in mm
    % Plot the lineout along the fast axis direction. 
    im_roi = im_out;  
    im_line_norm = sum(im_roi,1)./max(sum(im_roi,1)); % Normalization
    %3) Calculate the 95% beam width of the entire beam.
    im_line_norm_csum = cumsum(im_line_norm);
    [im_line_norm_csum_unique, ia, ~] = unique(im_line_norm_csum);
    y_25per = 0.025*max(im_line_norm_csum_unique);
    y_975per = 0.975*max(im_line_norm_csum_unique);
    x_width_px = interp1(im_line_norm_csum_unique, ia, [y_25per,y_975per]);
    beamstruc_out.F_beam_wid(n) = camrel*(x_width_px(2) - x_width_px(1)); % Calculate the 95% entire beam width in [mm]
    % Calculate how many emitters are left
    [MAXTAB, ~] = peakdet(im_line_norm, 0.2); % Set threshold of 20% maximum
    beamstruc_out.emt_num(n) = size(MAXTAB, 1); % Detect emitter number;
    % Define the subplots
    %ax1 = app.beam_lineout_ax_1; ax2 = app.beam_lineout_ax_2;
    fh_lnout = figure('Name', 'Beam profile & lineout', 'Color', 'w', 'Position', [2151, 8, 1198, 861]);
    ax1 = subplot(2,1,1, 'Color', 'w');
    
    plot(gca, im_line_norm, 'LineWidth', 3, 'DisplayName', 'FAxis Lineout'); 
    hold(gca,'on'); plot(gca, MAXTAB(:,1), MAXTAB(:,2), 'ro', 'LineWidth', 3, 'MarkerSize', 10);
    % Plot the position of the 95% beam width.
    plot(gca, [x_width_px(1), x_width_px(1)], [0,1], 'k-.', 'LineWidth', 3);
    plot(gca, [x_width_px(2), x_width_px(2)], [0,1], 'k-.', 'LineWidth', 3);
    title(gca,[dcb_sn_str, ' Bar Num: ', num2str(beamstruc_out.emt_num(n))]);
    axis(gca,'tight');
    set(gca, 'fontsize', 16);
    
    % Calculat the individual bar width FWHM in the fast axis direction
    hlf_max = 0.05*MAXTAB(:,2); % clculate 95% beam width and use it as smling calibration
    len = numel(hlf_max);
    ind = MAXTAB(:,1);
    dis = zeros(1,len);
    for i = 1:len
        [x1, x2, dis(i)]= cal_95(im_line_norm, ind(i), hlf_max(i));        
        plot(gca, [x1,x2], [hlf_max(i), hlf_max(i)], 'g-', 'LineWidth', 2.5);        
    end
    hold(gca,'off');
    beamstruc_out.F_beam_ind95(:,n) = dis(:);
    beamstruc_out.F_beam_indPekPos(:,n) = ind*camrel; % Individual bar peak positon 
    
    % Add current value in the figure;     
    annotation(gcf, 'textbox', [0.1302, 0.3746, 0.5000, 0.5000], 'String', ['Current: ', current_str, 'A'], 'LineStyle', 'none',...
        'Fontsize', 14);
    % In subplot 2 show the raw image
    ax2 = subplot(2,1,2);
    im = imagesc(ax2, img_xr, img_yr, im_data_crop); colorbar(ax2, 'east', 'color', 'w');
    ax2.XLim = im.XData; ax2.YLim = [im.YData(2), im.YData(1)];     
    xlabel(ax2, 'FAxis [mm]'); ylabel(ax2, 'SAxis [mm]');
    ax2.Position(3) = ax1.Position(3); 
    ax1.Position(4) = ax2.Position(4);
    ax1.Position(2) = 0.5;
    ax2.FontSize = 16;
    ax2.YDir = 'normal'; 
    ax1.XTick = [];
    
    saveas(fh_lnout, [dcb_sn_str, '_', 'lineout'], 'png');
    saveas(fh_lnout, [dcb_sn_str, '_', 'lineout'], 'fig');
    
    % Plot the individual bar 95% beam width.
    % This represents the smiling of each individual bar
    
    %hold(app.barFWHM_ax, 'on');
    ind95_data = round(beamstruc_out.F_beam_ind95(:,n)*camrel*1000,2);
    ind95_len = length(ind95_data);
    Hplt_barFW = plot(ax1_pkpos, 1:ind95_len, ind95_data, 'LineWidth', 3, 'Marker', 'o', 'MarkerSize', 8, ...
        'Color', line_color(n,:));
    set(ax1_pkpos, 'FontSize', 16,'XTick', 1:ind95_len, 'XTicklabel', []); 
    title(ax1_pkpos, 'Individual Bar Smiling', 'Interpreter', 'none');            
    % Subplot(2,1,2) to plot the relative distance change between each
    % individual peak
    pk_pos_um = ind*camrel*1000; % individual peak position in um
    pk_pos_rel = diff(pk_pos_um); % relative peak position difference in um
    pk_len = length(pk_pos_um);
    Hplt_pkpos = plot(ax2_pkpos, 2:pk_len, pk_pos_rel, 'LineWidth', 3, 'Marker', 'o', 'MarkerSize', 8, ...
        'Color', line_color(n,:));
    set(ax2_pkpos, 'FontSize', 16,'XTick', 1:pk_len, 'Xlim', [0, pk_len]); 
    ax1_pkpos.Position(4) = ax2_pkpos.Position(4);
    ax1_pkpos.Position(2) = 0.5;
    
    beamstruc_out.dcb{n} = dcb_sn_str; % Save all the dcb_sn_str
    end
    
    hold(ax1_pkpos, 'off'); hold(ax2_pkpos, 'off');
    
    ylabel(ax1_pkpos, 'Bar 95% Beam Width [\mum]');
    xlabel(ax2_pkpos, 'Bar Position')
    ylabel(ax2_pkpos, 'FAxis Peak Separation [\mum]');
    
    legend(ax1_pkpos, beamstruc_out.dcb(:), 'box', 'off', 'Location', 'northeast', 'NumColumns',3, 'Fontsize', 10);
    
    grid(ax1_pkpos, 'on'); grid(ax1_pkpos, 'minor');
    grid(ax2_pkpos, 'on'); grid(ax2_pkpos, 'minor');
    
    saveas(fh_pkpos, [dcb_sn_str, '_', 'pkpos'], 'png');
    saveas(fh_pkpos, [dcb_sn_str, '_', 'pkpos'], 'fig');
    
    % Add plot of FAxis 95% beam width in [mm]
    fh_95bwidth = figure('Name', '95% beam width', 'Color', 'w', 'Position', [2151, 8, 1198, 861]);    
    data = beamstruc_out.F_beam_wid;
    plot(gca, 1:length(data), data, 'LineWidth', 3, 'Marker', 's', 'MarkerSize', 10);
    ylabel('FAxis 95% Beam Width [mm]'); ytickformat('%.2f');
    set(gca, 'Xtick', 1:length(data), 'XTickLabel', beamstruc_out.dcb(:), 'FontSize', 16);
    grid on; grid minor;
    saveas(fh_95bwidth, 'Beam_width95%', 'png');
    saveas(fh_95bwidth, 'Beam_width95%', 'fig');
end


function [x1_inp, x2_inp, dis]= cal_95(vectr, ind, threld)
% THIS FUNCTION CAL_FWHM CALCULATE THE FWHM OF INPUT VECTOR
% vectr: Input vector;
% ind: position where to start searching
% threld: defined threshold where values are above.

x_cen = ind; % change x_cen from mm into px.
x1 = x_cen-1; % index of <x_cen
x2 = x_cen+1; % index of >x_cen

try
while true
    if vectr(x1) > threld
        x1 = x1-1;
    else 
        break;
    end
end

% use interpolation to calcualte the x value at threld
x_raise = x1:x_cen;
[y_rise, ia, ~] = unique(vectr(x_raise));
x_raise = x_raise(ia);

x1_inp = interp1(y_rise, x_raise, threld);


while true
    if vectr(x2) > threld
        x2 = x2 + 1; 
    else
        break;
    end
end

% use interpolation to calculate the x value at threld

x_fall = x_cen: x2;
[y_all, ia, ~] = unique(vectr(x_fall));
x_fall = x_fall(ia);

x2_inp = interp1(y_all, x_fall, threld);

dis = x2_inp - x1_inp; % width in pixel
catch
end
end