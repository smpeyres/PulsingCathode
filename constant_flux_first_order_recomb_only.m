% script for calculating transient reaction-diffusion under first-order 
% recombination only - no substrate, steady flux to start

% Define dimensional parameters
L = 11.3; % domain length (arbitrary)
D = 3.4; % diffusion coefficient (arbitrary)
k = 1.4; % rate constant (arbitrary)

% Calculate intrinsic length, time scales
x_c = sqrt(D/k);
t_c = 1/k;

% Spatial mesh: 10 points per x_c
N_x = ceil(10 * L / x_c);
x = linspace(0, L, N_x);

% Time: solve for 5 time constants, 10 points per t_c
T_fin = 5*t_c;
N_t = ceil(10*T_fin);
t = linspace(0, T_fin, N_t);

% Solve
m = 0; % Cartesian coordinates

% Function handles
pde = @(x,t,u,dudx) pdefun(x,t,u,dudx,D,k);
ic = @icfun;
bc = @bcfun;

sol = pdepe(m, pde, ic, bc, x, t);

% Plot
surf(x,t,sol);
xlabel('x');
ylabel('t');
zlabel('u');

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
    u0 = 1;  % constant initial condition
end

function [pl,ql,pr,qr] = bcfun(xl,ul,xr,ur,t)
    % Left boundary: u = 0
    pl = ul;
    ql = 0;
    
    % Right boundary: u = 0
    pr = ur;
    qr = 0;
end