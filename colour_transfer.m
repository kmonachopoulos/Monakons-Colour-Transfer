%-------------------------------------------------------------------------%
%  Project       : Colour Transfer                                        %
%  File          : Colour_Transfer.m                                      %
%  Description   : Colour Transfer between Images                         %
%  Author        : Monachopoulos Konstantinos                              %
%-------------------------------------------------------------------------%

clc;clear;close all;

% Read Source and Target Images
source_image_rgb=imread('source_image.jpg');
target_image_rgb=imread('target_image.jpg');

if size(target_image_rgb,1) > size(source_image_rgb,1) || size(target_image_rgb,2)> size(source_image_rgb,2)
    for i=1:3
        Tmp_source_image_rgb(:,:,i)=imresize( source_image_rgb(:,:,i) , size(target_image_rgb(:,:,i)) );
    end
    source_image_rgb=Tmp_source_image_rgb;  
end

% Show Source and Target Images
subplot(1,3,1),imshow(source_image_rgb);
title('Source Image')
subplot(1,3,2),imshow(target_image_rgb);
title('Target image')

% RGB to Lab conversion
labTransformation = makecform('srgb2lab');
source_image_lab = applycform(source_image_rgb,labTransformation);
target_image_lab = applycform(target_image_rgb,labTransformation);
source_image_lab = lab2double(source_image_lab);
target_image_lab = lab2double(target_image_lab);

% Initialize matrices (optional)
standar_deviation_source=zeros(3,1);
standar_deviation_target=zeros(3,1);
mean_value_source=zeros(1,3);
mean_value_target=zeros(1,3);
final_target_image_lab=zeros(size(target_image_lab,1),size(target_image_lab,2),size(target_image_lab,3));

% Standar deviation and mean value
standar_deviation_source(:,1)=std2(source_image_lab);
standar_deviation_target(:,1)=std2(target_image_lab);

% Mean value for every layer
for i=1:3
    mean_value_source(i)=mean2(source_image_lab(:,:,i));
    mean_value_target(i)=mean2(target_image_lab(:,:,i));
end

% Calculate the final Image in Lab colour space
for k=1:size(source_image_lab,3)
    for i=1:size(source_image_lab,1)
        for j=1:size(source_image_lab,2)
            final_target_image_lab(i,j,k)=((standar_deviation_target(k,1)/standar_deviation_source(k,1))*(source_image_lab(i,j,k)-mean_value_source(k)))+mean_value_target(k);
        end
    end
end

% Thresholds
T1 = 0.008856;
T2 = 0.206893;

% Lab to XYZ conversion
[M, N] = size(final_target_image_lab(:,:,1));
s = M * N;
L = reshape(final_target_image_lab(:,:,1), 1, s);
a = reshape(final_target_image_lab(:,:,2), 1, s);
b = reshape(final_target_image_lab(:,:,3), 1, s);
fY = ((L + 16) / 116) .^ 3;
YT = fY > T1;
fY = (~YT) .* (L / 903.3) + YT .* fY;
Y = fY;
fY = YT .* (fY .^ (1/3)) + (~YT) .* (7.787 .* fY + 16/116);
fX = a / 500 + fY;
XT = fX > T2;
X = (XT .* (fX .^ 3) + (~XT) .* ((fX - 16/116) / 7.787));
fZ = fY - b / 200;
ZT = fZ > T2;
Z = (ZT .* (fZ .^ 3) + (~ZT) .* ((fZ - 16/116) / 7.787));

% Normilize white pixels following the D65 standard 
X = X * 0.950456;
Z = Z * 1.088754;

% XYZ to RGB conversion
MAT = [ 3.240479 -1.537150 -0.498535;
    -0.969256  1.875992  0.041556;
    0.055648 -0.204043  1.057311];
RGB = max(min(MAT * [X; Y; Z], 1), 0);

final_target_image_rgb(:,:,1) = reshape(RGB(1,:), M, N);
final_target_image_rgb(:,:,2) = reshape(RGB(2,:), M, N);
final_target_image_rgb(:,:,3) = reshape(RGB(3,:), M, N);

% Show the final Results
subplot(1,3,3),imshow(final_target_image_rgb);
title('Results after colour transfer')
