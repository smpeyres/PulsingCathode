% script for calculating transient reaction-diffusion under first-order 
% recombination only - no substrate, pulse train flux
close all;

% Dimensional governing equation: C_t - DC_xx = -k_1 C
% Boundary conditions: C_x (x=0,t) = -J_0/D & C_x(x=L,t) = 0
% Initial condition: C (x,t=0) = 0

% Define dimensional parameters : ethylene glycol
D = 7.2e-10; % diffusivity, m^2/s
k = 1.2e6; % first-order rate constant, 1/s
J_peak = 2.4e-2; % peak interfacial flux, mol/m^2-s
freq = 4e3; % Hz - ADJUST THIS to explore different f/k regimes
duty = 0.1; % duty cycle (fraction of period that flux is on)

% Calculate intrinsic length, time scales, period
x_c = sqrt(D/k);
t_c = 1/k;
period = 1/freq; % seconds

% KEY DIMENSIONLESS PARAMETERS
f_over_k = freq / k;
fk_over_duty = f_over_k / duty;

fprintf('Dimensionless parameters:\n');
fprintf('  f/k = %.3e\n', f_over_k);
fprintf('  fk/duty = %.3e\n', fk_over_duty);
fprintf('  x_c = %.3e m\n', x_c);
fprintf('  t_c = %.3e s\n', t_c);
fprintf('  P = %.3e s\n', period);
fprintf('  duty = %.2f\n', duty);

% Define domain length as 6x x_c
L = 6.0*x_c;

% Spatial mesh: 10 points per x_c
N_x = ceil(10 * L / x_c);
x = linspace(0, L, N_x);

% Time domain: solve for enough time to reach periodic steady state
% Need at least ~5*t_c for steady state
n_periods = max(10, ceil(1/f_over_k));
T_fin = n_periods * period;

% For high-quality visualization, use dense sampling
% Ensure at least 200 points per period, with extra for low duty cycles
points_per_period = max(200, ceil(500*duty));  % High resolution for clean plots

% Calculate required points
n_output_points = n_periods * points_per_period;

% Safety check: if too many points, reduce number of periods but maintain resolution
max_points = 200000;  % Generous limit for smooth plots
if n_output_points > max_points
    n_periods = floor(max_points / points_per_period);
    n_periods = max(10, n_periods);  % But keep at least 10 periods
    T_fin = n_periods * period;
    n_output_points = n_periods * points_per_period;
end

% Build time vector that explicitly includes points during "on" phases
% This ensures pdepe evaluates the BC during the pulses
t_points = [];
for i = 0:n_periods-1
    % Add points throughout this period, with extra density during "on" phase
    t_on_start = i * period;
    t_on_end = i * period + duty * period;
    t_off_end = (i+1) * period;
    
    % Dense sampling during "on"
    t_on = linspace(t_on_start, t_on_end, ceil(points_per_period * duty));
    % Sparser during "off"
    t_off = linspace(t_on_end, t_off_end, ceil(points_per_period * (1-duty)));
    
    t_points = [t_points, t_on(1:end-1), t_off(1:end-1)];
end
t = [t_points, T_fin];
n_output_points = length(t);

fprintf('  Number of periods simulated: %d\n', n_periods);
fprintf('  T_fin/t_c = %.2f\n', T_fin/t_c);
fprintf('  Points per period: %d\n', points_per_period);
fprintf('  Total output points: %d\n', n_output_points);

% Solve
m = 0; % Cartesian coordinates

% Function handles
pde = @(x,t,u,dudx) pdefun(x,t,u,dudx,D,k);
ic = @icfun;
bc = @(xl,ul,xr,ur,t) bcfun(xl,ul,xr,ur,t,D,J_peak,period,duty);

% Force small enough timesteps to resolve the "on" phases
% MaxStep should be smaller than the "on" duration
options = odeset('MaxStep', duty * period / 10);

sol = pdepe(m, pde, ic, bc, x, t, options);

% =========================================================================
% PLOTTING
% =========================================================================

% Extract concentration at x=0 for temporal plots
u_0_numerical = sol(:,1);

figure;
plot(t/t_c, u_0_numerical);
xlabel('t / t_c');
ylabel('u(0,t)');
title('Full time history - checking convergence');
grid on;

