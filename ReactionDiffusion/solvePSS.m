function results = solvePSS(params, opts)
%{
solvePSS : Solve for the periodic steady state (PSS) of the solvated
electron + substrate film model with pulse train current using Picard
iteration.

Inputs:
params - struct with fields:
    .recRateConst [1/s] Lumped first-order recombination rate const. (k_r)
    .subRateConst [m^3/mol-s] Second-order electron-substrate rate const. (k_s)
    .emDiff [m^2/s] Electron diffusivity (D_e)
    .subDiff [m^2/s] Substrate diffusivity (D_s)
    .initConc [mol/m^3] Initial (bulk) substrate concentration (C_s,i)
    .filmThickness [mol/m^2-s] Film thickness (delta)
    .peakCurrent [A] Peak current (i_p)
    .interfacialArea [m^2] Interfacial area (A)
    .frequency [Hz] Frequency (f)
    .dutyCycle [-] Duty cycle (alpha = t_on/T)

opts - optional struct with fields:
    .tol - Relative Picard convergence tolerance (default 1e-4)
    .maxIter - Maximum Picard iterations (default 100)
    .pointsPerPeriod - Output time points per period (default 200)
    .plotBool - Generate diagnostic plots? (default false)

Outputs:
results - struct with fields:
    .periodicSteadyFE [%] Periodic steady-state faradaic efficiency
    .subTotal [mol/m^2] Substrate consumed per period per unit area
    .emTotal [mol/m^2] Electrons consumed per period per unit area
    .sol - pdepe solution array [time x space x species]
    .x [m] Spatial mesh
    .t [t] Time mesh for one PSS period [s]
    .relChangeHistory - Picard relative change at each iteration
    .numIter - Number of Picard iterations to convergence
%}
%% Parse 'opts'

% if only params is passed or if opts array is empty, create struct:
if nargin < 2 || isempty(opts)
    opts = struct();
end

% See local helper function 'getOpt' at bottom
tol = getOpt(opts, 'tol', 1e-4);
maxIter = getOpt(opts, 'maxIter', 100);
pointsPerPeriod = getOpt(opts, 'pointsPerPeriod', 200);
plotBool = getOpt(opts, 'plotBool', false);

%% Parse 'params'

recRateConstant = params.recRateConstant;
subRateConstant = params.subRateConstant;
emDiff = params.emDiff;
subDiff = params.subDiff;
initConc = params.initConc;
filmThickness = params.filmThickness;
peakCurrent = params.peakCurrent;
interfacialArea = params.interfacialArea;
frequency = params.frequency;
dutyCycle = params.dutyCycle;

% Define the period
period = 1/f; % [s]

% Define the peak flux
faradayConst = 96485; % [C/mol]
peakFlux = peakCurrent/(interfacialArea*faradayConst); % [mol/m^2-s]

%% Build spatial mesh

% Intrinsic electron length scale under selective limit
emLength = sqrt(emDiff / (subRateConstant * initConc));
% Intrinsic substrate length scale under selective limit
subLength = (subDiff*emDiff / (subRateConstant * peakFlux))^(1/3);
% Determine minimum length scale
minLength = min(emLength,subLength);

numLengths = ceil(filmThickness / minLength);
numPointsPerLength = 20; % hardcoded
xNum = numLengths * numPointsPerLength;
x = linspace(0, delta, xNum);

%% Build time mesh for one period
t = linspace(0, period, pointsPerPeriod);

%% Configure the pdepe solver
m = 0; % Cartesian coordinates
onTime = dutyCycle * period;
% Set maximum timestep as a tength of the on time
pdeOpts = odeset('MaxStep', onTime/10);

% See helper functions at bottom
pdeHandle = @(xq, tq, u, dudx) getPDE(xq, tq, u, dudx, emDiff, subDiff, recRateConstant, subRateConstant);
bcHandle = @(xl, ul, xr, ur, tq) getBC(xl, ul, xr, tq, peakFlux, period, dutyCycle, initCont);

%% Picard iteration

% Initial guess: C_e = 0, C_s = C_s,i everywhere
ic = [zeros(xNum, 1), initConc*ones(xNum,1)];

disp('=== solvePSS: Picard iteration ===')
fprintf('  N_x = %d,  points/period = %d,  tol = %.1e\n\n', ...
        N_x, points_per_period, tol);

relChangeHistory = nan(maxIter,1);
sol = [];

for iter = 1:maxIter
    icHandle = @(xq) getIC(xq, x, ic);

    sol = pdepe(m, pdeHandle, icHandle, bcHandle, x, t, pdeOpts);

    



end