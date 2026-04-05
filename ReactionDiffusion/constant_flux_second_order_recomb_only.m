% script for calculating transient reaction-diffusion under second-order 
% recombination only - no substrate, steady flux to start

% Dimensional governing equation: C_t - DC_xx = -2 k C^2
% Boundary conditions: C_x (x=0,t) = -J/D & C_x(x=L,t) = 0
% Initial condition: C (x,t=0) = 0

% Define dimensional parameters : water
D = 4.9e-9; % diffusivity, m^2/s
k = 5.5e6; % second-order rate constant, m^3/mol-s
J = 1.3e-1; % interfacial flux, mol/m^2-s

% Calculate intrinsic length, time, concentration scales
x_c = (D^2 / (2 * k * J))^(1/3);
t_c = (D / (4 * k^2 * J^2))^(1/3);
C_c = (J^2 / (2 * k * D))^(1/3);

% Penetration length scale
l = x_c*(12)^(1/3);

% Define domain length as 7 times l_c
L = 7*l;

% Spatial mesh: 10 points per x_c
N_x = ceil(10 * L / x_c);
x = linspace(0, L, N_x);

% Time: solve for 40 time constants
T_fin = 40*t_c;
t = linspace(0, T_fin, 400);
% Note: pdepe naturally uses adaptive time-stepping

% Solve
m = 0; % Cartesian coordinates

% Function handles
pde = @(x,t,u,dudx) pdefun(x,t,u,dudx,D,k);
ic = @icfun;
bc = @(xl,ul,xr,ur,t) bcfun(xl,ul,xr,ur,t,D,J);

sol = pdepe(m, pde, ic, bc, x, t);
% Note: sol makes "double" with first index being timestep and second index
% being mesh point

% Functions with c u_t = df/dx + s
% c = coefficient on time derivative (1)
% f = flux term, f = D du/dx for diffusion, uniform D
% s = source term
function [c,f,s] = pdefun(x,t,u,dudx,D,k)
    c = 1;
    f = D * dudx;
    s = -2* k * u * u;
end

function u0 = icfun(x)
    u0 = 0;  % constant initial condition
end

% Naturally concentration, flux-based
function [pl,ql,pr,qr] = bcfun(xl,ul,xr,ur,t,D,J)
    % Left boundary: f' = -J
    pl = J;
    ql = 1; % defines 'order'
    
    % Right boundary: u = 0
    pr = 0;
    qr = 1;
end

% PLOT 1: Spatial profiles at different times
figure;
hold on;

% Select snapshot times (e.g., at 0, 1, 2, 3, 4 time constants)
snapshot_times = [0, 0.1, 0.2, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 40.0] * t_c;

for i = 1:length(snapshot_times)
    % Find closest time index
    [~, idx] = min(abs(t - snapshot_times(i)));
    
    % Display as multiples of t_c
    t_normalized = t(idx)/t_c;
    plot(x/1e-9, sol(idx,:), 'DisplayName', sprintf('t = %.1f t_c', t_normalized), 'LineWidth',2);
end

function u_ss = steady(x,l,C_c)
    u_ss = (3/2)^(1/3) * C_c .* (1 + x./l).^-2;
end
plot(x/1e-9, steady(x,l,C_c), 'DisplayName', 'Steady Analytical', 'Color', 'k','LineWidth', 2, 'LineStyle', '--');

xlim([0,L/1e-9]);
xlabel('x [nm]');
ylabel('C_e [mM]');
legend('Location', 'best');
grid on;
hold off;

% PLOT 2: Temporal evolution at x=0
figure;
hold on;
% Extract u(0,t) from numerical solution (first spatial point)
u_0_numerical = sol(:,1);
% Analytical scaling: u(0,t) ~ J sqrt(t/D)
u_0_early = (2/sqrt(pi))*J*sqrt(t/D);
% Plot both
plot(sqrt(t/t_c), u_0_numerical, 'o', 'DisplayName', 'Numerical', 'MarkerSize', 6, 'LineWidth', 1.5);
plot(sqrt(t/t_c), u_0_early, '-', 'DisplayName', 'Early-Time Diffusion', 'LineWidth', 2);
yline((3/2)^(1/3)*C_c, ':', 'DisplayName', 'Steady', 'LineWidth', 2)
xlabel('sqrt(t / t_c)');
xlim([0,3]);
ylim([0,1]);
ylabel('C_e(0,t) [mM]');
legend('Location', 'best');
grid on;
hold off;