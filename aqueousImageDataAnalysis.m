% Analysis of aqueous image data
clear;

% Matsusada (mA), duty cycle (%), frequency (Hz), 
% c1 anode spot (mm^2), c1 error anode spot (mm^2),
data = [3, 25, 500, 0.2906, 0.2927 - 0.2906;
        4.6, 50, 500, 0.3199, 0.3226 - 0.3199;
        5.5, 75, 5e3, 0.2966, 0.2989 - 0.2966;
        5, 25, 1e3, 0.3185, 0.3207 - 0.3185;
        5, 50, 5e3, 0.2612, 0.2632 - 0.2612;
        5, 50, 1e3, 0.3054, 0.3072 - 0.3054;
        6.5, 90, 500, 0.3541, 0.357 - 0.3541;
        6, 50, 9e3, 0.2386, 0.2402 - 0.2386;
        6, 75, 1e3, 0.3328, 0.3351 - 0.3328;
        7.2, 90, 60, 0.3809, 0.3842 - 0.3809];

c1Values = data(:,4);
sigmaValues = sqrt(c1Values./2);
c1ErrorValues = data(:,5);
sigmaErrorValues = sqrt(c1ErrorValues./2);
data = [data sigmaValues sigmaErrorValues];

oneSigmaArea = pi.*(sigmaValues).^2;
twoSigmaArea = pi.*(2.*sigmaValues).^2;
data = [data oneSigmaArea twoSigmaArea];

% dA = 2*pi*sigma*dsigma
oneSigmaAreaMargin = 2.*pi.*sigmaValues.*sigmaErrorValues;
data = [data oneSigmaAreaMargin];

meanArea = mean(oneSigmaArea, "all");
stdDevMeanMeanArea = sqrt(sum((meanArea - oneSigmaArea).^2, "all")./(size(oneSigmaArea,1) - 1));
nineFiveMarginMeanArea = 2*stdDevMeanMeanArea;