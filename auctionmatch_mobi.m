function [lost cost assignment price reserve cascade chains candidate_num]=auctionmatch_mobi(dis,radius,f2uratio,speed,assign_topo,o_price,o_reserve,w,in_thre,out_thre )
%assig��һ������������ʾÿ���û����ӵĻ�վ��lost��δ�������ӵ��û�������assign_topo���������ˣ���ǰһ�ֵõ���assignment,reserve�Ǹ���VBS���������

%proportional match
in_threshold = in_thre; %rate����in_threshold���ɽ���
out_threshold = out_thre; %rateС��out_thresholdʱ�߳�������Ϊ15��rate 3.8161
maxiter=1e4;
numuser=size(dis,2); %size(A,n)�����size��������������������һ��n������1��2Ϊn��ֵ���� size�����ؾ��������������������r=size(A,1)����䷵�ص�ʱ����A�������� c=size(A,2) ����䷵�ص�ʱ����A��������
numfemto=size(dis,1); 
epsilon=1e-5;
disind=(dis<=radius); %disind�Ǹ���С��disһ���ľ���disС�ڵ���radius��λ�ã�disind�Ķ�Ӧλ��Ϊ1
handoff = 0;
kick_out = 0;
cascade = 0;
discount = 1;

dis=dis.*disind + 1./(disind) - 1; %"."��ʾԪ��Ⱥ���㡣�μ�<�����﷨>P4
rate=getrate(dis,radius)+epsilon; % ÿ���û��� r 100*500
lograte=log2(rate)-log2(epsilon);%-w*log2((f2uratio-1)^(f2uratio-1)/f2uratio^f2uratio);

cost=0;
lost=0;
change=1;
iteration=0;
assignment = assign_topo;
price=o_price; % numfemto * f2uratio
reserve = o_reserve; %��VBS���������,numfemto * f2uratio

%�Ѽ���Ҫ�л����û�
[max_rate f_id] = max(rate);
moved_point = []; %���ڴ洢�ƶ��˵��û����ı��(�Լ��������û����ı��)
for i=1:numuser
   if speed(i) ~= 0
       if assignment( i ) == 0
           moved_point = [moved_point i];
           continue
       end
       if rate( assignment( i ) , i ) > out_threshold %�ų�����Ҫ�л���(��δ�ﵽ�߳�Ҫ�����ֵ)
           continue
       else %��Ҫ������ƶ��û����߳� �� handoff
           [ tmp_row , tmp_col ] = find( reserve == i );
           reserve( tmp_row , tmp_col ) = 0;
           assignment( i ) = 0;
           moved_point = [moved_point i];
       end
   else
       if assign_topo(i) == 0
           moved_point = [moved_point i];
       end
   end
end
old_moved_p = moved_point;
old_reserve = reserve;

%�����������뿪��VBS�۸�����
price( find(reserve==0) ) = 0; %���������ӵ�VBS���۸�����
for fem = 1: numfemto
    if length(find( price(fem,:) == 0 )) ~= 0
        vbs_id = find( price(fem,:) == 0 );
        for j = 1:length(vbs_id)
            i = f2uratio-length(vbs_id)+j;
            price(fem,vbs_id(j))=-w*log2(( i-1)^(i-1)/i^i);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% fprintf('Femtomatching:��������ƶ��û���\n')
% moved_point( find( speed(moved_point) ~= 0 ) )
% fprintf('\nFemtomatching:��������������û�:\n')
% moved_point( find( assign_topo(moved_point) == 0 ))
% for i=1:length(moved_point)
%    if assign_topo(moved_point(i)) == 0
%            fprintf('  %g  ',moved_point(i)) 
%    end
% end
% fprintf('\nFemtomatching:�����������̣�\n')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

while(change==1)
    if length(moved_point) == 0
        break;
    end
    [curprice priceid] = min( price , [] , 2 );

    
    change=0;
    iteration=iteration+1;
    
    cost(iteration)=sum(assignment~=0);     %���������ţ���ʾȡ��ֵ�±��Ӧ��Ԫ��???????????????????????????
    %sum(curprice)
    if iteration>maxiter
        break;
    end
    

    %user submit requests
    requestbs=zeros(length(moved_point),1);
    bid=zeros(length(moved_point),1);
    for i=1:length(moved_point)
        margin=lograte(:,moved_point(i))-curprice;
        if assign_topo(moved_point(i)) ~= 0  %��֮ǰ�����ӣ�����ԭ���ӻ�վ���ܴ���
            margin( assign_topo(moved_point(i)) )=lograte( assign_topo(moved_point(i)) ,moved_point(i)) - discount*curprice( assign_topo(moved_point(i)) );
        end
        [ maxmargin requestbs(i)]=max(margin);
        if(maxmargin<=0)
            requestbs(i)=0;
            continue;
        end
        margin(requestbs(i))=-inf;
    

        [secondmargin id ]=max(margin);
        bid(i)=maxmargin-secondmargin ; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% �˴���bid�е���
        if(bid(i)<=1e-2)
              bid(i)=0.5;%rand(1,1);
        end
        if(bid(i)<0)
            bid(i)=0;
            requestbs(i)=0;
        end
    end

    win_list = [];
    for i=1:numfemto
        requestid=find(requestbs==i);
        if(isempty(requestid));
            continue;
        end
        [maxbid uid]=max(bid(requestid));
        winuser=moved_point(requestid(uid)); %winuserָ��user��ʵ��ID

        if(maxbid==0)
            maxbid=1;
        end
        
        assignment(winuser)=i;
        win_list = [win_list winuser];
        if(reserve(i,priceid(i))~=0) %assigned
            assignment(reserve(i,priceid(i)))=0;
            moved_point = [moved_point reserve(i,priceid(i))];
        end
        
        reserve(i,priceid(i))= winuser ;
       if maxbid < 0.3
           maxbid = 0.5;
       end
       price(i,priceid(i))=price(i,priceid(i))+maxbid;
       [curprice(i) , priceid(i)]=min(price(i,:));%give the smallest price

        change=1;
    end
    for i=1:length(win_list)
        moved_point( find( moved_point == win_list(i) ) ) = [];
    end
end

lost=length(find(assignment==0));

candidate = setdiff( old_moved_p,moved_point );
candidate_num = length(candidate);

%new femto_quota
association_stat = (old_reserve ~= 0); %����ʼʱ��VBS������״̬
femto_quota = sum(association_stat , 2); %��candidate�������ӵĻ�վ����ʼ״̬ʱ���ӵ��û�����
chains = 0; %��¼�������û�������ԭ�������ӣ����ƶ���radius��������ͨ�����߱��˶��������
for ii=1:length(candidate)
    BS_tmp = assignment(candidate(ii));
    if femto_quota(BS_tmp) >= f2uratio
        chains = chains +1;
    else                                                                                              %%% ����debug %%%
        femto_quota(BS_tmp) = femto_quota(BS_tmp) +1;
    end
end

cascade = length(setdiff(find((assignment~=assign_topo)==1),old_moved_p ));

if (cascade ~=0 & chains == 0)                                                                                   %%% ����debug %%%
    chains = 1;                                                                                     %%% ����debug %%%
end                                                                                              %%% ����debug %%%

end
