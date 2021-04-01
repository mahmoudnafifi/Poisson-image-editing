function im_out = PIE( im_target,im_source,im_mask,m,c )
%PIE function: blends the source image with the target one based on the
%boundary given as a BW mask using Poisson Image Editing (PIE)
%  -Usage-
%	im_out = PIE(targetImage,sourceImage,mask,0,0); %for seamless cloning
%	(true color)
%   im_out = PIE(targetImage,sourceImage,mask,1,0); %for mixing gradients
%   (true color)
%	im_out = PIE(targetImage,sourceImage,mask,0,1); %for seamless cloning
%	(grayscale)
%   im_out = PIE(targetImage,sourceImage,mask,1,1); %for mixing gradients
%   (grayscale)
%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Citation:
%   Pérez, Patrick, Michel Gangnet, and Andrew Blake.
%   "Poisson image editing." ACM Transactions on Graphics (TOG). Vol. 22.
%   No. 3. ACM, 2003.
%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  -Inputs-
%	 im_target: target image
%    im_source: source image
%    im_mask: mask image
%    m: 0 for seamless cloning (default), and 1 for mixing gradients.
%    c: 0 for true color source and target images (default), and 1 for
%    grayscale source and target images.
%  -Outputs-
%    im_out: output image after blending the source image with the source
%    image based on the given mask (uint8).

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Initialization

if nargin<3
    error('Please, use  PIE(targetImage,sourceImage,mask)');
elseif nargin<4
    m=0; %use the default method (seamless cloning)
    c=0; %use the default image type (true color)
elseif nargin<5
    c=0; %use the default image type (true color)
end

if size(im_target,1)~= size(im_source,1) || ...
        size(im_target,1)~= size(im_mask,1) || ...
        size(im_target,2)~= size(im_source,2) || ...
        size(im_target,2)~= size(im_mask,2) || ...
        size(im_target,3)~=size(im_source,3)
    error('Please, use images with the same size');
end

%if the mask is not grayscale, convert it
if size(im_mask,3)>1
    im_mask=rgb2gray(im_mask);
end

%convert source and target images to double for more precise computations
im_target=double(im_target);
im_source=double(im_source);

%if we are working with true color, let m=3 otherwise, m=1
if c==0 %true color images
    c=3; %for the next for loop
else
    c=1;
    if size(im_source,3)>1
        im_source=rgb2gray(im_source);
    end
    if size(im_target,3)>1
        im_target=rgb2gray(im_target);
    end
    
end

%initially, output image = target image
im_out=im_target;


%create the laplacian mask for the second derivative of the source image
laplacian_mask=[0 1 0; 1 -4 1; 0 1 0];

%normalize the mask image to assure that unknown pixels = 1
im_mask=mat2gray(im_mask);

%convert it to logical to ignore any fractions (soft masks)
im_mask=im_mask==1;

%find the number of unknown pixels based on the mask
n=size(find(im_mask==1),1);

%create look up table
map=zeros(size(im_mask));

%loop through the mask image to initialize the look up table for mapping
counter=0;
for x=1:size(map,1)
    for y=1:size(map,2)
        if im_mask(x,y)==1 %is it unknow pixel?
            counter=counter+1;
            map(x,y)=counter;  %map from (x,y) to the corresponding pixel
            %in the 1D vector
        end
    end
end


