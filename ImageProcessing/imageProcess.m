% Test of processing images for area calculation
clear;

%% Load image

rgbImage = imread("09Sep2026/1kHz_5%_1.3mA.jpg");
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
hold off;

% Pause for user
pause;


%% Prepare image for Gaussian fit

% Display image
imshow(rgbImage,[]);
title('Select ROI around the plasma-liquid spot. Make it tight!');

% Select appropriate region of interest
% Tip: only get lower part of discharge to avoid glow along needle tip
% and to get entirety of plasma spot
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
imshow(croppedImageGray,[]);
title('Cropped ROI in Grayscale.')

% Compute centroid
[rows, cols] = size(croppedImageGray);
totalMass = sum(croppedImageGray(:));
x = 1:cols;
y = 1:rows;
centroidX = sum(sum(croppedImageGray) .* x) / totalMass;
centroidY = sum(sum(croppedImageGray, 2)' .* y) / totalMass;

% Show position of centroid
imshow(croppedImageGray);

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
centroidRowLum = croppedImageGray(centroidPixel(2),:);

% remove some background
centroidRowLum = centroidRowLum - min(centroidRowLum);

% develop x values for that row
numPixelsCentroidRow = length(centroidRowLum);
centroidRowLength = mmPerPixel*linspace(-round(numPixelsCentroidRow/2), round(numPixelsCentroidRow/2), numPixelsCentroidRow);

%% Perform the Gaussian fit

% Use fit from Curve Fitting Toolbox, display automatically
f = fit(centroidRowLength.', centroidRowLum.', 'gauss1')

% plot the fit versus data
plot(f,centroidRowLength, centroidRowLum)

% Standard deviation = c_1/sqrt(2)
% Extract coefficients from the Gaussian fit
coeffs = coeffvalues(f);
stdDev = coeffs(3) / sqrt(2); % Standard deviation from the fit

% Extract confidence intervals for the standard deviation
confInt = confint(f);
stdDevCI = confInt(1, 3) / sqrt(2); % Lower bound
stdDevCI_upper = confInt(2, 3) / sqrt(2); % Upper bound

dSigma = stdDevCI_upper - stdDev;
area = pi*stdDev^2;
dArea = 2*pi*stdDev*dSigma;