function speed=get_speed(lambda, maxx,maxy)
%generates a random speed vector

n = round(lambda*maxx*maxy); %number of nodes

speed = rand(n,1)*2;

for i=1:1:length(speed)
    if speed(i)>=0.9 | speed(i)<=0.3
        speed(i) = 0;
    end
end
% fprintf('�ƶ��û�������%g \n', 1-length(find(speed==0))/n );
pause(1);
end