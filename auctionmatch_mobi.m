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
%assignment=zeros(numuser,1);%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%1028-23:03����
assignment = assign_topo;
price=o_price; % numfemto * f2uratio
reserve = o_reserve; %��VBS���������,numfemto * f2uratio
% for i=2:f2uratio
%     price(:,i)=-w*log2((i-1)^(i-1)/i^i);
% end
% curprice=zeros(numfemto,1); %�˻�վ�ĵ�ǰ���ۣ�����
% priceid=ones(numfemto,1);   %�˻�վ�����������ǵڼ���VBS
% [curprice priceid] = min( price , [] , 2 );
% curprice = curprice .* w;   %%%%%%%%%%%%%


%�Ѽ���Ҫ�л����û�
[max_rate f_id] = max(rate);
moved_point = []; %���ڴ洢�ƶ��˵��û����ı��(�Լ��������û����ı��)
for i=1:numuser
%    fprintf('speed(%g)=%g',i,speed(i))
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
%            if max_rate(i) < in_threshold %�ų���Ҫ�л���ûAP��������
%                kick_out = kick_out + 1;
%            else
%                handoff = handoff + 1;
%                cascade = cascade -1; %������Ҫhandoff���û�����һ�α任BS����cascade
               moved_point = [moved_point i];
%            end
       end
   else
       if assign_topo(i) == 0
           moved_point = [moved_point i];
       end
   end
end
% old_assign1 = assign_topo;
% old_assign2 = old_assign1;
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
  
% %         if(assignment(i)~=0)
% %             continue;
% %         end
        margin=lograte(:,moved_point(i))-curprice;
        if assign_topo(moved_point(i)) ~= 0  %��֮ǰ�����ӣ�����ԭ���ӻ�վ���ܴ���
%             margin( assign_topo(moved_point(i)) )
            margin( assign_topo(moved_point(i)) )=lograte( assign_topo(moved_point(i)) ,moved_point(i)) - discount*curprice( assign_topo(moved_point(i)) );
%             margin( assign_topo(moved_point(i)) )
%             pause(1)
        end
        [ maxmargin requestbs(i)]=max(margin);
        if(maxmargin<=0)
            requestbs(i)=0;
            continue;
        end
        margin(requestbs(i))=-inf;
    

        [secondmargin id ]=max(margin);
%         bid(i)=maxmargin-secondmargin;
        bid(i)=maxmargin-secondmargin ; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% �˴���bid�е���
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

    win_list = [];
    for i=1:numfemto
        requestid=find(requestbs==i);
        if(isempty(requestid));
            continue;
        end
        [maxbid uid]=max(bid(requestid));
        winuser=moved_point(requestid(uid)); %winuserָ��user��ʵ��ID
        
%         %�˶δ�������debug���鿴reserve��price�ж�Ӧ��˻�վ�ķ������  %%%%%  %%%%%   %%%%%
%         tmp_res = reserve(i,:)
%         tmp_pri = price(i,:)
%         %����
        
%         if rate( i , winuser ) < (in_threshold+0.2)
%             continue;
%         end

        if(maxbid==0)
            %fprintf('bid=0, femto=%d, user=%d, previous=%d\n',i,winuser,reserve(i,priceid(i)));
            maxbid=1;
            %priceid(i)
        end
        
        assignment(winuser)=i;
%%%%%%%%%%%% print user behavior below %%%%%%%%%%%%%%
%         fprintf('Femtomatching:assignment(%g) = %g \n', winuser , i )
%         if assignment(winuser) ~= old_assign2( winuser ) & old_assign2( winuser )~= 0 & 0 ==length(find(old_moved_p == winuser))
%             fprintf('Femtomatching:user%g jump from BS %g to BS %g\n',winuser,old_assign2( winuser ),assignment(winuser))
%         end
%%%%%%%%%%%% print user behavior above %%%%%%%%%%%%%%
        win_list = [win_list winuser];
        if(reserve(i,priceid(i))~=0) %assigned
            assignment(reserve(i,priceid(i)))=0;
%%%%%%%%%%%% print user behavior below %%%%%%%%%%%%%%
%             fprintf('Femtomatching:%g was kicked out from BS %g ,VBS %g \n',reserve(i,priceid(i)),i,priceid(i));
%%%%%%%%%%%% print user behavior above %%%%%%%%%%%%%%
            moved_point = [moved_point reserve(i,priceid(i))];
        end
        
