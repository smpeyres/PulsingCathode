% script for calculating transient reaction-diffusion under first-order 
% recombination only - no substrate, steady flux to start

% Dimensional governing equation: C_t - DC_xx = -k_1 C
% Boundary conditions: C_x (x=0,t) = -J_0/D & C_x(x=L,t) = 0
% Initial condition: C (x,t=0) = 0

% Define dimensional parameters : ethylene glycol
D = 7.2e-10; % diffusivity, m^2/s
k = 1.2e6; % first-order rate constant, 1/s
J_0 = 2.4e-2; % interfacial flux, mol/m^2-s

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
bc = @(xl,ul,xr,ur,t) bcfun(xl,ul,xr,ur,t,D,J_0);

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
function [pl,ql,pr,qr] = bcfun(xl,ul,xr,ur,t,D,J_0)
    % Left boundary: f' = -J_0
    pl = J_0;
    ql = 1; % defines 'order'
    
    % Right boundary: u = 0
    pr = 0;
    qr = 1;
end

% Plot snapshots at selected times
figure;
hold on;

% Select snapshot times (e.g., at 0, 1, 2, 3, 4 time constants)
snapshot_times = [0, 0.1, 0.2, 0.5, 1.0, 2.0, 5.0] * t_c;

for i = 1:length(snapshot_times)
    % Find closest time index
    [~, idx] = min(abs(t - snapshot_times(i)));
    
    % Display as multiples of t_c
    t_normalized = t(idx)/t_c;
    plot(x, sol(idx,:), 'DisplayName', sprintf('t = %.1f t_c', t_normalized), 'LineWidth',2);
end

xlim([0,L]);
xlabel('x');
ylabel('u');
legend('Location', 'best');
grid on;
hold off;