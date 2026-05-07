clear all; close all; clc;

% ====================== PATH ======================
P = '.\Electrical\5_07';
S = dir(fullfile(P, '*.csv'));
numFiles = numel(S);

fprintf('Processing %d CSV files...\n\n', numFiles);

% ====================== PREALLOCATE ======================
Results = NaN(numFiles, 5);      % [Freq_Hz, Duty_%, Set_mA, Avg_Whole_mA, Avg_ON_mA]
FileNames = strings(numFiles, 1);

% ====================== MAIN LOOP ======================
for k = 1:numFiles
    filename = S(k).name;
    filepath = fullfile(P, filename);
    FileNames(k) = filename;
    
    fprintf('(%d/%d) %s\n', k, numFiles, filename);

    % ---------- 1. Parse filename ----------
    freq = NaN; 
    duty = NaN; 
    set_current = NaN;
    
    % ----- Frequency (Hz + kHz robust) -----
    freq_match = regexp(filename, '(\d+\.?\d*)\s*(k)?\s*Hz', 'tokens', 'ignorecase');
    if ~isempty(freq_match)
        tokens = freq_match{1};
        val = str2double(tokens{1});
        
        if numel(tokens) >= 2 && ~isempty(tokens{2})
            freq = val * 1000;  % kHz → Hz
        else
            freq = val;
        end
    end
    
    % ----- Duty (%) -----
    duty_match = regexp(filename, '(\d+)\s*%', 'tokens');
    if ~isempty(duty_match)
        duty = str2double(duty_match{1}{1});
    end
    
    % ----- Set current (mA) -----
    current_match = regexp(filename, '(\d+\.?\d*)\s*mA', 'tokens', 'ignorecase');
    if ~isempty(current_match)
        set_current = str2double(current_match{1}{1});
    end

    % ---------- 2. Read data ----------
    try
        data = readmatrix(filepath, 'NumHeaderLines', 1);
    catch
        warning('Failed to read %s', filename);
        continue;
    end
    
    if size(data, 2) < 3
        warning('Skipping %s (not enough columns)', filename);
        continue;
    end

    % ---------- 3. Compute currents ----------
    shuntResistance = 100; % kOhm
    Current = -data(:,3) / shuntResistance;   % Convert to mA
    Avg_Whole = mean(Current, 'omitnan');

    % ---------- ON-TIME AVERAGE (NEW METHOD) ----------
    on_current = Current(Current > 2);   % define ON region
    
    if numel(on_current) >= 10
        
        % Step 1: average over ON region
        mean_on = mean(on_current);
        
        % Step 2: optional ±50% filtering
        lower = mean_on * 0.50;
        upper = mean_on * 1.50;
        
        clean_values = on_current(on_current >= lower & on_current <= upper);
        
        % Step 3: final value
        if numel(clean_values) >= 8
            Avg_Peak = mean(clean_values);
        else
            Avg_Peak = mean_on;
            disp("Improve x-axis resolution - capture fewer pulses.")
        end
    else
        Avg_Peak = NaN;
    end

    % ---------- 4. Store ----------
    Results(k,:) = [freq, duty, set_current, Avg_Whole, Avg_Peak];
end

% ====================== DERIVED METRICS ======================
Freq_Hz = Results(:,1);
Duty = Results(:,2);
Set_mA = Results(:,3);
AvgWhole = Results(:,4);
AvgPeak = Results(:,5);

% Theoretical peak current
TheoPeak = NaN(numFiles,1);
valid_idx = Duty > 0;
TheoPeak(valid_idx) = Set_mA(valid_idx) ./ (Duty(valid_idx)/100);

% ====================== BUILD TABLE ======================
T = table(FileNames, Freq_Hz, Duty, Set_mA, AvgWhole, AvgPeak, TheoPeak, ...
    'VariableNames', {'Filename','Frequency_Hz','Duty_Percent','Set_Current_mA', ...
                      'Avg_Whole_mA','Avg_ON_mA','Theoretical_Peak_mA'});

T = sortrows(T, {'Set_Current_mA','Frequency_Hz','Duty_Percent'});

% ---------- ROUND ----------
T.Frequency_Hz        = round(T.Frequency_Hz);
T.Duty_Percent        = round(T.Duty_Percent);
T.Set_Current_mA      = round(T.Set_Current_mA, 2);
T.Avg_Whole_mA        = round(T.Avg_Whole_mA, 4);
T.Avg_ON_mA           = round(T.Avg_ON_mA, 4);
T.Theoretical_Peak_mA = round(T.Theoretical_Peak_mA, 4);

% ====================== PRINT ======================
fprintf('\n=== Pulsing Analysis Results ===\n\n');
fprintf('%-30s %8s %8s %10s %15s %15s %15s\n', ...
    'Filename','Freq(Hz)','Duty(%)','Set_mA','Avg_Whole','Avg_ON','Theo_Peak');
fprintf('%s\n', repmat('-',1,115));

for i = 1:height(T)
    fprintf('%-30s %8.0f %8.0f %10.1f %15.1f %15.1f %15.1f\n', ...
        T.Filename(i), ...
        T.Frequency_Hz(i), ...
        T.Duty_Percent(i), ...
        T.Set_Current_mA(i), ...
        T.Avg_Whole_mA(i), ...
        T.Avg_ON_mA(i), ...
        T.Theoretical_Peak_mA(i));
end

% ====================== SAVE ======================
writetable(T, fullfile(P, 'Pulsing_Analysis_Results.xlsx'));
save(fullfile(P, 'Pulsing_Analysis_Results.mat'), 'Results', 'FileNames', 'T');

fprintf('\nDone. Results saved to Pulsing_Analysis_Results.xlsx and .mat\n');