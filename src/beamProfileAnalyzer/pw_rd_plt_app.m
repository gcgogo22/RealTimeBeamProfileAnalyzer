% This script reads in the power and voltage file and plot the data.
[file_name,fld_dir] = uigetfile('*', 'Select Power Measurement');
full_file_name = fullfile(fld_dir,file_name);
pw_data = readtable(full_file_name);

% Extract current value.
curr_col = pw_data{:,1};
ind = cellfun(@isempty, curr_col); ind = find(ind == 1)-1;
curr_col_db = cellfun(@str2double, curr_col(2:ind));

% Change second column from cell to double
temp = cellfun(@str2double, pw_data{:,2});
% Extract power matrix
mod_num = size(pw_data,2)-1;
pw_mat = [temp(2:ind), pw_data{2:ind, 3:end}];

% Extract voltage matrix
vol_mat = [temp(ind+2: end), pw_data{ind+2: end, 3:end}];

% Plt the power and voltage data
ln_color = linspecer(mod_num);
leg = pw_data.Properties.VariableNames(2:end);
leg_pw = strcat(leg(:), {'_Power'});
leg_vol= strcat(leg(:), {'_Vol'});
leg_cm = [leg_pw; leg_vol];
% Reset ax property before plotting
cla(app.pw_vol_ax, 'reset');

yyaxis(app.pw_vol_ax, 'left'); hp1 = plot(app.pw_vol_ax, curr_col_db, pw_mat, 'LineWidth', 3, 'LineStyle', '-');
set(hp1, {'Color'}, mat2cell(ln_color, ones(1,mod_num), size(ln_color, 2)));
set(app.pw_vol_ax, 'FontSize', 16, 'Ycolor', 'k');
ylabel(app.pw_vol_ax,'Power(W)');
yyaxis(app.pw_vol_ax, 'right'); hp2 = plot(app.pw_vol_ax,curr_col_db, vol_mat, 'LineWidth', 3, 'LineStyle', '-.'); 
set(hp2, {'Color'}, mat2cell(ln_color, ones(1,mod_num), size(ln_color, 2)));
set(app.pw_vol_ax, 'Ylim', [16, 30], 'FontSize', 16, 'Ycolor', 'k');
ylabel(app.pw_vol_ax, 'Voltage(V)');

title(app.pw_vol_ax,pw_data.Properties.VariableNames(1));
xlabel(app.pw_vol_ax,'Current(A)');
grid(app.pw_vol_ax,'on'); grid(app.pw_vol_ax,'minor');
legend(app.pw_vol_ax, leg_cm, 'Location', 'Northwest', 'Box', 'off', 'Interpreter', 'none');

