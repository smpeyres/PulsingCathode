function results = solvePSS(params, opts)
%{
solvePSS : Solve for the periodic steady state (PSS) of the solvated
electron + substrate film model with pulse train current using Picard
iteration.

Inputs:
params - struct with fields:
    .firstOrderRateConst [1/s] First order rate constant of electron
        recomb. (k_1)
    .secOrderRateConst [m^3/mol-s] Second-order rate constant of electron
        recomb. (k_2)
    .subRateConst [m^3/mol-s] Second-order electron-substrate rate const. (k_s)
    .emDiff [m^2/s] Electron diffusivity (D_e)
    .subDiff [m^2/s] Substrate diffusivity (D_s)
    .initConc [mol/m^3] Initial (bulk) substrate concentration (C_s,i)
    .filmThickness [m] Film thickness (delta)
    .peakCurrent [A] Peak current (i_p)
    .interfacialArea [m^2] Interfacial area (A)
    .frequency [Hz] Frequency (f)
    .dutyCycle [-] Duty cycle (alpha = t_on/T)

opts - optional struct with fields:
    .tol                - Relative Picard convergence tolerance (default 1e-4)
    .maxIter            - Maximum Picard iterations (default 100)
    .pointsPerPeriod    - Output time points per period (default 200)
    .plotBool           - Generate diagnostic plots? (default false)
    .numPointsPerLength - Number of mesh points per characteristic length
                          (default 20)

Outputs:
results - struct with fields:
    .periodicSteadyFE [%] Periodic steady-state faradaic efficiency
    .subTotal [mol/m^2] Substrate consumed per period per unit area
    .emTotal [mol/m^2] Electrons consumed per period per unit area
    .sol - pdepe solution array [time x space x species]
    .x [m] Spatial mesh
    .t [s] Time mesh for one PSS period
    .relChangeHistory - Picard relative change at each iteration
    .numIter - Number of Picard iterations to convergence

CHANGES vs. original script version
-------------------------------------
1. t_on is an explicit node in the time output vector. pdepe passes the
   time vector to ode15s as required output points, so ode15s will step
   to t_on exactly and restart — handling the flux discontinuity cleanly
   with no extra pdepe calls and no overhead.

2. MaxStep uses min(onTime, offTime)/10 rather than just onTime/10, so
   it is appropriate for asymmetric duty cycles in either direction.

3. The relative-change metric guards against a near-zero denominator for
   both species independently, then takes the max.
%}

%% Parse opts
if nargin < 2 || isempty(opts)
    opts = struct();
end

tol                = getDefault(opts, 'tol',                1e-4);
maxIter            = getDefault(opts, 'maxIter',            100);
pointsPerPeriod    = getDefault(opts, 'pointsPerPeriod',    200);
plotBool           = getDefault(opts, 'plotBool',           false);
numPointsPerLength = getDefault(opts, 'numPointsPerLength', 20);

%% Parse params
firstOrderRateConst = getDefault(params, 'firstOrderRateConst', 0);
secOrderRateConst   = getDefault(params, 'secOrderRateConst',   0);
subRateConst        = params.subRateConst;
emDiff              = params.emDiff;
subDiff             = params.subDiff;
initConc            = params.initConc;
filmThickness       = params.filmThickness;
peakCurrent         = params.peakCurrent;
interfacialArea     = params.interfacialArea;
frequency           = params.frequency;
dutyCycle           = params.dutyCycle;

period   = 1 / frequency;
faradayConst = 96485;
peakFlux = peakCurrent / (interfacialArea * faradayConst);

%% Spatial mesh
emLength  = sqrt(emDiff / (subRateConst * initConc));
subLength = (subDiff * emDiff / (subRateConst * peakFlux))^(1/3);
minLength = min(emLength, subLength);

numLengths = ceil(filmThickness / minLength);
xNum       = numLengths * numPointsPerLength;
x          = linspace(0, filmThickness, xNum);

%% Time mesh for one period
if pointsPerPeriod < 20
    warning('solvePSS:LowTimeResolution', ...
        'pointsPerPeriod = %d is very low. Results may be inaccurate.', ...
        pointsPerPeriod);
