function [lost assignment femtoquota cascade chains candidate_num]=college_mobi(dis,radius,quota,assign_topo,in_thre,out_thre,o_femtoquota,speed) %dis,( femto * user )
disind=(dis<=radius);
dis=dis.*disind+1000.*(1-disind);
numuser=size(dis,2);
numfemto=size(dis,1); %size�Ĳ�����1��������2������

assignment=assign_topo;
old_assignment = assignment; %��¼���ڼ�¼ǰһiteration�����ˡ��������˲��䣬��college����
femtoquota=o_femtoquota; %��¼��վʣ��ɹ�����

epsilon=1e-5;
in_threshold = in_thre; %rate����in_threshold���ɽ���
out_threshold = out_thre; %rateС��out_thresholdʱ�߳�������Ϊ15��rate 3.8161
chains = 0;
cascade = 0;

rate=getrate(dis,radius)+epsilon; % ÿ���û��� r 100*500

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
           femtoquota(assignment( i )) = femtoquota(assignment( i )) + 1 ;
           assignment( i ) = 0;
           if max_rate(i) > in_threshold
%            if max_rate(i) < in_threshold %�ų���Ҫ�л���ûAP��������
%                kick_out = kick_out + 1;
%            else
%                handoff = handoff + 1;
               moved_point = [moved_point i];
           end
       end
   else %if speed=0 but assigned no BS
       if assign_topo(i) == 0 
           moved_point = [moved_point i];
       end
   end
end
old_moved_p = moved_point;
old_femtoquota = quota - femtoquota; %��ʼ״̬�£�����BS�����û��ĸ��������ڼ�������chains

asscount=1;
iteration = 0;
while(asscount>0)
%     moved_point
    asscount=0;
    iteration = iteration +1;
    %user choose the best femto
    [minval user_femto]=min(dis,[],1); %minval ��С���룻user_femto ÿ��user�����Ļ�վID
    fmask=(minval<radius);
    user_femto=user_femto.*fmask; %��õ�һ־Ը
    
    new_in = [];
    push_out = [];
    for i = 1:length(moved_point)
       wanted_BS = user_femto( moved_point(i) );  %�� �������û� �ĵ�һ־Ը
       
%%%%%%%%%%%%%%%�ų��޻�վ���ǵ��û�
       if wanted_BS == 0
              continue
       end
%%%%%%%%%%%%%%%%%%%%%%%

       if femtoquota( wanted_BS ) ~= 0 %�п������λ
           assignment( moved_point(i) ) = wanted_BS;
           femtoquota(wanted_BS)=femtoquota(wanted_BS)-1;
           push_out = [push_out i];
%            fprintf('college:user %g assign to BS %g without kick anyone out\n',moved_point(i),wanted_BS);
       else     %�޿������λ
           fusers=find( assignment == wanted_BS );
%            fusers             %���ڴ����⣬ȷ��׼ȷ���ɾ��
%            wanted_BS             %���ڴ����⣬ȷ��׼ȷ���ɾ��
%            dis(wanted_BS,fusers)             %���ڴ����⣬ȷ��׼ȷ���ɾ��
%            moved_point(i)             %���ڴ����⣬ȷ��׼ȷ���ɾ��
%            dis(wanted_BS,moved_point(i))             %���ڴ����⣬ȷ��׼ȷ���ɾ��
%            a = input(' 1.press any key ');             %���ڴ����⣬ȷ��׼ȷ���ɾ��
           [fval , frank]=sort(minval(fusers));
%            fval             %���ڴ����⣬ȷ��׼ȷ���ɾ��
%            frank             %���ڴ����⣬ȷ��׼ȷ���ɾ��
%            a = input(' 2.press any key ');             %���ڴ����⣬ȷ��׼ȷ���ɾ��
%            fprintf('femtoquota(wanted_BS) ):%g\t,quota:%g\n',femtoquota(wanted_BS),quota )             %���ڴ����⣬ȷ��׼ȷ���ɾ��
           max_dis_user_id = fusers(frank( quota ) );
%            max_dis_user_id             %���ڴ����⣬ȷ��׼ȷ���ɾ��
%            a = input(' 3.press any key ');             %���ڴ����⣬ȷ��׼ȷ���ɾ��
           
           if dis( wanted_BS,max_dis_user_id ) < minval( moved_point(i) ) %��һ־Ը������
               dis(wanted_BS,moved_point(i))=inf;
               asscount = asscount + 1;
%                fprintf('college:user %g change its target next iteration\n',moved_point(i))
               continue
           else %��һ־Ը���㣬������ԭǰquota�ĵ�quota��
%                fprintf('college:%g was kicked out from BS %g (%g)\n',max_dis_user_id,assignment( max_dis_user_id ),dis(assignment( max_dis_user_id ),max_dis_user_id) ); %%%%%%%%%%%  should print %%
%                fprintf('college:user %g assign to BS %g (%g)\n',moved_point(i),wanted_BS,dis(wanted_BS,moved_point(i)));
%                assignment( moved_point(i) )             %���ڴ����⣬ȷ��׼ȷ���ɾ��
               assignment( moved_point(i) ) = assignment( max_dis_user_id );
%                assignment( moved_point(i) )             %���ڴ����⣬ȷ��׼ȷ���ɾ��
               assignment( max_dis_user_id ) = 0;
%                assignment( max_dis_user_id )             %���ڴ����⣬ȷ��׼ȷ���ɾ��
%                a = input(' 4.press any key ');             %���ڴ����⣬ȷ��׼ȷ���ɾ��
               push_out = [push_out i];
               new_in = [new_in max_dis_user_id];
%                push_out             %���ڴ����⣬ȷ��׼ȷ���ɾ��
%                new_in             %���ڴ����⣬ȷ��׼ȷ���ɾ��
%                a = input(' 5.press any key ');             %���ڴ����⣬ȷ��׼ȷ���ɾ��

%                if iteration ~= 1
%                    cascade_tmp_test = cascade_tmp_test +1; %�����㣬�������ڰ����ձ��߳����û�Ҳ���ȥ��
%                    fprintf('college:cascade_tmp_test ++   cascade_tmp_test=%g\n',cascade_tmp_test);
%                end

%                fprintf('college:assignment(%g) = %g \n', moved_point(i) , wanted_BS ); %%%%%%%%%%%  should print %%
               
           end
       end
    end
    moved_point(push_out) = [];
    moved_point = [moved_point new_in];
    
    asscount = asscount + sum(abs(assignment - old_assignment));
    old_assignment = assignment;

end


%lost=sum( min(dis,[],1)>radius );
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
    else
%         old_femtoquota( assignment(candidate(ii)) )                                                    %%% ����debug %%%
%         fprintf('old_femtoquota(%g) = %g\n',BS_tmp,old_femtoquota(ii))                                 %%% ����debug %%%
        old_femtoquota(BS_tmp) = old_femtoquota(BS_tmp) +1;
    end
end

cascade = length(setdiff(find((assignment~=assign_topo)==1),old_moved_p ));

% fprintf('college:iteration:%g,\tlost:%g,\tcascade:%g,\tchains:%g\n\n\n',iteration,lost,cascade,chains);

end