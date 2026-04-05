% simple check to make a pulse train

freq = 1000; % Hz
period = 1/freq; % seconds
duty = 0.01;
J_peak = 1e-1; % mol/m^2-s

% Ensure at least 10 points per "on" phase
T_fin = 2*period;
points_per_on = 10;
N_periods = T_fin / period;
N_t = ceil(points_per_on / duty * N_periods);
t = linspace(0, T_fin, N_t);
t_mod = mod(t,period);

J_0 = zeros(size(t)); % Initialize the pulse train
J_0(t_mod < duty * period) = J_peak; % Set pulse values based on duty cycle

% Plot snapshots at selected times
figure;

plot(t, J_0, 'LineWidth',2);

xlim([0,T_fin]);
xlabel('t');
ylabel('J_0');
grid on;
hold off;