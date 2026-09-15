clear all;

% regression model of duty cycle, frequency, peak current, height on area

% data - duty cycle, frequency, peak current, height, area
% Most recent data: 09Sep2026
data = [...
5.0, 1.00E+03, 17.3, 1.9857, 0.0785;
10.0, 1.00E+03, 15.0, 2.0185, 0.0707;
50.0, 1.00E+03, 14.2, 1.8980, 0.2100;
50.0, 1.00E+03, 17.1, 1.9036, 0.2445;
5.0, 2.00E+03, 22.2, 1.9774, 0.1183;
10.0, 2.00E+03, 23.1, 2.0148, 0.1041;
15.0, 2.00E+03, 14.9, 2.0097, 0.0628;
15.0, 2.00E+03, 25.0, 2.0192, 0.1565;
5.0, 4.00E+03, 20.8, 1.9913, 0.2143;
10.0, 4.00E+03, 16.7, 2.0426, 0.1155;
5.0, 5.00E+03, 17.4, 2.0515, 0.2011;
10.0, 5.00E+03, 14.7, 2.0376, 0.1012;
15.0, 5.00E+03, 13.4, 2.0287, 0.0655;
15.0, 6.00E+03, 14.0, 2.0515, 0.0831;
20.0, 9.00E+03, 11.9, 2.0470, 0.0814;
10.0, 5.00E+02, 16.6, 2.0053, 0.1025;
25.0, 5.00E+02, 12.2, 1.3895, 0.1249;
50.0, 5.00E+02, 10.3, 1.3973, 0.1633;
25.0, 1.00E+03, 19.3, 1.3390, 0.1508;
50.0, 1.00E+03, 11.4, 1.3587, 0.1361;
50.0, 5.00E+03, 8.5, 1.3959, 0.1058;
90.0, 5.00E+02, 8.6, 1.3029, 0.1992;
50.0, 9.00E+03, 8.3, 1.3882, 0.0851;
75.0, 1.00E+03, 9.1, 1.3419, 0.1888;
90.0, 6.00E+01, 9.7, 1.3882, 0.2476];

% 1. Extract columns from your original 'data' matrix
duty   = data(:,1);
freq   = data(:,2);
peak   = data(:,3);
height = data(:,4);
area   = data(:,5); % dependent variable

% 2. Create the full table 
% Note: The dependent variable (Area) must be included in the table.
tbl_full = table(duty, freq, peak, height, area, ...
    'VariableNames', {'Duty', 'Freq', 'Peak', 'Height', 'Area'});

% 3. Run the stepwise regression
% - 'linear' is the starting point (checks basic x1, x2, x3, x4)
% - 'Upper', 'quadratic' allows it to test squared terms (like Duty^2) and interactions (like Duty*Peak)
% - 'Criterion', 'sse' uses F-tests (p-values) to strictly add/remove terms
mdl_step = stepwiselm(tbl_full, 'linear', ...
    'Upper', 'quadratic', ...
    'Criterion', 'sse');

% 4. Display the final equation it built
disp(mdl_step)

% Reduced model wighout height
tbl_red = table(duty, freq, peak, area, ...
    'VariableNames', {'Duty', 'Freq', 'Peak', 'Area'});

mdl_step_red = stepwiselm(tbl_red, 'linear', ...
    'Upper', 'quadratic', ...
    'Criterion', 'sse');

disp(mdl_step_red)