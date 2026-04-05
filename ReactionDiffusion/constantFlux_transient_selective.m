% script for calculating steady reaction-diffusion under selective
% conditions, transient calculation, steady flux.

% Dimensional governing equations:
% E_t - D_e E_xx = - k E S
% S_t - D_s S_xx = - k E S
% BCs:
% E_x (x=0) = -J/D_e 
% E_x (x=delta) = 0
% S_x (x=0) = 0
% S (x=delta) = S_b
% E (x, t= 0) = 0
% S (x, t= 0) = S_b

% Define dimensional parameters : water, 200 mM chloroacetate
k = 1.5e6; % m3 mol-1 s-1
D_e = 4.9e-9; % m2 s-1
D_s = 1.1e-9; % m2 s-1
S_b = 99; % mol m-3
J = 1.3e-1; % mol m-2 s-1
delta = 8.4e-7; % m

% Calculate intrinsic length scales
x_e = sqrt(D_e/(k*S_b)); % electron
x_s = ((D_s*D_e)/(k*J))^(1/3); % substrate
% Define minimum length scale
xc_min = min([x_e,x_s]);

% calculate timescales
t_D = (delta^2)/D_s; % substrate diffusion across film
t_e = (k*S_b)^(-1); % electron
t_s = (D_e^2/(D_s*k^2*J^2))^(1/3); % substrate
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

% Time mesh : three segments to capture multi-scale without huge memory
% Points per segment
N = 50;
% Segment 1: resolve electron dynamics, from 0 to 5*t_e
seg1 = linspace(0, 5*t_e, N);
% Segment 2: resolve substrate dynamics, from 5*t_e to 5*t_s
seg2 = linspace(5*t_e, 5*t_s, N);
% Segment 3: resolve diffusion dynamics, from 5*t_s to 5*t_D
seg3 = linspace(5*t_s, 5*t_D, N);
% Concatenate and remove duplicate boundary points
t = unique([seg1, seg2, seg3]);

% Solve
m = 0; % Cartesian coordinates

% Using "Solve Systems of PDEs" Example to help
% https://www.mathworks.com/help/matlab/math/solve-system-of-pdes.html

% code equation
% here u(1) = E, u(2) = S
function [c,f,s] = pdefun(x,t,u,dudx,D_e,D_s,k)
    c = [1; 1];
    f = [D_e; D_s] .* dudx;
    F_e = - k * u(1) * u(2);
    F_s = - k * u(1) * u(2);
    s = [F_e; F_s];
end

% code ICs
function u0 = pdeic(x,S_b)
    u0 = [0; S_b];
end

% code BCs
% Naturally concentration, flux-based
function [pl,ql,pr,qr] = bcfun(xl,ul,xr,ur,t,J,S_b)
    % Left boundary: f(1) = -J
    % Left boundary: f(2) = 0
    pl = [J; 0];
    ql = [1; 1]; % defines 'order'
    
    % Right boundary: f(1) = 0
    % Right boundary: u(2) = S_b
    pr = [0; ur(2) - S_b];
    qr = [1; 0];
end

% Function handles
pde = @(x,t,u,dudx) pdefun(x,t,u,dudx,D_e,D_s,k);
ic = @(x) pdeic(x,S_b);
bc = @(xl,ul,xr,ur,t) bcfun(xl,ul,xr,ur,t,J,S_b);

% Solve equation
sol = pdepe(m,pde,ic,bc,x,t);

% PLOT 1: Spatial profiles of electron at different times
figure;
hold on;
% Select snapshot times
seg_1_e = [0, 0.1, 0.2, 0.5, 1.0, 2.0, 5.0] * t_e;
seg_2_e = [0.1, 0.2, 0.5, 1.0] * t_s;
snapshot_times_e = unique([seg_1_e, seg_2_e]);
for i = 1:length(snapshot_times_e)
% Find closest time index
    [~, idx] = min(abs(t - snapshot_times_e(i)));
% Display as multiples of t_e
    t_norm_e = t(idx)/t_e;
    plot(x/1e-9, sol(idx,:,1), 'DisplayName', sprintf('t = %.1f t_e', t_norm_e), 'LineWidth',2);
end

xlim([0,x_s/1e-9]);
xlabel('x [nm]');
ylabel('C_e [mM]');
legend('Location', 'best');
grid on;
hold off;

% PLOT 2: Spatial profiles of substrate at different times
figure;
hold on;
% Select snapshot times 
seg_1_s = [0, 1.0, 2.0, 5.0] * t_e;
seg_2_s = [0.1, 0.2, 0.5, 1.0, 2.0, 5.0] * t_s;
seg_3_s = [0.1, 0.2, 0.5, 1.0, 2.0, 5.0] * t_D;
snapshot_times_s = unique([seg_1_s, seg_2_s, seg_3_s]);
for i = 1:length(snapshot_times_s)
% Find closest time index
    [~, idx] = min(abs(t - snapshot_times_s(i)));
% Display as multiples of t_D
    t_norm_D = t(idx)/t_D;
    plot(x/1e-6, sol(idx,:,2), 'DisplayName', sprintf('t = %.2f t_D', t_norm_D), 'LineWidth',2);
end

xline(x_s/1e-6, 'LineWidth', 2, 'Color','k','LineStyle','--', 'DisplayName','x_s')
xlim([0,delta/1e-6]);
xlabel('x [um]');
ylabel('C_s [mM]');
legend('Location', 'best');
grid on;
hold off;

