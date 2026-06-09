clear all; close all; clc;

Csub = 20; % mM
F = 96485; %C/mol
A = 0.5e-6; %m^2
Dsub = 1.1e-9; % m^2/s
iPeak = 15e-3; %A
kr = 8e6; % 1/s
ks = 1.5e6; %m^3/mol-s

t_dep = (pi*F*F*A*A*Dsub/(4*iPeak*iPeak))*((Csub - kr/ks)^2);

% time array
tVals = [0, 0.1*t_dep, t_dep, 10*t_dep];

% Calculate concentration profile - transient
xVals = linspace(0,0.3e-6,100);

% Calculate the concentration profile using Fick's second law
function res = concProf(t,Csub,iPeak,F,A,Dsub,xVals)
    res = Csub - (iPeak/(F*A*Dsub)).*(2 * (Dsub*t/pi)^0.5 .* exp(-xVals.^2 ./ (4*Dsub*t)) ...
    - xVals.* erfc ( xVals ./ (4*Dsub*t)^0.5));
end

res01 = concProf(0.2*t_dep,Csub,iPeak,F,A,Dsub,xVals);
res1 = concProf(t_dep,Csub,iPeak,F,A,Dsub,xVals);
res10 = concProf(1.85*t_dep,Csub,iPeak,F,A,Dsub,xVals);


plot(xVals/sqrt(Dsub*t_dep),res01, 'LineWidth', 2);
hold on;
plot(xVals/sqrt(Dsub*t_dep),res1, 'LineWidth', 2);
plot(xVals/sqrt(Dsub*t_dep),res10, 'LineWidth', 2);
yticks([0,5.3333,20]);
yticklabels({'0','C_s = k_r/k_s', 'C_s = C_{s,i}'});
ylabel("Substrate Concentration, C_s");
xlabel("Depth, x/(D_{sub}t*)^{0.5}");
xlim([0,6]);
hold off;
