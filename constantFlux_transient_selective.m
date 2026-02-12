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
S_b = 2.0e2; % mol m-3
J = 1.3e-1; % mol m-2 s-1
delta = 8.4e-7; % m

% Calculate intrinsic length scales
x_e = sqrt(D_e/(k*S_b)); % electron
x_s = ((D_s*D_e)/(k*J))^(1/3); % substrate
% Define minimum length scale
xc_min = min(x_e,x_s);

% calculate timescales
t_D = (delta^2)/D_s; % substrate diffusion across film
t_e = (k*S_b)^(-1); % electron
t_s = (D_e^2/(D_s*k^2*J^2))^(1/3); % substrate
% Calculate minimum time scale
tc_min = min(t_D, t_e, t_s);
% Calculate maximum time scale
tc_max = max(t_D, t_e, t_s);

% # of minimum lengthscales in domain
numLengths = ceil(delta/xc_min);
% desired number of mesh points per minimum lengthscale
numPointsPerLength = 20;
% Calculate total # mesh points
N_x = numPointsPerLength*numLengths;
% Create uniform mesh
x = linspace(0,delta,N_x);

% Time: solve for 5 times longest time
T_fin = 5*tc_max;
% # of minimum timesscales in T_fin
numTimes = ceil(T_fin/tc_min);
% desired number of time steps per minimum timescale
numPointsPerTime = 10;
% Calculate total # time steps points
N_t = numPointsPerTime*numTimes;
% Create uniform mesh
t = linspace(0,T_fin,N_t);
% Note: pdepe naturally uses adaptive time-stepping

% Solve
m = 0; % Cartesian coordinates