% This .m file select the image folders decide from user whether to rotate 
% the image by 90 and analyze the result.

% Change in the fast and slow axis directioins at different current values.
fld_dir = uigetdir('~', 'Select Image Folder Directory');
patt_ind = strfind(fld_dir,'\');
mod_name = app.ModuleNameEditField.Value;
plt_title = [mod_name, '_', fld_dir(patt_ind(end)+1:end)];
% Find all the flds in this folder directory

bar_num = app.bar_num;
test_proj = app.module_name;
ob_dis = app.obj_dis;

% Extract current value
cd(fld_dir);
curr_files = ls('*.png');
curr_files_cell = mat2cell(curr_files, ones(size(curr_files,1),1), size(curr_files,2));
splitfcn = @(x) strsplit(x,'.');
temp = cellfun(splitfcn, curr_files_cell, 'UniformOutput', false);
temp = vertcat(temp{:});
curr_col_db = sort(cellfun(@str2double,temp(:,1)));

% Camera resolution
camrel = app.cam_rel; % mm/px
% Store the beamstruct_out data
bmData = struct();
[beamstruc_out] = fld_im_porcess(fld_dir, curr_col_db, bar_num, camrel, app, plt_title);
% Save data; 
cd('Processed');
bmData.(['M', plt_title]) = beamstruc_out;
save('BmOutputData', 'bmData');
cd ..;

% Plot the FAxis centroid shift and 95% beam width
cen_bw_plt(bmData, camrel, curr_col_db, plt_title, ob_dis, app); % Plot the centroid shift(um) and beam width (mm)
 
 
 % Plot the relative drift of each bar position in the module at different
 % current
%  for i = 1: len
%     name = fieldnames(bmData); 
%     pekData = bmData.(name{i}).F_beam_indPekPos;
%     module_name = name{i}(2:end);
%     Hfig_pek = ind_PekPositon(pekData, curr_col_db, ob_dis, module_name);
%     
%     % Save figures;     
%     saveas(Hfig_pek, [module_name, '_PekPos'], 'png');
%     saveas(Hfig_pek, [module_name, '_PekPos'], 'fig');
% end
 
 % Plot individual bar peak position drift at different current
 function Hfig_pek = ind_PekPositon(pekData, curr_col_db, ob_dis, module_name)
    pekData = (pekData - pekData(:,1))*1000/ob_dis; % Calculate relative peak positon shift in mrad
    line_num = size(pekData,1); ln_color_pek = linspecer(line_num);
    
    Hfig_pek = figure('Position', [2165 102 930 773]);
    Hplt_pek = plot(curr_col_db, pekData', 'LineWidth', 1.5,...
        'LineStyle', '-.', 'Marker', 's', 'MarkerSize', 8); 
    
    set(gca,'FontSize',16); xlabel('Current[A]'); ylabel('FAxis Bar Peak Position Drift[mrad]');
    title(module_name, 'Interpreter', 'none');
    
    % Set plot line color
    set(Hplt_pek, {'Color'},mat2cell(ln_color_pek, ones(1,line_num), size(ln_color_pek, 2)));
    
    leg = cell(1,line_num);
    for i = 1:line_num
        leg{i} = ['Bar_', num2str(i)]; % Bar position is from left to right
    end
    legend(leg,'box','off', 'FontSize', 8, 'Interpreter', 'none', 'Location', 'eastoutside');
   
 end
 
 function cen_bw_plt(bmData, camrel, curr_col_db, fig_title, ob_dis, app) 
 % Plot the FAxis relative centorid shift in um and FAxis 95% beam width in
 % mm
 % bmData is a struct data for input
 % camrel is the camera resolution
 
 ax_cen = app.beam_centroid_ax; ax_wid = app.beam_width_ax;
 
 flname_lv1 = fieldnames(bmData);
 len = length(flname_lv1);
 for i = 1:len
    name = flname_lv1{i}; name = name(2:end);
    data = bmData.(flname_lv1{i});
    data_cen = data.F_beam_cen;
        data_cen = data_cen- data_cen(1); % Calcuatle the relative shift in px
        data_cen = data_cen*camrel*1000; % Change px to um unit
        data_cen = data_cen/ob_dis; % Divide by objective distance[mm] and change to mrad
    data_wid = data.F_beam_wid;        
        data_wid = data_wid*camrel; % Change px to mm unit
    plot(ax_cen, curr_col_db, data_cen, 'LineWidth', 3,'Marker', 'o','MarkerSize', 8, 'DisplayName', name);
    set(ax_cen, 'XTick', curr_col_db, 'XTickLabel', []);
    
    title(ax_cen, fig_title, 'Interpreter', 'none');
    legend(ax_cen, 'box', 'off', 'interpreter', 'none');
    
    plot(ax_wid, curr_col_db, data_wid, 'LineWidth', 3, 'Marker', '^', 'MarkerSize', 8, 'DisplayName', name);
    set(ax_wid, 'FontSize', 16, 'XTick', curr_col_db), ylabel(ax_wid, 'FAxis 95% Beam Width [mm]'); ...
        xlabel(ax_wid,'Current [A]');
 end
    % Turn on the grid
    grid(ax_wid, 'on'); grid(ax_wid, 'minor');
    grid(ax_cen, 'on'); grid(ax_cen, 'minor');
 end
 
function [beamstruc_out] = fld_im_porcess(img_fld, curr_col_db, bar_num, camrel, app, plt_title)

% THIS FUNCTION ANALYZE THE IMAGES IN THE INPUT FOLDER
% Img_fld is the image folder directory
% Subfld is the sub-folder directory
% Img_num is the total image number is the folder


    % Initilization
    % Initilize the FAxis beam centroid;
    img_num = length(curr_col_db);
    beamstruc_out.F_beam_cen = zeros(1,img_num); % Fast axis beam centroid in pixel
    beamstruc_out.F_beam_wid = zeros(1,img_num); % Fast axis 95% beam width in pixel
    
    beamstruc_out.emt_num = zeros(1,img_num); % Emitter number at differt current value
    beamstruc_out.F_beam_indFWHM = zeros(bar_num, img_num); % Only for max 12 emitters
    beamstruc_out.F_beam_indPekPos = zeros(bar_num, img_num); % Record the individual bar peak position
    % Change to subfld direcotry and make processed folder
    cd(img_fld);
    mkdir('Processed');
    
    for n = 1: img_num

    img_file = [num2str(curr_col_db(n)), '.png']; % Save image files with current value
    img_full_flname = img_file;

    im_data = imread(img_full_flname);
    flg = app.RotateImageby90DegreeSwitch.Value;
    if strcmpi(flg, 'Yes')
        im_data = rot90(im_data); 
    end
    % Define image X, Y ragne. 
    img_xr = [0, camrel*size(im_data,2)];
    img_yr = [camrel*size(im_data,1), 0]; % FOV in mm
    % Plot the lineout in the center along the fast axis direction. 
    % Plot box width 51 px
    % wd = 50; Y_cen = size(im_data,1)/2; Y_top = Y_cen - wd/2; Y_bot = Y_cen + wd/2;
    im_roi = im_data; % Important: select ROI for the full image data. Because in slow axis, there is beam drift. 
    % If you don't cover the entire beam, this drift will affect the centroid calculation in the fast axis direction in a defined ROI box. 
    im_line_norm = sum(im_roi,1)./max(sum(im_roi,1));

    % Calculate how many emitters are left
    [MAXTAB, ~] = peakdet(im_line_norm, 0.2); % Set threshold of 20% maximum
    beamstruc_out.emt_num(n) = size(MAXTAB, 1); % Detect emitter number;
    
    % Define the subplots
    ax1 = app.beam_lineout_ax_1; ax2 = app.beam_lineout_ax_2; 
    plot(ax1, im_line_norm, 'LineWidth', 3, 'DisplayName', 'FAxis Lineout'); 
    hold(ax1,'on'); plot(ax1, MAXTAB(:,1), MAXTAB(:,2), 'ro', 'LineWidth', 3, 'MarkerSize', 10);
    title(ax1,['Bar Num: ', num2str(beamstruc_out.emt_num(n))]);
    axis(ax1,'tight');
    

    % Calculate the total beam centroid position
    loc = 1:1:length(im_line_norm);
    beam_cen = sum(im_line_norm.*loc)./sum(im_line_norm);
    plot(ax1, [beam_cen, beam_cen], [0,1], 'r-.', 'LineWidth', 2); 
    beamstruc_out.F_beam_cen(n) = beam_cen;

    % Calculate the total beam width in the FAxis direction
    int_cum = cumsum(im_line_norm);
    wid_lf = int_cum(end)*2.5/100;
    wid_rt = int_cum(end)*97.5/100;

    [int_cum_fil,ia,~] = unique(int_cum);
    wid_lf_x = interp1(int_cum_fil,ia,wid_lf);
    wid_rt_x = interp1(int_cum_fil,ia,wid_rt);
    beamstruc_out.F_beam_wid(n) = wid_rt_x - wid_lf_x; % 95% beam width in px

    
    % Calculat the individual bar width FWHM in the fast axis direction
    hlf_max = 0.5*MAXTAB(:,2);
    len = numel(hlf_max);
    ind = MAXTAB(:,1);
    dis = zeros(1,len);
    for i = 1:len
        [x1, x2, dis(i)]= cal_FWHM(im_line_norm, ind(i), hlf_max(i));        
        plot(ax1, [x1,x2], im_line_norm([x1, x1]), 'g-', 'LineWidth', 2.5);        
    end
    hold(ax1,'off');
    beamstruc_out.F_beam_indFWHM(:,n) = dis(:);
    beamstruc_out.F_beam_indPekPos(:,n) = ind*camrel; % Individual bar peak positon 
    legend(ax1,plt_title, 'Interpreter', 'none', 'box', 'off'); % Label module number
    % Add current value in the figure;
    text(ax1, 60, 0.9, ['Current: ', num2str(curr_col_db(n)), 'A'], 'FontSize', 16); 
    % In subplot 2 show the raw image
    im = imagesc(ax2, img_xr, img_yr, im_data); colorbar(ax2, 'east', 'color', 'w');
    ax2.XLim = im.XData; ax2.YLim = [im.YData(2), im.YData(1)];
    title(ax2, [plt_title, ' Beam Profile'], 'Interpreter', 'none'); 
    xlabel(ax2, 'FAxis [mm]'); ylabel(ax2, 'SAxis [mm]');
    ax2.Position(3) = ax1.Position(3); ax2.FontSize = 16;
    ax2.YDir = 'normal'; 
    ax1.XLabel.Visible = 'off'; 
    % Label the centroid positon in the ax1 X axis
    ax1.XTick = beam_cen;
    ax1.XTickLabel = ['Beam Centroid: ',num2str(beam_cen*camrel,'%.2f'), 'mm'];
    
    % Create a new figure to plot the individual bar FWHM
    ln_color_FW = linspecer(size(beamstruc_out.F_beam_indFWHM, 2));
    hold(app.barFWHM_ax, 'on');
    FWHM_data = round(beamstruc_out.F_beam_indFWHM(:,n)*camrel*1000,0);
    FWHM_len = length(FWHM_data);
    
    Hplt_barFW = plot(app.barFWHM_ax, 1:FWHM_len, FWHM_data, 'LineWidth', 3, 'Marker', 'o', 'MarkerSize', 8);
    set(Hplt_barFW, 'Color', ln_color_FW(n,:));
    set(app.barFWHM_ax, 'FontSize', 16,'XTick', 1:FWHM_len); xlabel(app.barFWHM_ax, 'Bar Position'),...
    ylabel(app.barFWHM_ax, 'Bar FWHM [\mum]');

    leg = num2cell(curr_col_db);
    fcn_hd = @(x) [num2str(x), 'A'];
    leg = cellfun(fcn_hd, leg, 'UniformOutput', false);
    legend(app.barFWHM_ax, leg, 'box', 'off', 'Location', 'northoutside', 'NumColumns',3);
    title(app.barFWHM_ax, plt_title, 'Interpreter', 'none');    
        if n == img_num && ~app.end_flg
            % if n is the last image, send information to message box
            uialert(app.BeamCentroidWidthUIFigure, 'Last Image!','Info','Icon', 'success');            
        elseif ~app.end_flg
            uiwait(app.BeamCentroidWidthUIFigure);
        else
        end
    end
    hold(app.barFWHM_ax,'off');
    grid(app.barFWHM_ax, 'on'); grid(app.barFWHM_ax, 'minor');
end


function [x1, x2, dis]= cal_FWHM(vectr, ind, threld)
% THIS FUNCTION CAL_FWHM CALCULATE THE FWHM OF INPUT VECTOR
% vectr: Input vector;
% ind: position where to start searching
% threld: defined threshold where values are above.

x_cen = ind; % change x_cen from mm into px.
x1 = x_cen-1; % index of <x_cen
x2 = x_cen+1; % index of >x_cen

while true
    if vectr(x1) > threld
        x1 = x1-1;
    else 
        break;
    end
end

threld_lf = vectr(x1);

while true
    if vectr(x2) > threld_lf
        x2 = x2 + 1; 
    else
        break;
    end
end

dis = x2 - x1; % FWHM in pixel
end