% script for calculating steady reaction-diffusion under selective
% conditions, steady state calculation, steady flux.

% Dimensional governing equations:
% D_e E_xx = k E S
% D_s S_xx = k E S
% BCs:
% E_x (x=0) = -J/D_e 
% E_x (x=delta) = 0
% S_x (x=0) = 0
% S (x=delta) = S_b

% Define dimensional parameters : water, 200 mM chloroacetate
k = 1.5e6; % m3 mol-1 s-1
D_e = 4.9e-9; % m2 s-1
D_s = 1.1e-9; % m2 s-1
S_b = 2.0e2; % mol m-3
J = 1.3e-1; % mol m-2 s-1
delta = 8.4e-7; % m

% Calculate intrinsic length scales
xc_1 = sqrt(D_e/(k*S_b));
xc_2 = ((D_s*D_e)/(k*J))^(1/3);
% Define minimum length scale
xc_min = min(xc_1,xc_2);

% Calculate intrinsic electron concentration scales
Ec_1 = J*delta/D_e;
Ec_2 = D_s/(k*delta*delta);
Ec_3 = J/sqrt(D_e*k*S_b);
Ec_4 = S_b*D_s/D_e;

% generate mesh
x = generateMesh(delta,xc_min);

% Configure solver tolerances
options = bvpset('RelTol', 1e-5, 'AbsTol', 1e-7);

% Define ODE system and boundary conditions
odefun = @(x, y) systemEquations(x, y, k, D_e, D_s);
bcfun = @(ya, yb) boundaryConditions(ya, yb, J, D_e, S_b);

% Initial guess
solinit = bvpinit(x, @(x) initialGuess(x, Ec_3, xc_1, S_b));

% Solve directly with bvp4c
fprintf('Solving system...\n');
sol = bvp4c(odefun, bcfun, solinit, options);
fprintf('Solution complete\n');

% Nested functions used above

function x = generateMesh(delta,xc_min)
    % # of minimum lengthscales in domain
    numLengths = ceil(delta/xc_min);
    % desired number of mesh points per minimum lengthscale
    numPointsPerLength = 20;
    % Calculate total # mesh points
    numPoints = numPointsPerLength*numLengths;
    % Create uniform mesh
    x = linspace(0,delta,numPoints);
end

function dydx = systemEquations(x, y, k, D_e, D_s)
    % System of ODEs
    % y(1) - radical concentration
    % y(2) - radical gradient
    % y(3) - substrate concentration
    % y(4) - substrate gradient
    % Recall:
    % D_e E_xx = k E S
    % D_s S_xx = k E S

    
    dydx = [y(2);
            k*y(1)*y(3)/D_e;
            y(4);
            k*y(1)*y(3)/D_s];
end

function res = boundaryConditions(ya, yb, J, D_e, S_b)
    % Boundary conditions at x=0 (ya) and x=1 (yb)
    % Written such that entry = 0
    % Recall:
    % E_x (x=0) = -J/D_e 
    % E_x (x=delta) = 0
    % S_x (x=0) = 0
    % S (x=delta) = S_b
    res = [ya(2) + J/D_e;   % Flux condition at x=0 for radical
           yb(2);       % Zero gradient at x=1 for radical
           ya(4);       % Zero gradient at x=0 for substrate
           yb(3) - S_b];  % Fixed concentration at x=1 for substrate
end

function y0 = initialGuess(x,Ec_3,xc_1,S_b)
    % Simple physics-based initial guess

    % Electron profile: exponential decay 
    E = Ec_3*exp(-x/xc_1);
    dEdx = Ec_3*exp(-x/xc_1)/xc_1;
    
    % Substrate profile: flat
    S = S_b;
    dSdx = 0;
    
    y0 = [E; dEdx; S; dSdx];
end

% PLOT: Spatial profiles

figure;
hold on;

plot(sol.x/1e-6, sol.y(1,:), 'DisplayName', 'Electron', 'LineWidth',2);
plot(sol.x/1e-6, sol.y(3,:), 'DisplayName', 'Substrate', 'LineWidth', 2);
xlim([2e-10/1e-6,delta/1e-6]);
ylim([1e-4,1e3]);
xlabel('x [um]');
ylabel('Concentration [mM]');
legend('Location', 'best');
xscale log;
yscale log;
grid on;
hold off;