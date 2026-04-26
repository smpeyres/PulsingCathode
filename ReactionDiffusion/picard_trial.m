% script for calculating PERIODIC STEADY STATE of transient reaction-diffusion
% under general conditions, using auto-terminating Picard iteration.
%
% Strategy: solve one period at a time. After each period, use the final
% state as the IC for the next period. Stop when period-end state stops
% changing (below tol). Final solution = one period of PSS.
clear all;

% Dimensional governing equations:
% E_t - D_e E_xx = - ks E S - 2 k_2 E^2
% S_t - D_s S_xx = - ks E S
% BCs:
% E_x (x=0) = -J(t)/D_e 
% E_x (x=delta) = 0
% S_x (x=0) = 0
% S (x=delta) = S_b
% IC for Picard iteration: E=0, S=S_b; then bootstrapped from previous period.

% Define dimensional parameters : water, 20 mM chloroacetate
k_s = 1.5e6;      % m3 mol-1 s-1
k_2 = 5.5e6;      % m^3/mol-s
D_e = 4.9e-9;     % m2 s-1
D_s = 1.1e-9;     % m2 s-1
S_b = 20;         % mol m-3
delta = 1e-6;     % m

% Pulse parameters
f = 5e3; % frequency [Hz]
T = 1/f; % period [s]
i_peak = 10; % mA
alpha = 0.5; % duty cycle [-]
area = 0.49; % mm^2
faraday = 96485;  % C/mol
J_peak = i_peak*1e-3/(area*1e-6*faraday); % mol m^-2 s^-1

% Picard convergence controls
tol       = 1e-4;  % relative change in period-end state to declare PSS
max_iter  = 200;   % safety cap on Picard iterations
points_per_period = 400;

% Calculate intrinsic length scales
x_e = sqrt(D_e/(k_s*S_b));               % electron
x_s = ((D_s*D_e)/(k_s*J_peak))^(1/3);    % substrate
xc_min = min([x_e, x_s]);

% calculate timescales (for reference / reporting)
t_D = (delta^2)/D_s;
t_e = (k_s*S_b)^(-1);
t_s = (D_e^2/(D_s*k_s^2*J_peak^2))^(1/3);

% Spatial mesh
numLengths = ceil(delta/xc_min);
numPointsPerLength = 30;
N_x = numPointsPerLength*numLengths;
x = linspace(0, delta, N_x);

% Time mesh for ONE period
t = linspace(0, T, points_per_period);

% Solver options
m = 0;
t_on = alpha * T;
options = odeset('MaxStep', t_on/20);

% Function handles (independent of IC)
pde = @(xq,tq,u,dudx) pdefun(xq,tq,u,dudx,D_e,D_s,k_s,k_2);
bc  = @(xl,ul,xr,ur,tq) bcfun(xl,ul,xr,ur,tq,J_peak,T,alpha,S_b);

% Initial guess for the periodic IC: E=0, S=S_b everywhere
u_ic = [zeros(N_x,1), S_b*ones(N_x,1)];

fprintf('=== Picard iteration for periodic steady state ===\n');
fprintf('N_x = %d, points/period = %d, tol = %.1e\n\n', N_x, points_per_period, tol);