end

onTime  = dutyCycle * period;
offTime = (1 - dutyCycle) * period;

% Distribute output points proportionally, with at least 2 per sub-interval,
% and ensure t_on is an explicit node so ode15s steps to it exactly and
% restarts — this handles the flux discontinuity cleanly.
nOn  = max(2, round(pointsPerPeriod * dutyCycle));
nOff = max(2, round(pointsPerPeriod * (1 - dutyCycle)));
tOn  = linspace(0,      onTime, nOn);
tOff = linspace(onTime, period, nOff + 1);
t    = [tOn, tOff(2:end)];

%% Timescale-based MaxStep
% Use the shorter sub-interval duration as MaxStep — correct for
% asymmetric duty cycles in either direction.
pdeOpts = odeset('MaxStep', min(onTime, offTime) / 10);

%% PDE and BC handles
m = 0;

pdeHandle = @(xq, tq, u, dudx) pdefun(xq, tq, u, dudx, emDiff, subDiff, ...
                firstOrderRateConst, secOrderRateConst, subRateConst);
bcHandle  = @(xl, ul, xr, ur, tq) bcfun(xl, ul, xr, ur, tq, peakFlux, ...
                period, dutyCycle, initConc);

%% Picard iteration
uInit = [zeros(xNum, 1), initConc * ones(xNum, 1)];

fprintf('=== solvePSS: Picard iteration ===\n');
fprintf('  N_x = %d,  points/period = %d,  tol = %.1e\n\n', ...
        xNum, pointsPerPeriod, tol);

relChangeHistory = nan(maxIter, 1);
sol      = [];
relChange = inf;

for iter = 1:maxIter

    icHandle = @(xq) icfun(xq, x, uInit);
    sol = pdepe(m, pdeHandle, icHandle, bcHandle, x, t, pdeOpts);

    % End-of-period state [xNum x 2]
    uEnd = squeeze(sol(end, :, :));

    % --- Convergence metric ---
    relChange = norm(uEnd(:,2) - uInit(:,2), 'fro') / norm(uInit(:,2), 'fro');

    relChangeHistory(iter) = relChange;
    fprintf('  Iter %3d:  relChange = %.3e  (e: %.3e, s: %.3e)\n', ...
            iter, relChange, relChangeSub);

    % Update IC for next iteration
    uInit = uEnd;

    if relChange < tol
        fprintf('\n  Converged in %d iterations.\n', iter);
        break;
    end
end

if relChange >= tol
    error('solvePSS:NoConvergence', ...
        ['Picard iteration did not converge after %d iterations. ' ...
         'Last relChange = %.3e (tol = %.3e). ' ...
         'Consider increasing maxIter or loosening tol.'], ...
        maxIter, relChange, tol);
end

numIter = iter;

%% Faradaic efficiency
substrateRate = trapz(x, subRateConst .* sol(:,:,1) .* sol(:,:,2), 2);
electronRate  = trapz(x, firstOrderRateConst    .*        sol(:,:,1)      + ...
                         2*secOrderRateConst .* sol(:,:,1).^2          + ...
                         subRateConst           .* sol(:,:,1) .* sol(:,:,2), 2);

subTotal = trapz(t, substrateRate);
emTotal  = trapz(t, electronRate);

if emTotal <= 0
    error('solvePSS:BadElectronBalance', ...
        'Total electron consumption is non-positive. Check parameters.');
end

periodicSteadyFE = 100 * subTotal / emTotal;

fprintf('\n=== PSS results ===\n');
fprintf('  FE                   = %.3f %%\n',       periodicSteadyFE);
fprintf('  Substrate consumed   = %.3e mol/m^2\n', subTotal);
fprintf('  Electrons consumed   = %.3e mol/m^2\n', emTotal);
fprintf('  Electrons delivered  = %.3e mol/m^2\n', peakFlux * dutyCycle * period);
fprintf('  Electron balance err = %.3e\n', ...
        peakFlux*dutyCycle*period - emTotal - trapz(x, sol(end,:,1) - sol(1,:,1)));

