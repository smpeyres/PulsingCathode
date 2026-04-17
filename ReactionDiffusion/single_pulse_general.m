% script for calculating transient reaction-diffusion under general
% conditions, single pulse.
clear all;

% Dimensional governing equations:
% E_t - D_e E_xx = - ks E S - kr E
% S_t - D_s S_xx = - ks E S
% BCs:
% E_x (x=0) = -J(t)/D_e 
% E_x (x=delta) = 0
% S_x (x=0) = 0
% S (x=delta) = S_b
% E (x, t= 0) = 0
% S (x, t= 0) = S_b

% Define dimensional parameters : water, 20 mM chloroacetate
k_s = 1.5e6; % m3 mol-1 s-1
k_2 = 5.5e6; % m^3/mol-s
D_e = 4.9e-9; % m2 s-1
D_s = 1.1e-9; % m2 s-1
S_b = 20; % mol m-3
delta = 1e-6; % m

% Pulse parameters
f = 5e4;          % frequency [Hz] — pick based on your timescales
T = 1/f;          % period [s]
alpha = 0.50;      % duty cycle (t_on / T)
i_peak = 9.84; % mA
area = 0.49; % mm^2
faraday = 96845; % C/mol
J_peak = i_peak*1e-3/(area*1e-6*faraday); % mol m^-2 s^-1

% Calculate intrinsic length scales
x_e = sqrt(D_e/(k_s*S_b)); % electron
x_s = ((D_s*D_e)/(k_s*J_peak))^(1/3); % substrate
% Define minimum length scale
xc_min = min([x_e,x_s]);

% calculate timescales
t_D = (delta^2)/D_s; % substrate diffusion across film
t_e = (k_s*S_b)^(-1); % electron
t_s = (D_e^2/(D_s*k_s^2*J_peak^2))^(1/3); % substrate
% Calculate minimum time scale
tc_min = min([t_D, t_e, t_s]);
% Calculate maximum time scale
tc_max = max([t_D, t_e, t_s]);

% # of minimum lengthscales in domain
numLengths = ceil(delta/xc_min);
% desired number of mesh points per minimum lengthscale
numPointsPerLength = 20;
% Calculate total # mesh points
N_x = numPointsPerLength*numLengths;
% Create uniform mesh
x = linspace(0,delta,N_x);

% Uniform time mesh across a reasonable number of periods
points_per_period = 400;
t = linspace(0, T, points_per_period);

% Solve
m = 0; % Cartesian coordinates

% Using "Solve Systems of PDEs" Example to help
% https://www.mathworks.com/help/matlab/math/solve-system-of-pdes.html

% code equation
% here u(1) = E, u(2) = S
function [c,f,s] = pdefun(x,t,u,dudx,D_e,D_s,k_s,k_2)
    c = [1; 1];
    f = [D_e; D_s] .* dudx;
    F_e = - k_s * u(1) * u(2) - 2 * k_2 * u(1) * u(1);
    F_s = - k_s * u(1) * u(2);
    s = [F_e; F_s];
end

% code ICs
function u0 = pdeic(x,S_b)
    u0 = [0; S_b];
end

% code BCs
% Naturally concentration, flux-based
function [pl,ql,pr,qr] = bcfun(xl,ul,xr,ur,t,J_peak,T,alpha,S_b)
    J_t = pulsedFlux(t, J_peak, T, alpha);
    
    % Left boundary: f(1) = -J(t), f(2) = 0
    pl = [J_t; 0];
    ql = [1; 1];
    
    % Right boundary: f(1) = 0, u(2) = S_b
    pr = [0; ur(2) - S_b];
    qr = [1; 0];
end

function J_t = pulsedFlux(t, J_peak, T, alpha)
    % Position within current period, normalized to [0, 1)
    phase = mod(t, T) / T;
    if phase < alpha
        J_t = J_peak;  % pulse on
    else
        J_t = 0;       % pulse off
    end
end

% Function handles
pde = @(x,t,u,dudx) pdefun(x,t,u,dudx,D_e,D_s,k_s,k_2);
ic = @(x) pdeic(x,S_b);
bc = @(xl,ul,xr,ur,t) bcfun(xl,ul,xr,ur,t,J_peak,T,alpha,S_b);

% Solve equation
% Tight MaxStep
t_on = alpha * T;
options = odeset('MaxStep', t_on/10);
sol = pdepe(m, pde, ic, bc, x, t, options);

% opts = odeset('MaxStep', T/10, 'RelTol', 1e-5, 'AbsTol', 1e-8);
% sol = pdepe(m, pde, ic, bc, x, t, opts);

% PLOT 1: Spatial profiles of electron at different times
figure;
hold on;
% Plot every 10 timesteps (including first and last)
step = 10;
time_indices = 1:step:size(sol,1);
% Ensure last timestep is included
if time_indices(end) ~= size(sol,1)
    time_indices = [time_indices, size(sol,1)];
end
plot(x/1e-9, sol(time_indices,:,1));
xlim([0,x_s/1e-9]);
xlabel('x [nm]');
ylabel('C_e [mM]');
legend('Location', 'best');
grid on;
hold off;

% PLOT 2: Spatial profiles of substrate at different times
figure;
hold on;
% Plot every 10 timesteps (including first and last)
step = 10;
time_indices = 1:step:size(sol,1);
% Ensure last timestep is included
if time_indices(end) ~= size(sol,1)
    time_indices = [time_indices, size(sol,1)];
end
plot(x/1e-6, sol(time_indices,:,2));
xlim([0,delta/1e-6]);
xlabel('x [um]');
ylabel('C_s [mM]');
legend('Location', 'best');
grid on;
hold off;

% Calculate single-pulse faradaic efficiency
substrateRate = trapz(x, k_s.*sol(:,:,2).*sol(:,:,1), 2);
substrateTotal = trapz(t, substrateRate);

electronRate = trapz(x, 2*k_2.*sol(:,:,1).*sol(:,:,1) +  k_s.*sol(:,:,2).*sol(:,:,1), 2);
electronTotal = trapz(t, electronRate);

FE = 1e2*substrateTotal/electronTotal;
