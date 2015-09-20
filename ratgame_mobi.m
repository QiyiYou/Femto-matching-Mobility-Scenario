function [lost assignment femtouserno cascade chains candidate_num]=ratgame_mobi(dis,radius,quota,assign_topo,in_thre,out_thre,o_femtouserno,speed)
disind=(dis<=radius);
dis=dis.*disind+1./(disind)-1;

rate=getrate(dis,radius);

numuser=size(dis,2);
numfemto=size(dis,1);
assignment=assign_topo;
femtoquota=ones(numfemto,1)*quota; %ÿ��femtoʣ�������
% femtoquota=o_femtoquota; %ÿ��femtoʣ�������

assistant = 0;                                                    %%% ����debug ����ɾ��%%%
asscount=1;
% old_userfemto=zeros(1,numuser); %�ɵ�assignment

% femtouserno=zeros(numfemto,1); %��һ־ԸͶ��BS���û���   ����BS�����û�����
femtouserno = o_femtouserno; %����BS�����û�����
% femtouserno = quota - femtoquota; %����BS�����û����� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% �˴�������
% estimatrate=zeros(numfemto,numuser); %�û���ÿ��BS��rate�Ĺ��ƣ�����100*500

in_threshold = in_thre; %rate����in_threshold���ɽ���
out_threshold = out_thre; %rateС��out_thresholdʱ�߳�������Ϊ15��rate 3.8161
chains = 0;
kick_out = 0;
cascade = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  ���Ҵ������û�  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[max_rate f_id] = max(rate);
moved_point = []; %���ڴ洢�ƶ��˵��û����ı��(�Լ��������û����ı��)
for i=1:numuser
%    fprintf('speed(%g)=%g',i,speed(i))
   if speed(i) ~= 0
       if assignment( i ) == 0
           moved_point = [moved_point i];
           continue
       end
       if rate( assignment( i ) , i ) > out_threshold %�ų�����Ҫhandoff��(��δ�ﵽ�߳�Ҫ�����ֵ)
           continue
       else %��Ҫhandoff��
           femtouserno(assignment( i )) = femtouserno(assignment( i )) - 1 ;
           assignment( i ) = 0;
%            if max_rate(i) < in_threshold %�ų���Ҫ�л���ûAP��������
%                kick_out = kick_out + 1;
%            else
%                handoff = handoff + 1;
               moved_point = [moved_point i];
%            end
       end
   else
       if assign_topo(i) == 0 
           moved_point = [moved_point i];
       end
   end
end
old_moved_p = moved_point;
old_femtoquota = femtouserno;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for j=1:numfemto
    if femtouserno(j) ~= length(find(assignment==j))
%         fprintf('femtouserno(%g)=%g,length(find(assignment==%g))=%g.unequal\nwarning!!!!!!!!!!!!!!!!!!!!!!!\n',j,femtouserno(j),j,length(find(assignment==j)));
        femtouserno(j) = length(find(assignment==j));
    end
    
end

old_assignment = assignment;
%%%%%%%%%%%%%%%%%%%%% ������� �� �������ƥ��  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
iteration = 0;
while(asscount>0)
%     moved_point
    asscount=0;
    iteration = iteration +1;
    rate=getrate(dis,radius);
    %user choose the best femto
    new_in = [];
    push_out = [];
    for u=1:length(moved_point)
       userexpect=femtouserno+1; % ������femto�� * 1����������BS���û������������Ҽ���󣬸���BS�����û����������~�� 
       this_user = moved_point(u);
       if(assignment( this_user )~=0)
              userexpect(assignment( this_user ))=userexpect(assignment( this_user ))-1; %���user�Ѿ���BS�ˣ�����BS�ü�1����1������������BS�Ƿ��и���Ч��
        end

       if sum( dis(:,this_user)<=radius ) == 0 %�޻�վ��������pass
           continue
       end
       
%         estimatrate=rate(:,this_user)./userexpect .*vaccell; %��������У�������վ ��rate
        estimatrate=rate(:,this_user)./userexpect; %.*vaccell; %��������У�������վ ��rate
        [maxval wanted_BS]=max(estimatrate);%�ó�������Ҫ��BS
        
        if maxval==0 | dis(wanted_BS,this_user)>radius
%             fprintf('RAT:user %g cannot connect anyone\n',this_user);
%             dis(wanted_BS,this_user)
%             input('cannot')
            continue
        end
        if wanted_BS == assignment(this_user)
%             if assignment(this_user) ~= 0                                                                %%% ����debug ����ɾ��%%%
%                 fprintf('RAT:user %g regard its BS(BS %g) as the best again\n',this_user,wanted_BS);          %%% ����debug ����ɾ��%%%
%             end                                                                                             %%% ����debug ����ɾ��%%%
            continue
        else
            if assignment(this_user)~= 0 %������û��������ӣ���expected BS����ԭ���ӵ�BS
