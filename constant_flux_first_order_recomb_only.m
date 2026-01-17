% script for calculating transient reaction-diffusion under first-order 
% recombination only - no substrate, steady flux to start

% Define some parameters
L = 10; % domain length (arbitrary)
D = 0.1; % diffusion coefficient (arbitrary)
k = 0.5; % rate constant (arbitrary)
T = 50; % final time (arbitrary)

% Spatial, time mesh
x = linspace(0, L, 100);
t = linspace(0, T, 200);

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