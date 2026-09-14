% Test of processing images for area calculation
clear;

%% Load image

rgbImage = imread("30Mar2026/7.2mA_90per_60Hz_30Mar2026.jpg");
% Creates 3D matrix:
% The first dimension represents the height (rows).
% The second dimension represents the width (columns).
% The third dimension represents the color channels (Red, Green, Blue).

%% Calculate length per pixel from tube reference

% Show image to user
imshow(rgbImage);
title('Select the left and right edges of the tube');

% Prompt user to select points on tube
title('Select the left edge of the tube');
leftEdge = ginput(1); % Returns [x, y] coordinates
title('Select the right edge of the tube');
rightEdge = ginput(1);

% Calculate number of horizontal pixels between edges
if leftEdge(1) > rightEdge(1)
    % Swap points if selected in reverse order
    temp = leftEdge;
    leftEdge = rightEdge;
    rightEdge = temp;
end
pixelDiameter = abs(rightEdge(1) - leftEdge(1));

% Calculate conversion factor from known tube diameter
tubeDiameter = 6.35; % mm
mmPerPixel = tubeDiameter / pixelDiameter; % mm/pixel
disp(['Conversion factor: ', num2str(mmPerPixel), ' mm/pixel. Press any key to continue.']);

% Visualization selection for validation
title(['Conversion factor: ', num2str(mmPerPixel), ' mm/pixel. Press any key to continue.']);
hold on;
plot([leftEdge(1), rightEdge(1)], [leftEdge(2), rightEdge(2)], 'r-', 'LineWidth', 2);
plot([leftEdge(1), rightEdge(1)], [leftEdge(2), leftEdge(2)], 'r--', 'LineWidth', 2);
hold off;

% Pause for user
pause;

%% Calculate height of discharge
% Show image to user
imshow(rgbImage);
title('Select the top and bottom of discharge');

% Prompt user to select points on discharge
title('Select the top of discharge');
topPoint = ginput(1); % Returns [x, y] coordinates
title('Select the bottom of discharge');
bottomPoint = ginput(1);

% Calculate number of vertical pixels between points
if topPoint(2) > bottomPoint(2)
    % Swap points if selected in reverse order
    temp = topPoint;
    topPoint = bottomPoint;
    bottomPoint = temp;
end
pixelHeight = abs(bottomPoint(2) - topPoint(2));
dischargeHeight = pixelHeight * mmPerPixel;
disp(['Discharge height ', num2str(dischargeHeight), ' mm. Press any key to continue.']);

% Visualization selection for validation
title(['Discharge height ', num2str(dischargeHeight), ' mm. Press any key to continue.']);
hold on;
plot([topPoint(1), bottomPoint(1)], [topPoint(2), bottomPoint(2)], 'r-', 'LineWidth', 2);
plot([topPoint(1), topPoint(1)], [topPoint(2), bottomPoint(2)], 'r--', 'LineWidth', 2);
hold off;

% Pause for user
pause;


%% Prepare image for Gaussian fit

% Display image
imshow(rgbImage,[]);
title('Select ROI around the plasma-liquid spot. Make it wide and thin!');

% Select appropriate region of interest
% Tip: only get lower part of discharge to avoid glow along needle tip
% Get entirety of plasma spot with very wide window
% Let the user draw a rectangle
roi = drawrectangle;
% Wait for the user to finish positioning the rectangle
position = roi.Position;
% position contains the coordinates of the rectangle in the form
% [x_min, y_min, width, height]

% Crop image
croppedImage = imcrop(rgbImage, position);

% Display cropped image
imshow(croppedImage);
title('Cropped ROI. Press any key to continue.');
pause;

% Grayscale the cropped image and display
croppedImageGray = rgb2gray(croppedImage);
rescaledCroppedImageGray = rescale(croppedImageGray);
imshow(rescaledCroppedImageGray);
title('Cropped ROI in rescaled grayscale.')

% Compute centroid
[rows, cols] = size(rescaledCroppedImageGray);
totalMass = sum(rescaledCroppedImageGray(:));
x = 1:cols;
y = 1:rows;
centroidX = sum(sum(rescaledCroppedImageGray) .* x) / totalMass;
centroidY = sum(sum(rescaledCroppedImageGray, 2)' .* y) / totalMass;

% Show position of centroid
imshow(rescaledCroppedImageGray);

hold on;
sz = 100;
scatter(centroidX, centroidY, sz, "filled", "red"); % Plot the point
hold off;
title(['Centroid coordinates: (', num2str(centroidX), ', ', num2str(centroidY), '). Press any key to continue.']);
pause;

% find nearest pixel to centroid
centroidPixel = [round(centroidX),round(centroidY)];
disp(centroidPixel);

% get row associated with that pixel
centroidRowLum = rescaledCroppedImageGray(centroidPixel(2),:);

% develop x values for that row
numPixelsCentroidRow = length(centroidRowLum);
centroidRowLength = mmPerPixel*linspace(-round(numPixelsCentroidRow/2), round(numPixelsCentroidRow/2), numPixelsCentroidRow);

%% Fit Gaussian with cubic background

% Initial Gaussian fit from Curve Fitting Toolbox, display automatically
fInit = fit(centroidRowLength.', centroidRowLum.', 'gauss1');
coeffsInit = coeffvalues(fInit);

% create Gaussian + poly5 model:
g = fittype("a1 + b1*x + c1*x^2 + d1*x^3 + e1*x^4 + a2*exp(-((x-b2)/c2)^2)", ...
    dependent="y", independent="x", ...
    coefficients = ["a1" "b1" "c1" "d1" "e1" "a2" "b2" "c2"]);

f = fit(centroidRowLength.', centroidRowLum.', g, 'StartPoint', horzcat([0,0,0,0,0],coeffsInit));

% plot the fit versus data
plot(f,centroidRowLength, centroidRowLum)

%% Calculate area and area uncertainty

% Standard deviation = c_1/sqrt(2)
% Extract coefficients from the Gaussian fit
coeffs = coeffvalues(f);
stdDev = coeffs(8) / sqrt(2);
confInt = confint(f);

stdDevCI_upper = confInt(2, 8) / sqrt(2); % Upper bound

dSigma = stdDevCI_upper - stdDev;

area = pi*stdDev^2
dArea = 2*pi*stdDev*dSigma