rel_change_history = nan(max_iter,1);
for iter = 1:max_iter
    % Build IC function from current u_ic array (interp to pdepe's queried x)
    ic_fun = @(xq) ic_from_array(xq, x, u_ic);
    
    % Solve one period
    sol = pdepe(m, pde, ic_fun, bc, x, t, options);
    
    % End-of-period state
    u_end = squeeze(sol(end,:,:));   % [N_x x 2]
    
    % Relative change vs. period-start state
    rel_change = norm(u_end - u_ic, 'fro') / norm(u_ic, 'fro');
    rel_change_history(iter) = rel_change;
    fprintf('Iter %3d:  ||u_end - u_start|| / ||u_start|| = %.3e\n', iter, rel_change);
    
    % Update IC for next iteration
    u_ic = u_end;
    
    if rel_change < tol
        fprintf('\nConverged to periodic steady state in %d iterations.\n', iter);
        break;
    end
end
if iter == max_iter && rel_change >= tol
    warning('Reached max_iter = %d without meeting tol = %.1e. Last rel change = %.3e', ...
            max_iter, tol, rel_change);
end

% sol now holds ONE period of the periodic steady state.

% ---------- Diagnostics ----------

% FE over the PSS period
substrateRate = trapz(x, k_s.*sol(:,:,1).*sol(:,:,2), 2);
electronRate  = trapz(x, 2*k_2.*sol(:,:,1).^2 + k_s.*sol(:,:,1).*sol(:,:,2), 2);
sub_total  = trapz(t, substrateRate);
elec_total = trapz(t, electronRate);
FE_PSS = 100 * sub_total / elec_total;

fprintf('\n=== Periodic steady state results ===\n');
fprintf('  FE (PSS)             = %.3f %%\n', FE_PSS);
fprintf('  Substrate consumed   = %.3e mol/m^2 per period\n', sub_total);
fprintf('  Electrons consumed   = %.3e mol/m^2 per period\n', elec_total);
fprintf('  Electrons delivered  = %.3e mol/m^2 per period\n', J_peak*alpha*T);
fprintf('  Electron balance err = %.3e (should be near zero)\n', ...
        J_peak*alpha*T - elec_total - trapz(x, sol(end,:,1) - sol(1,:,1)));

% ---------- Plots ----------

% Convergence history
figure;
semilogy(1:iter, rel_change_history(1:iter), 'o-', 'LineWidth', 2);
yline(tol, 'k--', 'tol');
xlabel('Picard iteration (= period number)');
ylabel('||u_{end} - u_{start}|| / ||u_{start}||');
title('PSS convergence');
grid on;

% Electron spatial profiles across one period of PSS
figure; hold on;
step = max(1, floor(points_per_period/10));
time_indices = 1:step:size(sol,1);
if time_indices(end) ~= size(sol,1), time_indices(end+1) = size(sol,1); end
for i = 1:length(time_indices)
    ti = time_indices(i);
    plot(x/1e-9, sol(ti,:,1), 'DisplayName', sprintf('t/T = %.2f', t(ti)/T), 'LineWidth', 1.5);
end
xlim([0, max(5*x_s, 5*x_e)/1e-9]);
xlabel('x [nm]'); ylabel('C_e [mol/m^3]');
title('Electron profile across one period of PSS');
legend('Location', 'best'); grid on; hold off;

% Substrate spatial profiles across one period of PSS
figure; hold on;
for i = 1:length(time_indices)
    ti = time_indices(i);
    plot(x/1e-6, sol(ti,:,2), 'DisplayName', sprintf('t/T = %.2f', t(ti)/T), 'LineWidth', 1.5);
end
xlim([0, delta/1e-6]);
xlabel('x [\mum]'); ylabel('C_s [mol/m^3]');
title('Substrate profile across one period of PSS');
legend('Location', 'best'); grid on; hold off;

% Surface concentrations vs time over one period
figure;
yyaxis left
plot(t/T, sol(:,1,1), 'LineWidth', 2);
ylabel('C_e(x=0) [mol/m^3]');
yyaxis right
plot(t/T, sol(:,1,2), 'LineWidth', 2);
ylabel('C_s(x=0) [mol/m^3]');
xlabel('t / T');
title('Surface concentrations over one PSS period');
grid on;

% ---------- Helper functions ----------

function u0 = ic_from_array(xq, x_grid, u_ic)
    % Interpolate stored IC array onto pdepe's queried point xq.
    % pdepe calls this once per mesh point, passing a scalar xq.
    u0 = [interp1(x_grid, u_ic(:,1), xq, 'linear', 'extrap');
          interp1(x_grid, u_ic(:,2), xq, 'linear', 'extrap')];
end

function [c,f,s] = pdefun(~,~,u,dudx,D_e,D_s,k_s,k_2)
    c = [1; 1];
    f = [D_e; D_s] .* dudx;
    F_e = -k_s*u(1)*u(2) - 2*k_2*u(1)*u(1);
    F_s = -k_s*u(1)*u(2);
    s = [F_e; F_s];
end

function [pl,ql,pr,qr] = bcfun(~,~,~,ur,tq,J_peak,T,alpha,S_b)
    J_t = pulsedFlux(tq, J_peak, T, alpha);
    pl = [J_t; 0];
    ql = [1; 1];
    pr = [0; ur(2) - S_b];
    qr = [1; 0];
end

function J_t = pulsedFlux(tq, J_peak, T, alpha)
    phase = mod(tq, T) / T;
    if phase < alpha
        J_t = J_peak;
    else
        J_t = 0;
    end
end