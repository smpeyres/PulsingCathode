% script for calculating transient reaction-diffusion under first-order 
% recombination only - no substrate, steady flux to start

% Dimensional governing equation: C_t - DC_xx = -k_1 C
% Boundary conditions: C_x (x=0,t) = -J/D & C_x(x=L,t) = 0
% Initial condition: C (x,t=0) = 0

% Define dimensional parameters : ethylene glycol
D = 7.2e-10; % diffusivity, m^2/s
k = 1.2e6; % first-order rate constant, 1/s
J = 2.4e-2; % interfacial flux, mol/m^2-s

% Calculate intrinsic length, time scales
x_c = sqrt(D/k);
t_c = 1/k;

% Define domain length as 7x x_c
L = 7.0*x_c;

% Spatial mesh: 10 points per x_c
N_x = ceil(10 * L / x_c);
x = linspace(0, L, N_x);

% Time: solve for 5 time constants
T_fin = 5*t_c;
t = linspace(0, T_fin, 50);
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
    s = -k * u;
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
% Select snapshot times (e.g., at 0, 0.1, 0.2, 0.5, 1, 2, 5 time constants)
snapshot_times = [0, 0.1, 0.2, 0.5, 1.0, 2.0, 5.0] * t_c;
for i = 1:length(snapshot_times)
% Find closest time index
    [~, idx] = min(abs(t - snapshot_times(i)));
% Display as multiples of t_c
    t_normalized = t(idx)/t_c;
    plot(x/1e-9, sol(idx,:), 'DisplayName', sprintf('t = %.1f t_c', t_normalized), 'LineWidth',2);
end

function u_ss = steady(x,J,D,k)
    A = J/sqrt(D*k);
    B = sqrt(k/D);
    u_ss = A .* exp(-B .* x);
end
plot(x/1e-9, steady(x,J,D,k), 'DisplayName', 'Steady Analytical', 'Color', 'k','LineWidth', 2, 'LineStyle', '--');
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
% Analytical solution: u(0,t) = (J/sqrt(D*k)) * erf(sqrt(k*t))
u_0_analytical = (J/sqrt(D*k)) * erf(sqrt(k*t));
% Analytical steady-state: u(0,t->\infty) = (J/sqrt(D*k))
u_0_steady = J/sqrt(D*k);
% Analytical early-time diffusion: u(0,t) = 2J*sqrt(t/D\pi)
u_0_early = (2/sqrt(pi))*J*sqrt(t/D);

% Plot both
plot(sqrt(t/t_c), u_0_numerical, 'o', 'DisplayName', 'Numerical', 'MarkerSize', 6, 'LineWidth', 1.5);
plot(sqrt(t/t_c), u_0_analytical, '-', 'DisplayName', 'Analytical', 'LineWidth', 2);
yline(u_0_steady, ':', 'DisplayName', 'Steady', 'LineWidth', 2);
plot(sqrt(t/t_c), u_0_early, '--', 'DisplayName', 'Early Time Diffusion', 'LineWidth', 2);
xlim([0,sqrt(5)]);
ylim([0,1]);
xlabel('sqrt(t / t_c) = sqrt(k_1t)');
ylabel('C_e(0,t)');
legend('Location', 'best');
grid on;
hold off;