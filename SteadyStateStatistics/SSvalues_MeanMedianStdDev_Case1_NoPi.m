function SSvalues_MeanMedianStdDev=SSvalues_MeanMedianStdDev_Case1_NoPi(SteadyStateDist, PolicyIndexes, SSvaluesFn, SSvalueParams, n_d, n_a, n_z, d_grid, a_grid, z_grid,p_val, Parallel)

if n_d(1)==0
    l_d=0;
else
    l_d=length(n_d);
end
l_a=length(n_a);
l_z=length(n_z);
N_a=prod(n_a);
N_z=prod(n_z);


if Parallel==2
    SSvalues_MeanMedianStdDev=zeros(length(SSvaluesFn),3, 'gpuArray'); % 3 columns: Mean, Median, and Standard Deviation

    SteadyStateDistVec=reshape(SteadyStateDist,[N_a*N_z,1]);
    
    PolicyValues=PolicyInd2Val_Case1(PolicyIndexes,n_d,n_a,n_z,d_grid,a_grid, Parallel);
    permuteindexes=[1+(1:1:(l_a+l_z)),1];    
    PolicyValuesPermute=permute(PolicyValues,permuteindexes); %[n_a,n_s,l_d+l_a]

    for i=1:length(SSvaluesFn)
        Values=ValuesOnSSGrid_Case1(SSvaluesFn{i}, SSvalueParams,PolicyValuesPermute,n_d,n_a,n_z,a_grid,z_grid,p_val,Parallel);
        Values=reshape(Values,[N_a*N_z,1]);        
        
        %Mean
        SSvalues_MeanMedianStdDev(i,1)=sum(Values.*SteadyStateDistVec);
        
        %Median
        [SortedValues,SortedValues_index] = sort(Values);
        SortedSteadyStateDistVec=SteadyStateDistVec(SortedValues_index);
        
        SSvalues_MeanMedianStdDev(i,2)=min(SortedValues(cumsum(SortedSteadyStateDistVec)>0.5));
        
        %Standard Deviation
        SSvalues_MeanMedianStdDev(i,3)=sqrt(sum(SteadyStateDistVec.*((Values-SSvalues_MeanMedianStdDev(i,1).*ones(N_a*N_z,1)).^2))); 
    end
else
    SSvalues_MeanMedianStdDev=zeros(length(SSvaluesFn),3); % 3 columns: Mean, Median, and Standard Deviation
    d_val=zeros(l_d,1);
    aprime_val=zeros(l_a,1);
    a_val=zeros(l_a,1);
    s_val=zeros(l_z,1);
    
    PolicyIndexesKron=reshape(PolicyIndexes,[l_d+l_a,N_a,N_z]);
    SteadyStateDistVec=reshape(SteadyStateDist,[N_a*N_z,1]);
    
    for i=1:length(SSvaluesFn)
        if Parallel==2
            Values=zeros(N_a,N_z,'gpuArray');
        else
            Values=zeros(N_a,N_z);
        end
        for j1=1:N_a
            a_ind=ind2sub_homemade([n_a],j1);
            for jj1=1:l_a
                if jj1==1
                    a_val(jj1)=a_grid(a_ind(jj1));
                else
                    a_val(jj1)=a_grid(a_ind(jj1)+sum(n_a(1:jj1-1)));
                end
            end
            for j2=1:N_z
                s_ind=ind2sub_homemade([n_z],j2);
                for jj2=1:l_z
                    if jj2==1
                        s_val(jj2)=z_grid(s_ind(jj2));
                    else
                        s_val(jj2)=z_grid(s_ind(jj2)+sum(n_z(1:jj2-1)));
                    end
                end
                if l_d==0
                    
                else
                    d_ind=PolicyIndexesKron(1:l_d,j1,j2);
                    for kk=1:l_d
                        if kk==1
                            d_val(kk)=d_grid(d_ind(kk));
                        else
                            d_val(kk)=d_grid(d_ind(kk)+sum(n_d(1:kk-1)));
                        end
                    end
                end
                aprime_ind=PolicyIndexesKron(l_d+1:l_d+l_a,j1,j2);
                for kk2=1:l_a
                    if kk2==1
                        aprime_val(kk2)=a_grid(aprime_ind(kk2));
                    else
                        aprime_val(kk2)=a_grid(aprime_ind(kk2)+sum(n_a(1:kk2-1)));
                    end
                end
                Values(j1,j2)=SSvaluesFn{i}(d_val,aprime_val,a_val,s_val,pi_s,p_val);
            end
        end
        
        Values=reshape(Values,[N_a*N_z,1]);
        
        %Mean
        SSvalues_MeanMedianStdDev(i,1)=sum(Values.*SteadyStateDistVec);
        
        %Median
        [SortedValues,SortedValues_index] = sort(Values);
        SortedSteadyStateDistVec=SteadyStateDistVec(SortedValues_index);
        
        SSvalues_MeanMedianStdDev(i,2)=min(SortedValues(cumsum(SortedSteadyStateDistVec)>0.5));
        
        %Standard Deviation
        SSvalues_MeanMedianStdDev(i,3)=sqrt(sum(SteadyStateDistVec.*((Values-SSvalues_MeanMedianStdDev(i,1).*ones(N_a*N_z,1)).^2)));
        
end

end

