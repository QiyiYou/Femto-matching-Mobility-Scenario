function [lost assignment femtouserno]=ratgame(dis,radius,quota)
disind=(dis<=radius);
dis=dis.*disind+1./(disind)-1;

rate=getrate(dis,radius);

numuser=size(dis,2);
numfemto=size(dis,1);
assignment=zeros(numuser,1);
femtoquota=ones(numfemto,1)*quota;


asscount=1;
old_userfemto=zeros(1,numuser); %�ɵ�assignment'
user_femto=zeros(1,numuser); %assignment'
femtouserno=zeros(numfemto,1); %��һ־ԸͶ��BS���û���
estimatrate=zeros(numfemto,numuser); %�û���ÿ��BS��rate�Ĺ��ƣ�����100*500
while(asscount>0)
    asscount=0;
    %user choose the best femto
    
    for u=1:numuser
       userexpect=femtouserno+1; % femto�� * 1�������Ҽ���󣬸���BS�����û����������~��
       if(user_femto(u)~=0)
              userexpect(user_femto(u))=userexpect(user_femto(u))-1; %���user�Ѿ���BS�ˣ�����BS�ü�1����1������������BS�Ƿ��и���Ч��
        end

        vaccell=(userexpect<=femtoquota); %�������û�������BS
        estimatrate(:,u)=rate(:,u)./userexpect.*vaccell; %��������У�������վ ��rate
        [maxval user_femto]=max(estimatrate,[],1); %�ó�������Ҫ��BS
        for f=1:numfemto
            femtouserno(f)=sum(user_femto==f);
            if femtouserno(f)>femtoquota(f)
               userid=find(user_femto==f); %���Ӵ�BS�������û�
               user_rates=rate(f,userid);
               [result uindex]=sort(user_rates,2,'descend');
               for i=femtoquota(f)+1:femtouserno(f)
                   user_femto(userid(uindex(i)))=0; %����ǰN��֮��ģ��߳�
               end
%                fprintf('femtouserno(%g)=%g,\tfemtoquota(%g)=%g,\tuser_femto(%g)=%g,\tuser %g,BS%g\n',f,femtouserno(f),f,femtoquota(f),u,user_femto(u),u,f);
%                pause(1)
               femtouserno(f)=femtoquota(f);
    %            uindex
    %                       userid=find(user_femto==f)
    %            user_rates=rate(f,userid)
            end        
        end
       
    end
        asscount=sum(abs(user_femto-old_userfemto));
        old_userfemto=user_femto;
%     assignment'
end

%     for f=1:numfemto
%         if femtouserno(f)>femtoquota
%            userid=find(user_femto==f);
%            user_rates=rate(f,userid);
%            [result uindex]=sort(user_rates,2,'descend');
%            for i=femtoquota+1:femtouserno(f)
%                user_femto(userid(uindex(i)))=0;
%            end
% %            uindex
% %                       userid=find(user_femto==f)
% %            user_rates=rate(f,userid)
%         end        
%     end
for i=1:numuser
    if user_femto(i)==0
        continue;
    end
    if(rate(user_femto(i),i)==0)
        user_femto(i)=0;
    end
end
assignment=user_femto';

%lost=sum( min(dis,[],1)>radius );
lost=sum(assignment==0);
end