fprintf('Analytical steady value = %.3e\n', J_peak/sqrt(D*k));
fprintf('Max numerical = %.3e\n', max(u_0_numerical));

% PLOT: Zoom on last few periods (periodic steady state) and time-averaged profile
figure('Position', [100, 100, 1200, 400]);

subplot(1,2,1);
hold on;

% Plot last 3 periods
t_zoom_start = T_fin - 3*period;
idx_zoom = find(t >= t_zoom_start);

plot((t(idx_zoom) - t_zoom_start)/period, u_0_numerical(idx_zoom), ...
     'b-', 'LineWidth', 2, 'DisplayName', 'Numerical');

% Add shading for "on" phases
y_lim = [0, max(u_0_numerical(idx_zoom))*1.1];
for i = 0:2
    patch([i, i, i+duty, i+duty], [y_lim(1), y_lim(2), y_lim(2), y_lim(1)], ...
          'g', 'FaceAlpha', 0.1, 'EdgeColor', 'none', 'HandleVisibility', 'off');
end

% Analytical limits
if fk_over_duty < 0.1  % Low frequency quasi-steady regime
    t_plot = t(idx_zoom);
    u_0_analytical = (J_peak/sqrt(D*k)) * ...
        (mod(t_plot - t_zoom_start, period) < duty*period);
    plot((t_plot - t_zoom_start)/period, u_0_analytical, ...
         'r--', 'LineWidth', 2, 'DisplayName', 'Analytical (quasi-steady)');
elseif f_over_k > 10  % High frequency time-averaged regime
    plot([0, 3], [duty*J_peak/sqrt(D*k), duty*J_peak/sqrt(D*k)], ...
         'r--', 'LineWidth', 2, 'DisplayName', 'Analytical (time-avg)');
end

xlim([0, 3]);
ylim(y_lim);
xlabel('(t - t_{start}) / P');
ylabel('u(0,t)');
title(sprintf('Periodic steady state (f/k=%.2e, fk/a=%.2e)', f_over_k, fk_over_duty));
legend('Location', 'best');
grid on;
hold off;

% PLOT: Time-averaged profile
subplot(1,2,2);
hold on;

% Calculate time average over last period
idx_last_period = find(t >= T_fin - period);
u_time_avg = mean(sol(idx_last_period, :), 1);

plot(x/x_c, u_time_avg, 'b-', 'LineWidth', 2, 'DisplayName', 'Numerical (time-avg)');

% Analytical time-averaged profile (works for all f/k)
u_analytical_avg = (duty*J_peak/sqrt(D*k)) * exp(-x/x_c);
plot(x/x_c, u_analytical_avg, 'r--', 'LineWidth', 2, ...
     'DisplayName', 'Analytical (duty × steady)');

xlim([0, L/x_c]);
xlabel('x / x_c');
ylabel('<u>_t');
title('Time-averaged concentration profile');
legend('Location', 'best');
grid on;
hold off;

% =========================================================================
% HELPER FUNCTIONS
% =========================================================================

function [c,f,s] = pdefun(x,t,u,dudx,D,k)
    c = 1;
    f = D * dudx;
    s = -k * u;
end

function u0 = icfun(x)
    u0 = 0;  % constant initial condition
end

function [pl,ql,pr,qr] = bcfun(xl,ul,xr,ur,t,D,J_peak,period,duty)
    % Periodic pulse train - robust to floating point errors
    % Compute which period we're in
    cycle_num = floor(t / period);
    t_in_cycle = t - cycle_num * period;  % More accurate than mod for large t
    
    if rem(t, period) < duty * period
        J_0 = J_peak;
    else
        J_0 = 0;
    end

    % % DEBUG: Print more detail
    % persistent call_count;
    % if isempty(call_count), call_count = 0; end
    % call_count = call_count + 1;
    % if mod(call_count, 1000) == 0
    %     fprintf('BC call %d: t=%.6e, t_in_cycle=%.6e, duty*P=%.6e, J_0=%.3e\n', ...
    %             call_count, t, t_in_cycle, duty*period, J_0);
    % end
    
    % Left boundary: pulse train flux
    pl = J_0;
    ql = 1;
    
    % Right boundary: zero concentration
    pr = 0;
    qr = 1;
end