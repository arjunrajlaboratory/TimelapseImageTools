R = getrect;

D = dir('stitch*.jpg');

numFrames = numel(D);

im1 = imread('stitch1.jpg');

imcr = imcrop(im1,R);

movie = zeros([size(imcr) numFrames],'uint8');

for i = 1:numFrames
    fprintf('Processing image %d\n',i);
    im = imread(['stitch' num2str(i) '.jpg']);
    imcr = imcrop(im,R);
    movie(:,:,i) = imcr;
end