for i=1:c %for each color channel
    
    % loop through the mask image again to:
    %1- initialize the coefficient matrix
    %2- initialize the B vector
    
    %if the method is seamless cloning; so, intially put B= (-) laplacian of
    %im_source,
    %otherwise (mixing gradients), B= (-) max(laplacian of im_source, laplacian
    %of im_target)
    
    %create the coefficient matrix A
    
    %At most, there are 5 coefficients per row according to eq (3)
    %in the report
    coeff_num=5;
    
    %create the sparse matrix to save memory
    A=spalloc(n,n,n*coeff_num);
    
    %create the right hand side of the linear system of equations (AX=B)
    B=zeros(n,1);
    
    if m==1  % mixing gradients
        
        %create the gradient mask for the first derivative
        grad_mask_x=[-1 1];
        grad_mask_y=[-1;1]; 
        
        %get the first derivative of the target image
        g_x_target=conv2(im_target(:,:,i),grad_mask_x, 'same');
        g_y_target=conv2(im_target(:,:,i),grad_mask_y, 'same');
        g_mag_target=sqrt(g_x_target.^2+g_y_target.^2);
        
        %get the first derivative of the source image
        g_x_source=conv2(im_source(:,:,i),grad_mask_x, 'same');
        g_y_source=conv2(im_source(:,:,i),grad_mask_y, 'same');
        g_mag_source=sqrt(g_x_source.^2+g_y_source.^2);
        
        %work with 1-D
        g_mag_target=g_mag_target(:);
        g_mag_source=g_mag_source(:);
        
        %initialize the final gradient with the source gradient
        g_x_final=g_x_source(:);
        g_y_final=g_y_source(:);
        
        %if the gradient of the target image is larger than the gradient of
        %the source image, use the target's gradient instead
        g_x_final(abs(g_mag_target)>abs(g_mag_source))=...
            g_x_target(g_mag_target>g_mag_source);
        g_y_final(abs(g_mag_target)>abs(g_mag_source))=...
            g_y_target(g_mag_target>g_mag_source);
        
        %map to 2-D
        g_x_final=reshape(g_x_final,size(im_source,1),size(im_source,2));
        g_y_final=reshape(g_y_final,size(im_source,1),size(im_source,2));
        
        %get the final laplacian of the combination between the source and
        %target images lap=second deriv of x + second deriv of y
        lap=conv2(g_x_final,grad_mask_x, 'same');
        lap=lap+conv2(g_y_final,grad_mask_y, 'same');
        
    else
        %create the laplacian of the source image
        lap=conv2(im_source(:,:,i),laplacian_mask, 'same');
    end
    counter=0;
    for x=1:size(map,1)
        for y=1:size(map,2)
            if im_mask(x,y)==1
                counter=counter+1;
                A(counter,counter)=4; %the diagonal represent the current pixel
                
                %check the boundary
                if im_mask(x-1,y)==0 %known left pixel
                    B(counter)=im_target(x-1,y,i); %add it to B
                else %unknown boundary
                    A(counter,map(x-1,y))=-1; %set its coefficient to -1
                end
                if im_mask(x+1,y)==0 %known right pixel
                    B(counter)=B(counter)+im_target(x+1,y,i); %add it to B
                else %unknown boundary
                    A(counter,map(x+1,y))=-1; %set its coefficient to -1
                end
                if im_mask(x,y-1)==0 %known bottom pixel
                    B(counter)=B(counter)+im_target(x,y-1,i); %add it to B
                else %unknown boundary
                    A(counter,map(x,y-1))=-1; %set its coefficient to -1
                end
                if im_mask(x,y+1)==0 %known top pixel
                    B(counter)=B(counter)+im_target(x,y+1,i); %add it to B
                else %unknown boundary
                    A(counter,map(x,y+1))=-1; %set its coefficient to -1
                end
                
                %update the B vector with the laplacian value
                
                B(counter)=B(counter)-lap(x,y);
                
            end
        end
    end
    
    %solve the linear system of equation
    X=A\B;
    
    
    %reshape X to restore the output image
    
    %     counter=0;
    %     for x=1:size(map,1)
    %         for y=1:size(map,2)
    %             if im_mask(x,y)==1
    %                 counter=counter+1;
    %                 im_out(x,y,i)=X(counter);
    %             end
    %         end
    %     end
    
    
    for counter=1:length(X)
        [index_x,index_y]=find(map==counter);
        im_out(index_x,index_y,i)=X(counter);
        
    end
    
    
    %release all
    clear A B X lap_source lap_target g_mag_source g_mag_target
end

im_out=uint8(im_out);

end

