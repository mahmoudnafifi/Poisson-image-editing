%
% T3 Demo code
%
source='source6.jpg';
target='target6.jpg';
result='result6.jpg';

I1 = imread(source);            % SOURCE IMAGE
I2 = imread(target);        % DESTINATION IMAGE

PIE_Gui(I1,I2,result,1,0);