%                 fprintf('RAT:user %g wanna jump from BS %g to BS %g\n',this_user,assignment(this_user),wanted_BS);           %%% ����debug ����ɾ��%%%
                femtouserno(assignment( this_user )) = femtouserno(assignment( this_user )) - 1 ;
                assignment(this_user) = 0;
            end
        end
%         [maxval user_femto]=max(estimatrate,[],1);%�ó�������Ҫ��BS

        if femtouserno( wanted_BS )<quota  %if the wanted BS is avalible with no need to kick anyone out
            if assignment(this_user)~= 0 %���ڱ������л�վ����ѡ����Ż�վ���û�
%                 fprintf('RAT:user %g jump from BS %g to BS %g without kicking anyone out(%g)\n',this_user,assignment(this_user),wanted_BS,rate(wanted_BS,this_user));           %%% ����debug ����ɾ��%%%
                femtouserno(assignment( this_user )) = femtouserno(assignment( this_user )) - 1 ;
                assignment(this_user) = 0;
            end
            assignment( this_user ) = wanted_BS;
            femtouserno( wanted_BS ) = femtouserno( wanted_BS ) +1;
            push_out = [push_out u];
%             fprintf('RAT:user %g connect BS %g without kicking anyone out(%g)\n',this_user,wanted_BS,rate(wanted_BS,this_user));
        
        else %if the wanted_BS is full occupied
            users_connected_thisBS=find( assignment == wanted_BS );
            rate_of_those_connected_user = rate(wanted_BS,users_connected_thisBS);
            [fval frank]=sort( rate_of_those_connected_user );

            if fval(quota) < rate(wanted_BS,this_user)
                uid_kicked = users_connected_thisBS( frank(quota) ); %the ID of the kicked user
%                 fprintf('RAT:user %g is kicked out (%g)\n',uid_kicked,rate(assignment(uid_kicked),uid_kicked));
                if assignment(this_user)~= 0 %���ڱ������л�վ����ѡ����Ż�վ���û�
%                     fprintf('user %g jump from BS %g to BS %g \n',this_user,assignment(this_user),wanted_BS);           %%% ����debug ����ɾ��%%%
                    femtouserno(assignment( this_user )) = femtouserno(assignment( this_user )) - 1 ;
                    assignment(this_user) = 0;
                end
                assignment( uid_kicked ) = 0;
                new_in = [new_in uid_kicked];
                assignment( this_user ) = wanted_BS;
%                 fprintf('RAT:assignment(%g)=%g (%g)\n',this_user,assignment( this_user ),rate(wanted_BS,this_user));
                push_out = [push_out u]; %prepare to push this user out of the 'moved_point' set
            else %�������һ־Ը����һ��ת�ڶ�־Ը
                dis(wanted_BS,this_user)=inf;
                asscount = asscount + 1;
%                 fprintf('RAT:user %g change its target next iteration\n',this_user)
                continue;
            end
        end
    end
    
%     moved_point(push_out) = [];
    moved_point = [moved_point new_in];
%         femtouserno(f)=femtoquota(f); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    asscount = asscount + sum(abs(assignment-old_assignment));
    old_assignment=assignment;
%     assignment'
end
moved_point = setdiff(moved_point,find(assignment~=0));

%% used for checking bugs below
% for i=1:numuser
%     if assignment(i)==0
%         continue;
%     end
%     if(rate(assignment(i),i)==0)
%         fprintf('Exception:\nWarn that user %g connected BS %g with rate=0\n',i,assignment(i));
%         pause(60);
%         assignment(i)=0;
%     end
% end
%% used for cheking bugs above


lost=sum(assignment==0);

candidate = setdiff( old_moved_p,moved_point );
candidate_num = length(candidate);
% candidate
chains = 0;
for ii=1:length(candidate)
    BS_tmp = assignment(candidate(ii));
    if old_femtoquota(BS_tmp) >= quota
%         fprintf('%g starts a chain\n',candidate(ii))
        chains = chains +1;
    else                                                                                              %%% ����debug %%%
%         old_femtoquota( assignment(candidate(ii)) )                                                    %%% ����debug %%%
%         fprintf('old_femtoquota(%g) = %g\n',BS_tmp,old_femtoquota(ii))                                 %%% ����debug %%%
        old_femtoquota(BS_tmp) = old_femtoquota(BS_tmp) +1;
    end
end

cascade = length(setdiff(find((assignment~=assign_topo)==1),old_moved_p ));

% fprintf('RAT game:iteration=%g,\tcascade=%g,\tlost:%g,\tchains:%g\n\n\n',iteration,cascade,lost,chains);


end
