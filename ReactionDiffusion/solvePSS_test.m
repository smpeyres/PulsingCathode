% Physical parameters - water, 20 mM chloroacetate
params.secOrderRateConst = 5.5e6;   % m^3/mol-s (k_2)
params.subRateConst      = 1.5e6;   % m^3/mol-s (k_s)
params.emDiff            = 4.9e-9;  % m^2/s
params.subDiff           = 1.1e-9;  % m^2/s
params.initConc          = 150;      % mol/m^3
params.filmThickness     = 1e-6;    % m
params.peakCurrent       = 9.78e-3; % A
params.interfacialArea   = 0.49e-6;  % m^2
params.frequency         = 5e4;     % Hz
params.dutyCycle         = 0.50;    % -

% Solver options - plots on so we can visually inspect
opts.plotBool = true;
opts.maxIter = 1000;

% Call
results = solvePSS(params, opts);

% Inspect
disp(results.periodicSteadyFE);