%% Pack results
results.periodicSteadyFE = periodicSteadyFE;
results.subTotal         = subTotal;
results.emTotal          = emTotal;
results.sol              = sol;
results.x                = x;
results.t                = t;
results.relChangeHistory = relChangeHistory(1:numIter);
results.numIter          = numIter;

%% Optional plots
if plotBool
    plotPSS(results, period, emLength, subLength, tol);
end

end % ---- end main function -----------------------------------------------


%% =========================================================================
%  LOCAL HELPER FUNCTIONS
%% =========================================================================

function val = getDefault(s, field, default)
    if isfield(s, field)
        val = s.(field);
    else
        val = default;
    end
end

% -------------------------------------------------------------------------
function u0 = icfun(xq, x_grid, uInit)
    u0 = [interp1(x_grid, uInit(:,1), xq, 'linear', 'extrap');
          interp1(x_grid, uInit(:,2), xq, 'linear', 'extrap')];
end

% -------------------------------------------------------------------------
function [c, f, s] = pdefun(~, ~, u, dudx, emDiff, subDiff, ...
                             firstOrderRateConst, secOrderRateConst, subRateConst)
    c = [1; 1];
    f = [emDiff; subDiff] .* dudx;
    s = [-firstOrderRateConst*u(1) - 2*secOrderRateConst*u(1)^2 - subRateConst*u(1)*u(2);
                                                                   -subRateConst*u(1)*u(2)];
end

% -------------------------------------------------------------------------
function [pl, ql, pr, qr] = bcfun(~, ~, ~, ur, tq, peakFlux, period, dutyCycle, initConc)
    J_t = pulsedFlux(tq, peakFlux, period, dutyCycle);
    pl = [J_t; 0];
    ql = [1;   1];
    pr = [0;   ur(2) - initConc];
    qr = [1;   0];
end

% -------------------------------------------------------------------------
function J_t = pulsedFlux(tq, peakFlux, period, dutyCycle)
    phase = mod(tq, period) / period;
    if phase < dutyCycle
        J_t = peakFlux;
    else
        J_t = 0;
    end
end

% -------------------------------------------------------------------------
function plotPSS(results, period, emLength, subLength, tol)
    sol = results.sol;
    x   = results.x;
    t   = results.t;

    % Convergence history
    figure;
    semilogy(1:results.numIter, results.relChangeHistory, 'o-', 'LineWidth', 2);
    yline(tol, 'k--', 'tol');
    xlabel('Picard iteration');
    ylabel('Relative change');
    title('PSS convergence');
    grid on;

    % Electron profiles
    figure; hold on;
    step = max(1, floor(size(sol, 1) / 10));
    tidx = unique([1:step:size(sol,1), size(sol,1)]);
    for i = 1:length(tidx)
        ti = tidx(i);
        plot(x/1e-9, sol(ti,:,1), ...
            'DisplayName', sprintf('t/T = %.2f', t(ti)/period), 'LineWidth', 1.5);
    end
    xlim([0, max(5*subLength, 5*emLength)/1e-9]);
    xlabel('x [nm]'); ylabel('C_e [mol/m^3]');
    title('Electron profile — one PSS period');
    legend('Location', 'best'); grid on; hold off;

    % Substrate profiles
    figure; hold on;
    for i = 1:length(tidx)
        ti = tidx(i);
        plot(x/1e-6, sol(ti,:,2), ...
            'DisplayName', sprintf('t/T = %.2f', t(ti)/period), 'LineWidth', 1.5);
    end
    xlim([0, max(x)/1e-6]);
    xlabel('x [µm]'); ylabel('C_s [mol/m^3]');
    title('Substrate profile — one PSS period');
    legend('Location', 'best'); grid on; hold off;

    % Surface concentrations
    figure;
    yyaxis left
    plot(t/period, sol(:,1,1), 'LineWidth', 2);
    ylabel('C_e(x=0) [mol/m^3]');
    yyaxis right
    plot(t/period, sol(:,1,2), 'LineWidth', 2);
    ylabel('C_s(x=0) [mol/m^3]');
    xlabel('t / T');
    title(sprintf('Surface concentrations — PSS (FE = %.1f %%)', results.periodicSteadyFE));
    grid on;
end