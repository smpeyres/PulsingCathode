% identify the operating quadrant for chloroacetate in either aqueous or
% ethylene glycol solutions
clear all;

%% Prompt user for solvent
promptSolvent = 'Select solvent ("water"/"aqueous" or "ethylene glycol"): ';
userSolvent = strtrim(lower(input(promptSolvent,'s')));

% Identify solvent from user input, define intrinsic parameters
if any(strcmp(userSolvent,{'water','aqueous'}))
    solventCode = 1;
    % pseudo-second order: 2e- + 2H2O -> 2OH- + H2
    k2 = 5.5e6; % m^3/mol-s
    % e- + ClCH2CO2- -> Cl- + CH2CO2-
    ks = 1.5e6; % m^3/mol-s
    % e- diffusivity
    De = 4.9e-9; % m^2/s
    % ClCH2CO2- diffusivity
    Ds = 1.1e-9; % m^2/s
elseif any(strcmp(userSolvent,{'eg','ethylene glycol','ethyleneglycol'}))
    solventCode = 2;
    % pseudo-first order: e- + HOCH2CH2OH -> HOCH2CH2O- + H
    k1 = 4.4e5; % 1/s
    % e- + ClCH2CO2- -> Cl- + CH2CO2-
    ks = 1.8e5; % m^3/mol-s
    % e- diffusivity
    De = 7.2e-10; % m^2/s
    % ClCH2CO2- diffusivity
    Ds = 6.4e-11; % m^2/s
else
    error('Invalid solvent selection. Enter "water"/"aqueous" or "ethylene glycol".')
end

%% Prompt user for operation conditions

% Prompt user for peak current (mA) and store as floating-point number
promptCurrent = 'Please enter the peak current (mA): ';
userPeakCurrent = str2double(strtrim(input(promptCurrent,'s')));
if isnan(userPeakCurrent)
    error('Invalid numeric input for peak current.');
end
% Convert to standard units
peakCurrent = 1e-3*userPeakCurrent; % mA to A

% Prompt user for plasma-liquid interfacial area (mm^2)
promptArea = 'Please enter the plasma-liquid interfacial area (mm^2): ';
userInterfacialArea = str2double(strtrim(input(promptArea,'s')));
if isnan(userInterfacialArea)
    error('Invalid numeric input for interfacial area.');
end
% Convert to standard units
interfacialArea = 1e-6*userInterfacialArea; % mm^2 to m^2

% Prompt user for duty cycle (%):
promptDuty = 'Please enter the duty cycle (%): ';
userDutyCycle = str2double(strtrim(input(promptDuty,'s')));
if isnan(userDutyCycle)
    error('Invalid numeric input for duty cycle.');
end
% Convert to standard units
dutyCycle = 1e-2*userDutyCycle; % percent to fraction

% Prompt user for frequency (Hz):
promptFreq = 'Please enter the frequency (Hz): ';
userFrequency = str2double(strtrim(input(promptFreq,'s')));
if isnan(userFrequency)
    error('Invalid numeric input for frequency.');
end
% No need to change units, just change name
frequency = userFrequency; % Hz = 1/s

% Prompt user for chloroacetate concentration (mM):
promptConc = 'Please enter the initial chloroacetate (ClCH2CO2-) concentration: ';
userInitConc = str2double(strtrim(input(promptConc,'s')));
if isnan(userInitConc)
    error('Invalid numeric input for initial concentration.');
end
% Just change name
initConc = userInitConc; % mM = mol/m^3

% Prompt user for film thickness
promptDelta = 'Please enter your assumed film thickness (um): ';
userDelta = str2double(strtrim(input(promptDelta,'s')));
if isnan(userDelta)
    error('Invalid numeric input for film thickness/delta.');
end
delta = 1e-6*userDelta; % um to m

%% Calculate lumped recombination coefficient, kr (1/s)

faradayConst = 96485; % C/mol

% Calculate value based on selected solvent
if solventCode == 1
    num = (k2^2)*(peakCurrent^2);
    den = (interfacialArea^2)*(faradayConst^2)*De;
    kr = (num/den)^(1/3); % for aqueous
else
    kr = k1; % For ethylene glycol
end

%% Determine whether concentration is above kinetic threshold, below transport threshold

kineticThreshold = kr/ks;
transportThreshold = peakCurrent*delta/(interfacialArea*faradayConst*Ds);

if and(initConc > kineticThreshold, initConc < transportThreshold)
    disp('Concentration is above kinetic threshold and below transport threshold. Proceeding with calculations...');
elseif initConc <= kineticThreshold
    disp('Concentration is at or below kinetic threshold. Ending calculation. Please adjust parameters.');
    return;
else
    disp('Concenctration is at or above transport threshold. Ending calculation. Please adjust parameters.');
    return;
end

%% Calculate pulse times

onTime = dutyCycle/frequency;

thresholdTime = 0.25*pi*(faradayConst^2)*(interfacialArea^2)*Ds*(peakCurrent^(-2))*((initConc - kineticThreshold)^2);

timeRatio = thresholdTime/onTime;

%% Calculate regimes
if and(timeRatio > 1, dutyCycle < 0.5)
    disp('System is in under-react, over-recover regime. Excellent!');
elseif and(timeRatio > 1, dutyCycle == 0.5)
    disp('System is in under-react, adequate recovery regime. Nice!');
elseif and(timeRatio == 1.0, dutyCycle < 0.5)
    disp('System is in adequate reaction, over-recover regime. Nice!');
elseif and(timeRatio < 1, dutyCycle > 0.5)
    disp('System is in under-react, under-recover regime. Not bad, consider adjusting parameters.')
elseif and(timeRatio < 1, dutyCycle < 0.5)
    disp('System is in over-react, over-recover regime. Not bad, consider adjusting parameters.')
elseif and(timeRatio <= 1, dutyCycle >= 0.5)
    disp('System is in over-react, under-recover regime. Not good, please adjust parameters.')
else
    disp('Regime not identified.')
end

%% Calculate the DC instantaneous Faradaic Efficiency

% prompt user if this calculation should be done
promptDCFESolve = 'Would you like to calculate the instantaneous FE for the analogous DC condition? (Y/N): ';
userDCFEYN = strtrim(input(promptDCFESolve,'s'));
if any(strcmp(userDCFEYN,{'yes','Y','Yes','y'}))
    % Calculate FE using interpolation from scaling law paper
    Ha = kr*(delta^2)/De;
    flux = peakCurrent/(interfacialArea*faradayConst);
    Da = ks*flux*(delta^3)/(Ds*De);
    Omega = ks*initConc/kr;
    if Da/Ha < 1
        alpha = 1;
    else
        alpha = 1 + log10(Da/Ha);
    end
    eta = (((1/Omega)*(1 + (Da/Ha)))^alpha + 1)^(-1/alpha);
    DCFE = 1e2*eta;
    disp(['Calculated instantaneous FE for DC at same peak current (1 um film thickness): ', num2str(DCFE), ' %']);
elseif any(strcmp(userDCFEYN,{'no','N','No','n'}))
    disp('Calculation of instantaneous FE for DC not requested,')
else
    error('Invalid Y/N selection.')
end

