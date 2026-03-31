% Areas - aqueous 200 mM NaClO4 - 30 March 2026

% sample = [current, duty, freq, diameter]
% mA, %, Hz, mm
s1 = [6; 50; 9e3; 0.49];
s2 = [7.2; 90; 60; 0.67];
s3 = [4.6; 50; 500; 0.54];
s4 = [5; 50; 5e3; 0.50];
s5 = [5.5; 75; 5e3; 0.55];
s6 = [6.5; 10; 10e3; 0.62];
s7 = [6.5; 90; 500; 0.64];
s8 = [3; 25; 500; 0.57];
s9 = [6; 75; 1e3; 0.44];
s10 = [5; 25; 1e3; 0.44];
s11 = [5; 50; 1e3; 0.54];
samples = [s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11];
diameterError = 0.03; % mm, likely an underestimate

function [area, areaError] = areaWithError(diameter, diameterError)
    area = pi*(diameter/2)^2;
    areaError = area*2*diameterError/diameter;
end

for element = samples
    [sampleArea, sampleAreaError] = areaWithError(element(1),diameterError);
    
end