function [VKron, Policy]=ValueFnIter_Case1_raw(VKron, N_d,N_a,N_z,pi_z, beta, ReturnMatrix,Howards,Tolerance) %Verbose,

% N_d=prod(n_d);
% N_a=prod(n_a);
% N_z=prod(n_z);

% if Verbose==1
%     disp('Starting Value Fn Iteration')
%     tempcounter=1;
%     tic;
% end

PolicyIndexes1=zeros(N_a,N_z);
PolicyIndexes2=zeros(N_a,N_z);
currdist=Inf;

while currdist>Tolerance
    
    VKronold=VKron;
    
    for z_c=1:N_z

        %Calc the condl expectation term (except beta), which depends on z but
        %not on control variables
%         EV_z=zeros(N_a,1); %aprime
        EV_z=VKronold.*kron(pi_z(z_c,:),ones(N_a,1));
        EV_z(isnan(EV_z))=0; %multilications of -Inf with 0 gives NaN, this replaces them with zeros (as the zeros come from the transition probabilites)
        EV_z=sum(EV_z,2);
        
%         for zprime_c=1:N_z
%             if pi_z(z_c,zprime_c)~=0 %                 EV_z=EV_z+VKronold(:,zprime_c)*pi_z(z_c,zprime_c);
%             end
%         end
        
        entireEV_z=kron(EV_z,ones(N_d,1));
        
        for a_c=1:N_a
            %Calc the RHS
            entireRHS=ReturnMatrix(:,a_c,z_c)+beta*entireEV_z; %d by aprime by 1
            
            %Calc the max and it's index
            [Vtemp,maxindex]=max(entireRHS);
            VKron(a_c,z_c)=Vtemp;
            PolInd_temp=ind2sub_homemade([N_d,N_a],maxindex); %[d;aprime]
            PolicyIndexes1(a_c,z_c)=PolInd_temp(1);
            PolicyIndexes2(a_c,z_c)=PolInd_temp(2);
        end
    end
    
    VKrondist=reshape(VKron-VKronold,[N_a*N_z,1]); VKrondist(isnan(VKrondist))=0;
    currdist=max(abs(VKrondist));
    
    if isfinite(currdist) %Use Howards Policy Fn Iteration Improvement
        Ftemp=zeros(N_a,N_z);
        for z_c=1:N_z
            for a_c=1:N_a
                Ftemp(a_c,z_c)=ReturnMatrix(PolicyIndexes1(a_c,z_c)+(PolicyIndexes2(a_c,z_c)-1)*N_d,a_c,z_c);%FmatrixKron(PolicyIndexes1(a_c,z_c),PolicyIndexes2(a_c,z_c),a_c,z_c);
            end
        end
        for Howards_counter=1:Howards
            VKrontemp=VKron;
            for z_c=1:N_z
                EVKrontemp_z=VKrontemp(PolicyIndexes2(:,z_c),:).*kron(pi_z(z_c,:),ones(N_a,1)); %kron(pi_z(z_c,:),ones(nquad,1))
                EVKrontemp_z(isnan(EVKrontemp_z))=0; %Multiplying zero (transition prob) by -Inf (value fn) gives NaN
                VKron(:,z_c)=Ftemp(:,z_c)+beta*sum(EVKrontemp_z,2);
            end
        end
    end
    
%     if Verbose==1
%         if rem(tempcounter,100)==0
%             disp(tempcounter)
%             disp(currdist)
%         end
%         tempcounter=tempcounter+1;
%     end
    
end

% if Verbose==1
%     time=toc;
%     fprintf('Value fn iteration took %8.4f seconds', time)
% end

% if PolIndOrVal==1
Policy=zeros(2,N_a,N_z);
Policy(1,:,:)=permute(PolicyIndexes1,[3,1,2]);
Policy(2,:,:)=permute(PolicyIndexes2,[3,1,2]);
% elseif PolIndOrVal==2
%     Policy=zeros(N_a,N_z,length(n_d)+length(n_a)); %NOTE: this is not actually in Kron form
%     for a_c=1:N_a
%         for z_c=1:N_z
%             temp_d=ind2grid_homemade(n_d,PolicyIndexes1(a_c,z_c),d_grid);
%             for ii=1:length(n_d)
%                 Policy(a_c,z_c,ii)=temp_d(ii);
%             end
%             temp_a=ind2grid_homemade(n_a,PolicyIndexes2(a_c,z_c),a_grid);
%             for ii=1:length(n_a)
%                 Policy(a_c,z_c,length(n_d)+ii)=temp_a(ii);
%             end
%         end
%     end
% end


end