
% ims = zeros(1024,1024,196,'uint16');
% 
% 
% for i = 1:196
%     name = ['Scan611_w1_s' num2str(i) '_t1.TIF'];
%     ims(:,:,i) = imread(name);
% end;
% 
% 
% im1 = ims(:,:,36);
% im2 = ims(:,:,37);
% 
% im1 = double(scale(im1));
% im2 = double(scale(im2));
% 
% overlap = 100;
% 
% im11 = im1(end-overlap:end,:);
% 
% im22 = im2(1:overlap+1,:);
% 
% [optimizer, metric]  = imregconfig('monomodal');
% registered = imregister(im11,im22,'translation',optimizer,metric);
% imshowpair(registered,im22)
% imshow([im11;im22])
% 
% 
% %im11 = im11
% 
% [moving_out,fixed_out] = cpselect(im2,im1,'Wait',true);
% 
% load transform_coords.mat
% 
% imtest = zeros(2048,1050);
% 
% 
% transform_coords = round(median(moving_out-fixed_out));
% 
% imtest( -transform_coords(2):-transform_coords(2)+1023, ... 
%     -transform_coords(1)+25:-transform_coords(1)+1023+25) = im2;
% 
% 
% imtest(1:1024,1+25:1024+25) = im1;
%******************

currentTime = 1;

for currentTime = 1:1
    numPositions = 289;
    numXPositions = 17;
    numYPositions = 17;
    
    
    arrayOfPositions = 1:numPositions;
    matrixOfPositions = reshape(arrayOfPositions,numXPositions,numYPositions);
    
%     for i = 2:2:numXPositions
%        matrixOfPositions(:,i) = flipud(matrixOfPositions(:,i));
%     end
    
    registerPosition.row = 8;
    registerPosition.col = 8;
    
    imagesize = 1024;
    
    
    
    ims = zeros(imagesize,imagesize,numPositions,'uint16');
    
    for i = 1:numPositions
        name = ['Scan' num2str(currentTime,'%3.3d') '_w1_s' num2str(i) '_t1.TIF'];
        ims(:,:,i) = imread(name);
    end
    
    
    %im1 = ims(:,:,36);
    %im2 = ims(:,:,37);
    
    
    if exist('transform_coords.mat','file')
        load transform_coords.mat
    else
        % First, register the column
        im1 = ims(:,:,matrixOfPositions(registerPosition.row,registerPosition.col));
        im2 = ims(:,:,matrixOfPositions(registerPosition.row+1,registerPosition.col));
        im1 = double(scale(im1));
        im2 = double(scale(im2));
        
        [moving_out,fixed_out] = cpselect(im1,im2,'Wait',true);
        
        columnTransformCoords = round(median(moving_out-fixed_out));
        
        % Next, register the rows
        im1 = ims(:,:,matrixOfPositions(registerPosition.row,registerPosition.col));
        im2 = ims(:,:,matrixOfPositions(registerPosition.row,registerPosition.col+1));
        im1 = double(scale(im1));
        im2 = double(scale(im2));
        
        [moving_out,fixed_out] = cpselect(im1,im2,'Wait',true);
        
        rowTransformCoords = round(median(moving_out-fixed_out));
        save transform_coords.mat columnTransformCoords rowTransformCoords
    end
    
    
    
    % Now we have the transforms.  Let's now set up the coordinates for the
    % megapicture.
    
    for i = 1:numPositions
        [row,col] = find(matrixOfPositions == i);
        
        topCoords(i)  = row*columnTransformCoords(2) + col*rowTransformCoords(2);
        leftCoords(i) = col*rowTransformCoords(1) + row*columnTransformCoords(1);
    end
    
    
    
    topCoords = topCoords - min(topCoords) + 1;
    leftCoords = leftCoords - min(leftCoords) + 1;
    
    
    
    compositeIm = zeros(max(topCoords)+imagesize-1,max(leftCoords)+imagesize-1,'uint16');
    
    h = fspecial('gaussian',40,20);  % For removing slow-varying background
    
    im1 = ims(:,:,matrixOfPositions(registerPosition.row,registerPosition.col));
    doubleIm = im2double(im1);  % Register image
    im1 = (doubleIm - imfilter(doubleIm,h,'replicate'));
    im1 = (im1-min(im1(:)))*10;
    srt1 = sort(im1(:));
    im1Percentiles = srt1(round(length(srt1)*[0.25 0.50 0.75]));
    
    for i = numPositions:-1:1
        
        doubleIm = im2double(ims(:,:,i));
        imageToAdd = (doubleIm - imfilter(doubleIm,h,'replicate'));
        imageToAdd = (imageToAdd-min(imageToAdd(:)))*10;
        
        srt = sort(imageToAdd);
        imNewPercentiles = srt(round(length(srt)*[0.25 0.50 0.75]));
        imageToAdd = (imageToAdd - imNewPercentiles(2))/...
            (imNewPercentiles(3)-imNewPercentiles(1))*...
            (im1Percentiles(3)-im1Percentiles(1)) + im1Percentiles(2);
        
        compositeIm(topCoords(i):topCoords(i)+imagesize-1, ...
            leftCoords(i):leftCoords(i)+imagesize-1) = ...
            im2uint16(imageToAdd);
    end
    
    %compositeIm(compositeIm==0) = median(doubleIm(:));
    
    compositeIm = im2uint16(scale(compositeIm)*2);
    
    imwrite(im2uint8(compositeIm),['stitch' num2str(currentTime) '.jpg']);
    
end

