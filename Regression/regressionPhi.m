clear all;

% regression model of duty cycle, frequency on degree of depletion

% data - duty cycle, frequency, phi_d
data = [...
5, 7, 0.59;
10, 7, 1.40;
15, 7, 2.51;
20, 7, 2.67;
10, 9, 0.68;
12.5, 9, 1.21;
15, 9, 1.21;
20, 9, 1.41;
20, 9, 2.46];

% 1. Extract columns from your original 'data' matrix
duty   = log(data(:,1));
freq   = log(data(:,2));
phi   = log(data(:,3)); % dependent variable

% 2. Create the full table 
% Note: The dependent variable (Area) must be included in the table.
tbl_full = table(duty, freq, phi, ...
    'VariableNames', {'Duty', 'Freq', 'Phi'});

% 3. Run the stepwise regression
% - 'linear' is the starting point (checks basic x1, x2, x3, x4)
% - 'Upper', 'quadratic' allows it to test squared terms (like Duty^2) and interactions (like Duty*Peak)
% - 'Criterion', 'sse' uses F-tests (p-values) to strictly add/remove terms
mdl_step = stepwiselm(tbl_full, 'linear', ...
    'Upper', 'quadratic', ...
    'Criterion', 'sse');

% 4. Display the final equation it built
disp(mdl_step)
