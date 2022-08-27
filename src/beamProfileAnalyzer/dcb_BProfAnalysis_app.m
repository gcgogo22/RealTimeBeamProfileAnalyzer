% This program analyze the dcb beam profile.
% 1) Calculate each bar smiling in px
% 2) Calculate relative distance between each bar.
% 3) Calculate the entire beam width. (95%)

img_fld = uigetdir('~', 'Select image folder');
full_name = fullfile(img_fld, '*.jpg');

if isempty(full_name)
    full_name = fullfile(img_fld, '*.png');
end
fl_names = ls(full_name);

camrel = app.cam_rel; % cam resolution in mm;
current = app.current;  % input the test current value

try
% Frist display an alert box to tell user to manually select the ROI box
crop_m = app.ManuallycroptheimageSwitch.Value;
if strcmpi(crop_m, 'Yes')
    uialert(app.ProdBeamAnalysisUIFigure, 'You select to manually choose image ROI', 'Info', 'Icon', 'warning');
end

[beamstruc_out] = fld_im_porcess(app, img_fld, fl_names, camrel, num2str(current));
save('BeamParameter', 'beamstruc_out');
close all;
catch Exp1
    disp(Exp1.message);
end
function [beamstruc_out] = fld_im_porcess(app, img_fld, fl_names, camrel, current_str)

