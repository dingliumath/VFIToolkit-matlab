function [VKron, Policy]=ValueFnIter_Case1_LowMem_NoD_Par2_raw(VKron, n_a, n_z, a_grid, z_grid, pi_z, beta, ReturnFn, ReturnFnParamNames, ReturnFnParams, Howards,Tolerance) % Verbose, a_grid, z_grid, 
%Does pretty much exactly the same as ValueFnIter_Case1, only without any
%decision variable (n_d=0)

N_a=prod(n_a);
N_z=prod(n_z);

PolicyIndexes=zeros(N_a,N_z,'gpuArray');

Ftemp=zeros(N_a,N_z,'gpuArray');

bbb=reshape(shiftdim(pi_z,-1),[1,N_z*N_z]);
ccc=kron(ones(N_a,1,'gpuArray'),bbb);
aaa=reshape(ccc,[N_a*N_z,N_z]);

CreateCleanedReturnFn(ReturnFn, ReturnFnParamNames, ReturnFnParams);

%%
l_a=length(n_a);
l_z=length(n_z);
if l_a==1 && l_z==1
    aprimevals=a_grid;
    avals=shiftdim(a_grid,-1);
elseif l_a==1 && l_z==2
    aprimevals=a_grid;
    avals=shiftdim(a_grid,-1);
elseif l_a==2 && l_z==1
    a1primevals=a_grid(1:n_a(1));
    a2primevals=shiftdim(a_grid(n_a(1)+1:n_a(1)+n_a(2)),-1);
    a1vals=shiftdim(a_grid(1:n_a(1)),-2);
    a2vals=shiftdim(a_grid(n_a(1)+1:n_a(1)+n_a(2)),-4);
elseif l_a==2 && l_z==2
    a1primevals=a_grid(1:n_a(1));
    a2primevals=shiftdim(a_grid(n_a(1)+1:n_a(1)+n_a(2)),-1);
    a1vals=shiftdim(a_grid(1:n_a(1)),-2);
    a2vals=shiftdim(a_grid(n_a(1)+1:n_a(1)+n_a(2)),-3);
end

%%
z_gridvals=zeros(N_z,length(n_z),'gpuArray'); 
for i1=1:N_z
    sub=zeros(1,length(n_z));
    sub(1)=rem(i1-1,n_z(1))+1;
    for ii=2:length(n_z)-1
        sub(ii)=rem(ceil(i1/prod(n_z(1:ii-1)))-1,n_z(ii))+1;
    end
    sub(length(n_z))=ceil(i1/prod(n_z(1:length(n_z)-1)));
    
    if length(n_z)>1
        sub=sub+[0,cumsum(n_z(1:end-1))];
    end
    z_gridvals(i1,:)=z_grid(sub);
end
% Somewhere in my codes I have a better way of implementing this z_gridvals when using gpu.
% But this will do for now.


%%
currdist=Inf;
while currdist>Tolerance
    VKronold=VKron;
    
    for z_c=1:N_z
%         ReturnMatrix_z=ReturnMatrix(:,:,z_c);

        % TempReturnFn.m is created by CreateCleanedReturnFn() as part of ValueFnIter_Case1()
        if l_a==1 && l_z==1
            zvals=z_gridvals(z_c);
            ReturnMatrix_z=arrayfun(@TempReturnFn, aprimevals, avals, zvals);
        elseif l_a==1 && l_z==2
            z1vals=z_gridvals(z_c,1);
            z2vals=z_gridvals(z_c,1);
            ReturnMatrix_z=arrayfun(@TempReturnFn, aprimevals, avals, z1vals,z2vals);
        elseif l_a==2 && l_z==1
            zvals=z_gridvals(z_c);
            ReturnMatrix_z=arrayfun(@TempReturnFn, a1primevals,a2primevals, a1vals,a2vals, zvals);
        elseif l_a==2 && l_z==2
            z1vals=z_gridvals(z_c,1);
            z2vals=z_gridvals(z_c,1);
            ReturnMatrix_z=arrayfun(@TempReturnFn, a1primevals, a2primevals, a1vals,a2vals, z1vals,z2vals);
        end
        if ~(l_a==1)
            ReturnMatrix_z=reshape(ReturnMatrix_z,[N_a,N_a]);
        end
        
        %Calc the condl expectation term (except beta), which depends on z but
        %not on control variables
        EV_z=VKronold.*(ones(N_a,1,'gpuArray')*pi_z(z_c,:)); %kron(ones(N_a,1),pi_z(z_c,:));
        EV_z(isnan(EV_z))=0; %multilications of -Inf with 0 gives NaN, this replaces them with zeros (as the zeros come from the transition probabilites)
        EV_z=sum(EV_z,2);
                
        entireRHS=ReturnMatrix_z+beta*EV_z*ones(1,N_a);%,1); %aprime by 1
        
        %Calc the max and it's index
        [Vtemp,maxindex]=max(entireRHS,[],1);
        VKron(:,z_c)=Vtemp;
        PolicyIndexes(:,z_c)=maxindex;
        
        tempmaxindex=maxindex+(0:1:N_a-1)*N_a;
        Ftemp(:,z_c)=ReturnMatrix_z(tempmaxindex); 
    end
    
    VKrondist=reshape(VKron-VKronold,[N_a*N_z,1]); VKrondist(isnan(VKrondist))=0;
    currdist=max(abs(VKrondist));
    if isfinite(currdist) %Use Howards Policy Fn Iteration Improvement
        for Howards_counter=1:Howards
            VKrontemp=VKron;
            
            EVKrontemp=VKrontemp(PolicyIndexes,:);
            EVKrontemp=EVKrontemp.*aaa;
            EVKrontemp(isnan(EVKrontemp))=0;
            EVKrontemp=reshape(sum(EVKrontemp,2),[N_a,N_z]);
            VKron=Ftemp+beta*EVKrontemp;
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

Policy=PolicyIndexes;



end