% identify the operating quadrant for chloroacetate in either aqueous or
% ethylene glycol solutions
clear all;

%% Prompt user for solvent
promptSolvent = 'Select solvent ("water"/"aqueous" or "ethylene glycol"): ';
userSolvent = strtrim(lower(input(promptSolvent,'s')));

% Identify solvent from user input, define intrinsic parameters
if any(strcmp(userSolvent,{'w','water','aqueous'}))
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
if not(userPeakCurrent > 0)
    error('Invalid numeric input for peak current.');
end
% Convert to standard units
peakCurrent = 1e-3*userPeakCurrent; % mA to A

% Prompt user for plasma-liquid interfacial area (mm^2)
promptArea = 'Please enter the plasma-liquid interfacial area (mm^2): ';
userInterfacialArea = str2double(strtrim(input(promptArea,'s')));
if not(userInterfacialArea > 0)
    error('Invalid numeric input for interfacial area.');
end
% Convert to standard units
interfacialArea = 1e-6*userInterfacialArea; % mm^2 to m^2

% Prompt user for duty cycle (%):
promptDuty = 'Please enter the duty cycle (%): ';
userDutyCycle = str2double(strtrim(input(promptDuty,'s')));
if not(and(userDutyCycle > 0, userDutyCycle < 100))
    error('Invalid numeric input for duty cycle.');
end
% Convert to standard units
dutyCycle = 1e-2*userDutyCycle; % percent to fraction

% Prompt user for frequency (Hz):
promptFreq = 'Please enter the frequency (Hz): ';
userFrequency = str2double(strtrim(input(promptFreq,'s')));
if not(userFrequency > 0)
    error('Invalid numeric input for frequency.');
end
% No need to change units, just change name
frequency = userFrequency; % Hz = 1/s

% Prompt user for chloroacetate concentration (mM):
promptConc = 'Please enter the initial chloroacetate (ClCH2CO2-) concentration: ';
userInitConc = str2double(strtrim(input(promptConc,'s')));
if not(userInitConc > 0)
    error('Invalid numeric input for concentration.');
end
% Just change name
initConc = userInitConc; % mM = mol/m^3

% Prompt user for film thickness
promptDelta = 'Please enter your assumed film thickness (um): ';
userDelta = str2double(strtrim(input(promptDelta,'s')));
if not(userDelta > 0)
    error('Invalid numeric input for film thickness.');
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

%% Regime identification

% Calculate time ratio
onTime = dutyCycle/frequency;

thresholdTime = 0.25*pi*(faradayConst^2)*(interfacialArea^2)*Ds*(peakCurrent^(-2))*((initConc - kineticThreshold)^2);

timeRatio = thresholdTime/onTime;

% Classification logic
underReact = timeRatio >= 1;
overRecover = dutyCycle <= 0.5;

if underReact && overRecover
    disp('Under-react, over-recover. Excellent!');
elseif underReact && ~overRecover
    disp('Under-react, under-recover. Consider adjusting parameters.');
elseif ~underReact && overRecover
    disp('Over-react, over-recover. Consider adjusting parameters.');
else
    disp('Over-react, under-recover. Please adjust parameters.');
end

%% Calculate the DC instantaneous Faradaic Efficiency

% prompt user if this calculation should be done
promptDCFESolve = 'Would you like to calculate the instantaneous FE for the analogous DC condition? (Y/N): ';
userDCFEYN = strtrim(input(promptDCFESolve,'s'));
if any(strcmp(userDCFEYN,{'yes','Y','Yes','y'}))
    % Calculate FE using interpolation from scaling law paper
    % Hatta number for electron recombination-diffusion
    Ha = kr*(delta^2)/De;
    % Calculate peak flux
    flux = peakCurrent/(interfacialArea*faradayConst);
    % Damkohler number for substrate reaction-diffusion
    Da = ks*flux*(delta^3)/(Ds*De);
    % Kinetic competition factor - ratio of psuedo-first order rate consts.
    Omega = ks*initConc/kr;
    if Da/Ha < 1
        alpha = 1;
    else
        alpha = 1 + log10(Da/Ha);
    end
    % Instantaneous radical selectivity - analogous to FEDC in this case
    eta = (((1/Omega)*(1 + (Da/Ha)))^alpha + 1)^(-1/alpha);
    DCFE = 1e2*eta;
    disp(['Calculated instantaneous FE for DC at same peak current: ', num2str(DCFE), ' %']);
elseif any(strcmp(userDCFEYN,{'no','N','No','n'}))
    disp('Calculation of instantaneous FE for DC not requested,')
else
    error('Invalid Y/N selection.')
end

