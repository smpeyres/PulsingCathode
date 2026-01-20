% script for calculating transient reaction-diffusion under first-order 
% recombination only - no substrate, pulse train flux

% Dimensional governing equation: C_t - DC_xx = -k_1 C
% Boundary conditions: C_x (x=0,t) = -J_0/D & C_x(x=L,t) = 0
% Initial condition: C (x,t=0) = 0

% Define dimensional parameters : ethylene glycol
D = 7.2e-10; % diffusivity, m^2/s
k = 1.2e6; % first-order rate constant, 1/s
J_peak = 2.4e-2; % peak interfacial flux, mol/m^2-s
freq = 1e5; % Hz - ADJUST THIS to explore different f/k regimes
duty = 0.1; % duty cycle (fraction of period that flux is on)

% Calculate intrinsic length, time scales, period
x_c = sqrt(D/k);
t_c = 1/k;
period = 1/freq; % seconds

% KEY DIMENSIONLESS PARAMETER
f_over_k = freq / k;

fprintf('Dimensionless parameters:\n');
fprintf('  f/k = %.3e\n', f_over_k);
fprintf('  x_c = %.3e m\n', x_c);
fprintf('  t_c = %.3e s\n', t_c);
fprintf('  P = %.3e s\n', period);
fprintf('  duty = %.2f\n', duty);

% Define domain length as 6x x_c
L = 6.0*x_c;

% Spatial mesh: 10 points per x_c
N_x = ceil(10 * L / x_c);
x = linspace(0, L, N_x);

% Determine the shorter timescale to define timestep
t_on = duty * period;
t_step = 0.1 * min(t_c, t_on);

% Time domain: solve for enough time to reach periodic steady state
% Need at least ~5*t_c, but also want multiple periods for visualization
n_periods = max(10, ceil(5*k/freq));
T_fin = n_periods * period;
t = linspace(0, T_fin, ceil(T_fin/t_step));

fprintf('  Number of periods simulated: %d\n', n_periods);
fprintf('  T_fin/t_c = %.2f\n', T_fin/t_c);

% Solve
m = 0; % Cartesian coordinates

% Function handles
pde = @(x,t,u,dudx) pdefun(x,t,u,dudx,D,k);
ic = @icfun;
bc = @(xl,ul,xr,ur,t) bcfun(xl,ul,xr,ur,t,D,J_peak,period,duty);

sol = pdepe(m, pde, ic, bc, x, t);

% =========================================================================
% PLOTTING
% =========================================================================

% Extract concentration at x=0 for temporal plots
u_0_numerical = sol(:,1);

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
if f_over_k < 0.1
    t_plot = t(idx_zoom);
    u_0_analytical = (J_peak/sqrt(D*k)) * ...
        (mod(t_plot - t_zoom_start, period) < duty*period);
    plot((t_plot - t_zoom_start)/period, u_0_analytical, ...
         'r--', 'LineWidth', 2, 'DisplayName', 'Analytical');
elseif f_over_k > 10
    plot([0, 3], [duty*J_peak/sqrt(D*k), duty*J_peak/sqrt(D*k)], ...
         'r--', 'LineWidth', 2, 'DisplayName', 'Analytical');
end

xlim([0, 3]);
ylim(y_lim);
xlabel('(t - t_{start}) / P');
ylabel('u(0,t)');
title('Periodic steady state (last 3 periods)');
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
    % Periodic pulse train
    t_mod = mod(t, period);  % time within current period
    
    if t_mod < duty * period
        J_0 = J_peak;  % "on" phase
    else
        J_0 = 0;       % "off" phase
    end
    
    % Left boundary: pulse train flux
    pl = J_0;
    ql = 1;
    
    % Right boundary: zero concentration
    pr = 0;
    qr = 1;
end