%%        % used for checking bugs below %�������ڴ�����
%         if length( find(reserve == winuser)) ~= 0  %���ڴ����⣬ȷ��׼ȷ���ɾ��
%             
%             find( reserve == winuser )             %���ڴ����⣬ȷ��׼ȷ���ɾ��
%             winuser                                %���ڴ����⣬ȷ��׼ȷ���ɾ��
%             old_assign2(winuser)                   %���ڴ����⣬ȷ��׼ȷ���ɾ��
%             old_assign1(winuser)                   %���ڴ����⣬ȷ��׼ȷ���ɾ��
%             fprint('reserveδ����\n')               %���ڴ����⣬ȷ��׼ȷ���ɾ��
%             a = input('press Enter to continue\n');%���ڴ����⣬ȷ��׼ȷ���ɾ��
%             
%             reserve( find(reserve == winuser) ) = 0;%���ڴ����⣬ȷ��׼ȷ���ɾ��
%         end                                        %���ڴ����⣬ȷ��׼ȷ���ɾ��
%%         % used for checking bugs above %�������ڴ�����
        
        reserve(i,priceid(i))= winuser ;
       if maxbid < 0.3
           maxbid = 0.5;
       end
       price(i,priceid(i))=price(i,priceid(i))+maxbid;
%        fprintf('price(BS:%g,VBS:%g)=%g\n', i , priceid(i) , price(i,priceid(i)) )  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% print
       [curprice(i) , priceid(i)]=min(price(i,:));%give the smallest price

        change=1;
    end
%%    %delete the assigned used from 'moved_point' %���ѷ�����û���moved_pointɾ��
    for i=1:length(win_list)
        moved_point( find( moved_point == win_list(i) ) ) = [];
    end
    
%     old_assign2 = old_assign1;
%     old_assign1 = assignment;
end

lost=length(find(assignment==0));

candidate = setdiff( old_moved_p,moved_point );
candidate_num = length(candidate);
% candidate

%������chain�İ汾2
%new femto_quota
association_stat = (old_reserve ~= 0); %����ʼʱ��VBS������״̬
femto_quota = sum(association_stat , 2); %��candidate�������ӵĻ�վ����ʼ״̬ʱ���ӵ��û�����
chains = 0; %��¼�������û�������ԭ�������ӣ����ƶ���radius��������ͨ�����߱��˶��������
for ii=1:length(candidate)
    BS_tmp = assignment(candidate(ii));
    if femto_quota(BS_tmp) >= f2uratio
%         fprintf('%g starts a chain\n',candidate(ii))
        chains = chains +1;
    else                                                                                              %%% ����debug %%%
%         old_reserve( assignment(candidate(ii)),: )                                                    %%% ����debug %%%
%         fprintf('femto_quota(%g) = %g\n',BS_tmp,femto_quota(ii))                                 %%% ����debug %%%
        femto_quota(BS_tmp) = femto_quota(BS_tmp) +1;
    end
end

cascade = length(setdiff(find((assignment~=assign_topo)==1),old_moved_p ));
% % cascade1 = cascade_jumpBS + chains;                  %���ڴ����⣬ȷ��׼ȷ���ɾ��
% % if (cascade1~=cascade) & (cascade_kicked~=0)                  %���ڴ����⣬ȷ��׼ȷ���ɾ��
% %     fprintf('match:kicked user:\n')                  %���ڴ����⣬ȷ��׼ȷ���ɾ��
% %     setdiff(moved_point,old_moved_p)                  %���ڴ����⣬ȷ��׼ȷ���ɾ��
% %     fprintf('cascade(+chain) = %g,\tcascade(+kick) = %g,chains = %g\n',cascade1,cascade,chains);                  %���ڴ����⣬ȷ��׼ȷ���ɾ��
% %     input('match:cascade unequal!!')                  %���ڴ����⣬ȷ��׼ȷ���ɾ��
% % end                  %���ڴ����⣬ȷ��׼ȷ���ɾ��
% fprintf('cascade:%g,\tnew chains:%g\n',cascade,chains);
% fprintf('auction:iteration:%g,\thandoff:%g,\tkick out:%g,\tass_change:%g\tcascade:%g,\tlost:%g\n\n\n', iteration , handoff , kick_out ,sum(assignment ~= assign_topo), cascade , lost );
% % pause(1.5);                                                                                   %%% ����debug %%%
% % if (cascade<chains) | (cascade ~=0 & chains == 0)                                                    %%% ����debug %%%
% %     pause(1)
% % %     input('got!!!!!')                                                                                     %%% ����debug %%%
% % end                                                                                              %%% ����debug %%%
if (cascade ~=0 & chains == 0)                                                                                   %%% ����debug %%%
    chains = 1;                                                                                     %%% ����debug %%%
end                                                                                              %%% ����debug %%%

end