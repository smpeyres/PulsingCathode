% script for calculating transient reaction-diffusion under second-order
% recombination only - no substrate, pulse train flux
clear all;

% Dimensional governing equation: C_t - DC_xx = -2 k_2 C^2
% Boundary conditions: C_x (x=0,t) = -J_0/D & C_x(x=L,t) = 0
% Initial condition: C (x,t=0) = 0

% Define dimensional parameters : water
D = 4.9e-9; % diffusivity, m^2/s
k = 5.5e6; % second-order rate constant, m^3/mol-s
J_peak = 1.3e-1; % interfacial flux, mol/m^2-s
freq = 5e7; % Hz - Adjust freely
duty = 0.2; % duty cycle - Adjust freely (between 0 and 1)

% Calculate phi -> dimensionless moduli
period = 1/freq; % seconds
C_ec = (J_peak^2/(2*k*D))^(1/3); % characteristic concentration
phi = (duty*period*2*k*C_ec)^-1; % phi for n = 2

% Calculate the lengthscale
x_c = (D^2 / (2 * k * J_peak))^(1/3);

fprintf('  freq = %.3e Hz\n', freq);
fprintf('  P = %.3e s\n', period);
fprintf('  duty = %.2f\n', duty);
fprintf('  phi = %.3e\n', phi);
fprintf('  x_c = %.3e m\n', x_c);

% Define domain length as 7 x l
l = x_c*(12)^(1/3); % Penetration length scale
L = 7*x_c;

% Spatial mesh: 10 points per x_c
N_x = ceil(10 * L / x_c);
x = linspace(0, L, N_x);

% Time domain: solve for enough time to reach periodic steady state
% Let's just say its 10 periods, for now. We can adjust later.
if phi > 10
    n_periods = 5*round(phi);
else
    n_periods = 10;
end

T_fin = n_periods * period;

% Output times for plotting (actual integration uses MaxStep for accuracy)
points_per_period = 200;  % Sufficient for smooth plotting
t = linspace(0, T_fin, n_periods * points_per_period);

fprintf('  Total time: %d s\n', T_fin);
fprintf('  Number of periods simulated: %d\n', n_periods);
fprintf('  Points per period: %d\n', points_per_period);
fprintf('  Total output points: %d\n', length(t));

% Solve
m = 0; % Cartesian coordinates

% Function handles
pde = @(x,t,u,dudx) pdefun(x,t,u,dudx,D,k);
ic = @icfun;
bc = @(xl,ul,xr,ur,t) bcfun(xl,ul,xr,ur,t,J_peak,period,duty);

% Force small enough timesteps to resolve the "on" phases
% MaxStep should be smaller than the "on" duration
t_on = duty * period;
num_step_per_on = 40; % can increase if needed
options = odeset('MaxStep', t_on/num_step_per_on);

sol = pdepe(m, pde, ic, bc, x, t, options);

% "Helper" functions

function [c,f,s] = pdefun(x,t,u,dudx,D,k)
    c = 1;
    f = D * dudx;
    s = -2 * k * u^2;
end

function u0 = icfun(x)
    u0 = 0;  % initial condition at zero
end

function [pl,ql,pr,qr] = bcfun(xl,ul,xr,ur,t,J_peak,period,duty)
    % Periodic pulse train for flux at left boudary
    if rem(t, period) < duty * period
        J_0 = J_peak;
    else
        J_0 = 0;
    end

    % Left boundary: pulse train flux
    pl = J_0; % sets the flux, which is positive: J_0 = -D * u_x
    ql = 1; % coefficient for flux BC; ql = 0 would be Dirichlet BC

    % Right boundary: zero flux
    pr = 0; % sets flux = 0 at x=L
    qr = 1;
end

% Plotting

% Plot 1: Concentration at x=0 over time, showing periodic steady state

% Extract concentration at x=0 for temporal plots
u_0_numerical = sol(:,1);

% PLOT: Zoom on last few periods (periodic steady state) and time-averaged profile
figure;

% subplot(1,2,1);
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
if phi < 0.1  % Low frequency quasi-steady regime
    t_plot = t(idx_zoom);
    u_0_analytical = (3*J_peak^2/(4*k*D))^(1/3) * ...
        (mod(t_plot - t_zoom_start, period) < duty*period);
    plot((t_plot - t_zoom_start)/period, u_0_analytical, ...
         'r--', 'LineWidth', 2, 'DisplayName', 'Analytical (quasi-steady)');
elseif phi > 10  % High frequency time-averaged regime
    yline((3*duty^2*J_peak^2/(4*k*D))^(1/3), 'r--', 'LineWidth', 2, 'DisplayName', 'Analytical (time-avg)');
end

xlim([0, 3]);
ylim(y_lim);
xlabel('t / P');
ylabel('u(0,t)');
title(sprintf('Periodic steady state (freq = %.2e, duty = %.2f, phi=%.2e)', freq, duty, phi));
legend('Location', 'best');
grid on;
hold off;


