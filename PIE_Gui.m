%%
% Author: Michael S. Brown, York University
%
% Simple Matlab GUI for selection a Region of Interest from Image1, and
% pasting this into Image2.
%
% It calls a function called: PossionImageIntegration()
%       Currently this function is just a dummy function adds the ROI and
%       Dest together.  This should generate the PIE image.
%
% Main functions: PIE_Gui
%   - Call back functions: myButtonPressDown, myButtonPressUp,
%   myMouseMotion, myKeypress
%
function PIE_Gui(I1, I2,FileName,Method,Color)

%
% -------------------  SELECT SOURCE ROI ------------------
%
disp('USAGE: select a polygon region by using left mouse clicks to draw the vertices');
disp('       right nouse click to finish - you can then drag the selected region around.');
disp('       When you have it where you want it, double click left to cut it and paste to the next image.');

h = figure('MenuBar', 'none', 'Toolbar', 'none');  % open window
[BW, xi, yi] = roipoly(I1);                         % this returns a binary image with white (1) in the mask

% extract mask (crop image)
[r,c] = find(BW == 1);                      % find the max values
maxH = max(r) - min(r);                     % extract the height
maxW = max(c) - min(c);                     % extract the width
SRC = imcrop(I1,[min(c) min(r) maxW maxH]);  % crop the image in the RIO

% crop mask - make the mask RGB (3 layers)
Mc = zeros(size(SRC));                       % make a copy of Ic
Mc(:,:,1) = imcrop(BW,[min(c) min(r) maxW maxH]);
Mc(:,:,2) = imcrop(BW,[min(c) min(r) maxW maxH]);
Mc(:,:,3) = imcrop(BW,[min(c) min(r) maxW maxH]);

%
% NOW SELECT PLACE TO PASTE
%
imshow(I2);
title('Click and drag region to desired location. Press any key to integrate, press q to quit');
lh = line(xi, yi, 'Marker','.','LineStyle','-', 'Color', 'r', 'LineWidth',2);

% Set up units and callback functions
set(h, 'Units', 'pixels');
set(h,'WindowButtonDownFcn',@myButtonPressDown);
set(h,'WindowButtonUpFcn',@myButtonPressUp);
set(h, 'WindowButtonMotionFcn', @myMouseMotion);
set(h, 'KeyPressFcn', @myKeyPress);

myData.xi = xi-min(xi);
myData.yi = yi-min(yi);
myData.SRC = SRC;
myData.DEST = I2;
myData.Mc=Mc;
myData.pressDown = 0;
myData.line = lh;
myData.curX = -1;
myData.curY = -1;
myData.Method=Method;
myData.Color=Color;
myData.FileName=FileName;

set(h, 'UserData', myData);

return


%%
% When button is pressed, call this function
%
function myButtonPressDown(obj,event_obj)

myData = get(obj, 'UserData');      % get the user data (variable name does not have to be "myData"
myData.pressDown = 1;               % set mouse press = true
p = get(gca,'CurrentPoint');        % get current position of mouse on the image
curX = p(1,1);                      % extract the X position (it's a floating point value)
curY = p(1,2);                      % extract the Y positions
myData.curX = curX;
myData.curY = curY;
set(myData.line,'XData', myData.xi+curX, 'YData', myData.yi+curY);

% Save the myData variable back to the object
set(obj, 'UserData', myData);
return

%%
% When button is released, call this function
%
function myButtonPressUp(obj,event_obj)

myData = get(obj, 'UserData');  % get the user data
myData.pressDown = 0;           % set mouse press to be false
set(obj, 'UserData', myData);   % set the uer data (i.e. record mouse is not longer being pressed)

return

%%
% Called anytime the mouse is moved
%
function myMouseMotion(obj,event_obj)

myData = get(obj, 'UserData');  % get the user data

if (myData.pressDown == 1)              % we are only interested if the mouse is down
    p = get(gca,'CurrentPoint');        % get the current point from the image
    curX = p(1,1);                      % extract the point from the strange matlab datastructure return by previous line of code
    curY = p(1,2);
    set(myData.line,'XData', myData.xi+curX, 'YData', myData.yi+curY);
    myData.curX = curX;
    myData.curY = curY;
    set(obj, 'UserData', myData);
end
return


%%
% Call when key any pressed any key
%
function myKeyPress(obj, event_obj)

if (event_obj.Key == 'q')
    close(obj);
    return;
end

% Update the userdata in the object
myData = get(obj, 'UserData');
if (myData.pressDown == 0)          % if mouse is not pressed
    
    if (myData.curX == -1)
        disp('Select a location');
        return;
    end
    
    %
    % Get the source and destination image
    % Compute a new image (SImage) where the source is translated to
    % the correct position based on the last mouse position.
    %
    %
    DEST = myData.DEST;
    SRC = myData.SRC;
    tx = round(myData.curX);
    ty = round(myData.curY);
    
    [hh ww depth] = size(SRC);
    
    %use only the ROI
    TRG(:,:,1)=DEST( ty:(ty+hh-1), tx:(tx+ww-1), 1 );
    TRG(:,:,2)=DEST( ty:(ty+hh-1), tx:(tx+ww-1), 2 );
    TRG(:,:,3)=DEST( ty:(ty+hh-1), tx:(tx+ww-1), 3 );
    
    %         SImage( ty:(ty+hh-1), tx:(tx+ww-1), 1 ) =  SRC(:,:,1);
    %         SImage( ty:(ty+hh-1), tx:(tx+ww-1), 2 ) =  SRC(:,:,2);
    %         SImage( ty:(ty+hh-1), tx:(tx+ww-1), 3 ) =  SRC(:,:,3);
    
    
    Mc = rgb2gray(myData.Mc);
    Mc(1,:)=0;
    Mc(end,:)=0;
    Mc(:,1)=0;
    Mc(:,end)=0;
    se = strel('disk',5);
    Mc = imerode( Mc,se);
    % Call the PIE function.  It will returned the integrated image
    newI = PIE( TRG,SRC,Mc,myData.Method,myData.Color);
    %reconstruct
    if size(newI,3)==1
        DEST=rgb2gray(DEST);
        DEST( ty:(ty+hh-1), tx:(tx+ww-1)) =  newI(:,:);
    else
        DEST( ty:(ty+hh-1), tx:(tx+ww-1), 1 ) =  newI(:,:,1);
        DEST( ty:(ty+hh-1), tx:(tx+ww-1), 2 ) =  newI(:,:,2);
        DEST( ty:(ty+hh-1), tx:(tx+ww-1), 3 ) =  newI(:,:,3);
    end
    %PossionImageIntegration(SImage, DEST, tx, ty, ww, hh);
    imshow(DEST);
    imwrite(DEST,myData.FileName);
end

return

