function [X Y direct]=random_direction(userx,usery,direction,speed,fieldsize,radius)
%�ĸ������Ϊ������n * 1��������n Ϊ�û�����
%�������룺userx��usery����Ϊ��ǰuser��λ�á�
%directionΪ�Ƕ�����������user�ƶ��ĽǶȣ�ȡֵ��Ϊ[0,360)
%speedΪ�ٶȣ��ٶ�Ϊ0��Ϊ��ֹ
% fprintf('userx,length %g \n',length(userx))
% fprintf('userx,length %g \n',length(speed))
X=userx+speed.*cosd(direction);
Y=usery+speed.*sind(direction);
direct=direction;

for i=1:1:length(X)
%   if X(i)>=(fieldsize/2-radius) 
   if X(i)>=fieldsize/2 
       X(i) = fieldsize/2;
       if direct(i)>180
           direct(i) = 540 - direct(i);
       else direct(i)<=180
           direct(i) = 180 - direct(i);
       end
%   elseif X(i)<= -(fieldsize/2-radius)
   elseif X(i)<= -fieldsize/2
       X(i) = -fieldsize/2;
       if direct(i)>180
           direct(i) = 540 - direct(i);
       else direct(i)<=180
           direct(i) = 180 - direct(i);
       end
   end
   
   if Y(i)>=fieldsize/2
       Y(i) = fieldsize/2;
       direct(i) = 360 - direct(i);
   elseif Y(i)<= -fieldsize/2
       Y(i) = -fieldsize/2;
       direct(i) = 360 - direct(i);
   end
end



end