% THIS FUNCTION ANALYZE THE IMAGES IN THE INPUT FOLDER
% Img_fld is the image folder directory
% Img_num is the total image number is the folder
    

    % Initilization
    % Initilize the FAxis beam centroid;
    try
    img_num = size(fl_names, 1);
    beamstruc_out.F_beam_cen = zeros(1,img_num); % Fast axis beam centroid in pixel
    beamstruc_out.F_beam_wid = zeros(1,img_num); % Fast axis 95% beam width in pixel
    
    beamstruc_out.emt_num = zeros(1,img_num); % Emitter number at differt current value
    beamstruc_out.F_beam_indFWHM = zeros(100, img_num); % Only for max 12 emitters
    beamstruc_out.F_beam_indPekPos = zeros(100, img_num); % Record the individual bar peak position
    beamstruc_out.F_beam_ind95 = zeros(100, img_num); % over 
    
    hold(app.bar_pkpos, 'on');
    hold(app.bar_beamwid, 'on');
    % Change to subfld direcotry and make processed folder
    cd(img_fld);
    if ~exist('Processed', 'dir')
        mkdir('Processed');
    end
    cd('Processed');
    
    % Generate plot line color
    line_color = linspecer(img_num);
  
    for n = 1: img_num

    % Check flag value and determine whether continuing the loop
    img_file = fullfile(img_fld, fl_names(n,:)); % Save image files with current value
    img_full_flname = img_file;
    im_data = imread(img_full_flname);
    
    dcb_sn_str = strsplit(fl_names(n,:), '_');
    dcb_sn_str = dcb_sn_str{1};
    
    %1) show the raw image and plot roi on top of it.
    flg = app.RotateImageby90DegreeSwitch.Value;
        if strcmpi(flg, 'Yes')
            im_data = rot90(im_data); 
        end
    % Define x, y range    
    img_x = [0, camrel*size(im_data,2)];
    img_y = [0, camrel*size(im_data,1)]; % FOV in mm
    imagesc(app.dcb_roi,img_x, img_y, im_data); hold(app.dcb_roi, 'on');
    
    axis(app.dcb_roi, 'tight');
    hold(app.dcb_roi, 'off');
    text(app.dcb_roi, 455*camrel, 120*camrel, 'ROI', 'FontSize', 16, 'FontWeight', 'b', 'Color', 'w');
    xlabel(app.dcb_roi, 'FAxis Pos [mm]');
    ylabel(app.dcb_roi, 'SAxis Pos [mm]');
    title(app.dcb_roi, [app.module_name, ' ', dcb_sn_str], 'Interpreter', 'none');
    
    % Check the flag of mannually crop image
    flg_m = app.ManuallycroptheimageSwitch.Value;
    if strcmpi(flg_m, 'Yes')
        h = drawrectangle(app.dcb_roi, 'Color', 'w');
        roi_pos = round(h.Position./camrel);
    else
        roi_pos = [169, 160, 648, 400];
    end
    rectangle(app.dcb_roi, 'Position', roi_pos*camrel, 'LineWidth', 2, 'EdgeColor', 'c');
    %2) calculate each bar smiling
    im_data_crop = im_data(roi_pos(2):roi_pos(2) + roi_pos(4), roi_pos(1): roi_pos(1)+roi_pos(3));
    im_bw = imbinarize(im_data_crop, 'global');    
    se = strel('square', 4);
    im_cl = imclose(im_bw, se); % connect split dots on the edge 
    se = strel('square', 2);
    im_out = imopen(im_cl, se); % remove the small pixels
    img_xr = [0, camrel*size(im_out,2)];
    img_yr = [0, camrel*size(im_out,1)]; % FOV in mm
    
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
    ax1 = app.beam_lineout_ax_1;
    
    plot(ax1, im_line_norm, 'LineWidth', 3, 'DisplayName', 'FAxis Lineout'); 
    hold(ax1,'on'); plot(ax1, MAXTAB(:,1), MAXTAB(:,2), 'ro', 'LineWidth', 3, 'MarkerSize', 10);
    % Plot the position of the 95% beam width.
    plot(ax1, [x_width_px(1), x_width_px(1)], [0,1], 'k-.', 'LineWidth', 3);
    plot(ax1, [x_width_px(2), x_width_px(2)], [0,1], 'k-.', 'LineWidth', 3);
    title(ax1,[dcb_sn_str, ' Bar Num: ', num2str(beamstruc_out.emt_num(n))]);
    axis(ax1,'tight');
    set(ax1,'fontsize', 16);
    
    % Calculat the individual bar 95% width in the fast axis direction
    hlf_max = 0.05*MAXTAB(:,2); % clculate 95% beam width and use it as smling calibration
    len = numel(hlf_max);
    ind = MAXTAB(:,1);
    dis = zeros(1,len);
    for i = 1:len
        [x1, x2, dis(i)]= cal_95(im_line_norm, ind(i), hlf_max(i));        
        plot(ax1, [x1,x2], [hlf_max(i), hlf_max(i)], 'g-', 'LineWidth', 2.5);        
    end
    hold(ax1,'off');
    
    beamstruc_out.F_beam_ind95(1:length(dis),n) = dis(:);
    beamstruc_out.F_beam_indPekPos(1:length(ind),n) = ind*camrel; % Individual bar peak positon 
    
    
    % In subplot 2 show the raw image
    ax2 = app.beam_lineout_ax_2;
    im = imagesc(ax2, img_xr, img_yr, im_data_crop); colorbar(ax2, 'east', 'color', 'w');
    ax2.XLim = im.XData; ax2.YLim = im.YData;     
    xlabel(ax2,'FAxis [mm]'); ylabel(ax2, 'SAxis [mm]');
    ax2.Position(3) = ax1.Position(3); 
    ax1.Position(4) = ax2.Position(4);
    ax2.FontSize = 16;
    ax1.XTick = [];
    ytickformat(ax1,'%0.1f');
    ytickformat(ax2,'%0.1f'); % Set the same tick format to align the images.
    % Add current value in the figure;     
    text(ax1,0,ax1.YLim(2)*1.04, ['Current: ', current_str, 'A'], 'LineStyle', 'none',...
        'Fontsize', 14, 'Color', 'k');
    % Plot the individual bar 95% beam width.
    % This represents the smiling of each individual bar
  
    ind95_data = round(beamstruc_out.F_beam_ind95(1:length(dis),n)*camrel*1000,2);
    ind95_len = length(ind95_data);
    Hplt_barFW = plot(app.bar_beamwid, 1:ind95_len, ind95_data, 'LineWidth', 3, 'Marker', 'o', 'MarkerSize', 8, ...
        'Color', line_color(n,:), 'DisplayName', dcb_sn_str);
    set(app.bar_beamwid, 'FontSize', 16,'XTick', 1:ind95_len, 'XTicklabel', []); 
                
    % Subplot(2,1,2) to plot the relative distance change between each
    % individual peak
    pk_pos_um = ind*camrel*1000; % individual peak position in um
    pk_pos_rel = diff(pk_pos_um); % relative peak position difference in um
    pk_len = length(pk_pos_um);
    Hplt_pkpos = plot(app.bar_pkpos, 2:pk_len, pk_pos_rel, 'LineWidth', 3, 'Marker', 'o', 'MarkerSize', 8, ...
        'Color', line_color(n,:));
    set(app.bar_pkpos, 'FontSize', 16,'XTick', 1:pk_len);
    ytickformat(app.bar_beamwid, '%-4.0f');
    ytickformat(app.bar_pkpos, '%-4.0f');
    app.bar_beamwid.Position(4) = app.bar_pkpos.Position(4);
    
    legend(app.bar_beamwid, 'box', 'off', 'Location', 'southoutside', 'NumColumns',6, 'Fontsize', 8);
    beamstruc_out.dcb{n} = dcb_sn_str; % Save all the dcb_sn_str
    app.bar_pkpos.XLim = app.bar_beamwid.XLim;
        if ~app.end_flg && n < img_num
                uiwait(app.ProdBeamAnalysisUIFigure);
        elseif n == img_num
            uialert(app.ProdBeamAnalysisUIFigure, 'The last image!', 'Info'); 
        else
        end
    end
    
    hold(app.bar_beamwid, 'off'); hold(app.bar_pkpos, 'off');
    
    ylabel(app.bar_beamwid, 'Bar 95% Beam Width [\mum]');
    xlabel(app.bar_pkpos, 'Bar Position')
    ylabel(app.bar_pkpos, 'FAxis Peak Separation [\mum]');
    
    grid(app.bar_beamwid, 'on'); grid(app.bar_beamwid, 'minor');
    grid(app.bar_pkpos, 'on'); grid(app.bar_pkpos, 'minor');
        
    
    % Add plot of FAxis 95% beam width in [mm]   
    data = beamstruc_out.F_beam_wid;
    plot(app.beamwid, 1:length(data), data, 'LineWidth', 3, 'Marker', 's', 'MarkerSize', 10);
    ylabel(app.beamwid, 'FAxis 95% Beam Width [mm]'); ytickformat(app.beamwid, '%.2f');
    set(app.beamwid, 'Xtick', 1:length(data), 'XTickLabel', beamstruc_out.dcb(:), 'FontSize', 16, 'XTickLabelRotation', 45);
    grid(app.beamwid, 'on'); grid(app.beamwid, 'minor');
    catch Exp2
        disp(Exp2.message);
    end
    
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
    if vectr(x1) > threld && x1>1
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
    if vectr(x2) > threld && x2<numel(vectr)
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

if isnan(x1_inp)
    x1_inp = x1; % check interpolation, if nan then assign the boundary condition
end

if isnan(x2_inp)
    x2_inp = x2;
end

dis = x2_inp - x1_inp; % width in pixel
catch Exp3
    disp(Exp3.message);
end
end