% 
% 
% Plotting
% 
% Plot 1: Concentration at x=0 over time, showing periodic steady state
% 
% Extract concentration at x=0 for temporal plots
% u_0_numerical = sol(:,1);
% 
% fprintf('Analytical steady value = %.3e\n', (3*J_peak^2 /(4 * D * k))^(1/3));
% fprintf('Max numerical = %.3e\n', max(u_0_numerical));
% 
% PLOT: Zoom on last few periods (periodic steady state) and time-averaged profile
% figure('Position', [100, 100, 1200, 400]);
% 
% subplot(1,2,1);
% hold on;
% 
% Plot last 3 periods
% t_zoom_start = T_fin - 3*period;
% idx_zoom = find(t >= t_zoom_start);
% 
% plot((t(idx_zoom) - t_zoom_start)/period, u_0_numerical(idx_zoom), ...
%      'b-', 'LineWidth', 2, 'DisplayName', 'Numerical');
% 
% Add shading for "on" phases
% y_lim = [0, max(u_0_numerical(idx_zoom))*1.1];
% for i = 0:2
%     patch([i, i, i+duty, i+duty], [y_lim(1), y_lim(2), y_lim(2), y_lim(1)], ...
%           'g', 'FaceAlpha', 0.1, 'EdgeColor', 'none', 'HandleVisibility', 'off');
% end
% 
% Analytical limits
% if phi_over_duty < 0.1  % Low frequency quasi-steady regime
%     t_plot = t(idx_zoom);
%     u_0_analytical = (3*J_peak^2 /(4 * D * k))^(1/3) * ...
%         (mod(t_plot - t_zoom_start, period) < duty*period);
%     plot((t_plot - t_zoom_start)/period, u_0_analytical, ...
%          'r--', 'LineWidth', 2, 'DisplayName', 'Analytical (quasi-steady)');
% elseif phi > 10  % High frequency time-averaged regime
%     plot([0, 3], [(3* duty^2 * J_peak^2 /(4 * D * k))^(1/3), (3 * duty^2 * J_peak^2 /(4 * D * k))^(1/3)], ...
%          'r--', 'LineWidth', 2, 'DisplayName', 'Analytical (time-avg)');
% end
% 
% xlim([0, 3]);
% ylim(y_lim);
% xlabel('(t - t_{start}) / P');
% ylabel('u(0,t)');
% title(sprintf('Periodic steady state (phi=%.2e, phi/duty=%.2e)', phi, phi_over_duty));
% legend('Location', 'best');
% grid on;
% hold off;
% 
% Plot 2: Time-averaged concentration profile at periodic steady state
% subplot(1,2,2);
% hold on;
% 
% Calculate time average over last period
% idx_last_period = find(t >= T_fin - period); % indices for last period
% u_time_avg = mean(sol(idx_last_period, :), 1); % calculates time-averaged profile from last period
% 
% plot(x/x_c, u_time_avg, 'b-', 'LineWidth', 2, 'DisplayName', 'Numerical (time-avg)');
% 
% Analytical time-averaged profile (case-dependent)
% if phi_over_duty < 0.1  % Low frequency quasi-steady regime
%     Simply duty fraction of the on-phase quasi-steady solution
%     u_analytical_avg = duty * (3*J_peak^2 /(4 * D * k))^(1/3) * ...
%         ( (k*J_peak/(6*D^2))^(1/3) * x + 1 ).^(-2);
%     analytical_label = sprintf('Analytical');
% else  % High frequency time-averaged regime
%     u_analytical_avg = (3* duty^2 * J_peak^2 /(4 * D * k))^(1/3) * ...
%         ( (k*duty*J_peak/(6*D^2))^(1/3) * x + 1 ).^(-2);
%     analytical_label = sprintf('Analytical');
% end
% 
% plot(x/x_c, u_analytical_avg, 'r--', 'LineWidth', 2, ...
%      'DisplayName', analytical_label);
% 
% xlim([0, L/x_c]);
% xlabel('x / x_c');
% ylabel('<u>_t');
% title('Time-averaged concentration profile');
% legend('Location', 'best');
% grid on;
% hold off;
% 
% Plot 3: Spatial profiles at different time snapshots within last period
% figure('Position', [100, 550, 1400, 500]);
% 
% Define time snapshots within the last period
% num_snapshots = 6;
% snapshot_fractions = linspace(0, 1 - 1/num_snapshots, num_snapshots);
% snapshot_times = T_fin - period + snapshot_fractions * period;
% 
% Determine colors for snapshots
% colors = parula(num_snapshots);
% 
% for i = 1:num_snapshots
%     subplot(2, 3, i);
%     hold on;
% 
%     t_snap = snapshot_times(i);
% 
%     Find nearest index in solution
%     [~, idx_snap] = min(abs(t - t_snap));
% 
%     Extract numerical solution at this time
%     u_numerical_snap = sol(idx_snap, :);
% 
%     Calculate analytical solution based on regime
%     Quasi-steady analytical solution: instantaneous equilibrium
%     if phi_over_duty < 0.1
%         Low frequency: solution depends on whether flux is "on"
%         phase = mod(t_snap - (T_fin - period), period) / period;
%         if phase < duty
%             During "on" phase: use quasi-steady solution with J = J_peak
%             u_analytical_snap = (3*J_peak^2 /(4 * D * k))^(1/3) * ...
%                 ( (k*J_peak/(6*D^2))^(1/3) * x + 1 ).^(-2);
%         else
%             During "off" phase: concentration is zero
%             u_analytical_snap = zeros(size(x));
%         end
%     else
%         High frequency time-averaged regime: use smoothed average profile
%         u_analytical_snap = (3* duty^2 * J_peak^2 /(4 * D * k))^(1/3) * ...
%             ( (k*duty*J_peak/(6*D^2))^(1/3) * x + 1 ).^(-2);
%     end
% 
%     Plot both solutions
%     plot(x/x_c, u_numerical_snap, 'b-', 'LineWidth', 2, 'DisplayName', 'Numerical');
%     plot(x/x_c, u_analytical_snap, 'r--', 'LineWidth', 2, 'DisplayName', 'Analytical');
% 
%     phase = mod(t_snap - (T_fin - period), period) / period;
%     phase_pct = 100 * phase;
% 
%     xlim([0, L/x_c]);
%     xlabel('x / x_c');
%     ylabel('u(x,t)');
%     title(sprintf('t = %.1f%% of period', phase_pct));
%     legend('Location', 'best');
%     grid on;
%     hold off;
% end
