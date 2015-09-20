function [lost cost assignment price reserve user_bid]=auctionmatch(dis,radius,f2uratio,w)%assig��һ������������ʾÿ���û����ӵĻ�վ��lost��δ�������ӵ��û�����
%proportional match
maxiter=1e4;
numuser=size(dis,2); %size(A,n)�����size��������������������һ��n������1��2Ϊn��ֵ���� size�����ؾ��������������������r=size(A,1)����䷵�ص�ʱ����A�������� c=size(A,2) ����䷵�ص�ʱ����A��������
numfemto=size(dis,1); 
epsilon=1e-5;
disind=(dis<=radius); %disind�Ǹ���С��disһ���ľ���disС�ڵ���radius��λ�ã�disind�Ķ�Ӧλ��Ϊ1
dis=dis.*disind+1./(disind)-1; %"."��ʾԪ��Ⱥ���㡣�μ�<�����﷨>P4
rate=getrate(dis,radius)+epsilon; %epsilon ��ʲô ��
% rate %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lograte=log2(rate)-log2(epsilon);%-w*log2((f2uratio-1)^(f2uratio-1)/f2uratio^f2uratio);

cost=0;
lost=0;
change=1;
iteration=0;
assignment=zeros(numuser,1);
price=zeros(numfemto,f2uratio);
reserve=zeros(numfemto,f2uratio);
user_bid = zeros(numuser,1);
for i=2:f2uratio
    price(:,i)=-w*log2((i-1)^(i-1)/i^i);
end
curprice=zeros(numfemto,1); %�˻�վ�ĵ�ǰ���ۣ�����
priceid=ones(numfemto,1);   %�˻�վ�����������ǵڼ���VBS
while(change==1)
    change=0;
    iteration=iteration+1;
    
    cost(iteration)=sum(assignment~=0);     %���������ţ���ʾȡ��ֵ�±��Ӧ��Ԫ��???????????????????????????
    %sum(curprice)
    if iteration>maxiter
        break;
    end
    %user submit requests
    requestbs=zeros(numuser,1);
    bid=zeros(numuser,1);
    for i=1:numuser
  
        if(assignment(i)~=0)
            continue;
        end
%         curprice
%         fprintf('round %g',iteration)
%         pause(3)
        margin=lograte(:,i)-curprice;
        [ maxmargin requestbs(i)]=max(margin);
        if(maxmargin<=0)
            requestbs(i)=0;
            continue;
        end
        margin(requestbs(i))=-inf;
    

        [secondmargin id ]=max(margin);
        bid(i)=maxmargin-secondmargin;
%         if(i==69)
%              bid(i)
%              requestbs(i)
%              
%              rate(requestbs(i),i)
%         end
        if(bid(i)<=1e-2)
              %fprintf(1,'bid=0 user %d, %d:%g ,%d: %g\n',i,requestbs(i),maxmargin,id,secondmargin);
              bid(i)=0.5;%rand(1,1);
              %requestbs(i)=0;
        end
        if(bid(i)<0)
            bid(i)=0;
            requestbs(i)=0;
        end
    end
    nonzero = find(assignment==0);
    if(~isempty(nonzero))
        for j=1:length(nonzero)
            user_bid(nonzero(j)) = bid(nonzero(j));
        end
    end
    

    %requestbs'
    %bid'
    %curprice
    %priceid
    %femto get bids
    for i=1:numfemto
        requestid=find(requestbs==i);
        if(isempty(requestid))
            continue;
        end
        [maxbid uid]=max(bid(requestid));
        winuser=requestid(uid);
        if(maxbid==0)
            %fprintf('bid=0, femto=%d, user=%d, previous=%d\n',i,winuser,reserve(i,priceid(i)));
            maxbid=1;
            %priceid(i)
        end
%         if(i==68)
%               winuser
%                 requestbs(69)
%         end
        assignment(winuser)=i;
        if(reserve(i,priceid(i))~=0) %assigned
            assignment(reserve(i,priceid(i)))=0;
        end
        reserve(i,priceid(i))=winuser;
        price(i,priceid(i))=price(i,priceid(i))+maxbid;
        [curprice(i) priceid(i)]=min(price(i,:));%give the smallest price
        %maxbid
        change=1;
    end
end
%cost=curprice;
lost=length(find(assignment==0));
% iteration
% pause(600) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end