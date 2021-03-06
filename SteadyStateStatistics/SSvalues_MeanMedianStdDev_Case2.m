function SSvalues_MeanMedianStdDev=SSvalues_MeanMedianStdDev_Case2(SteadyStateDist, PolicyIndexes, SSvaluesFn, n_d, n_a, n_s, d_grid, a_grid, s_grid, pi_s,p_val)

num_d=length(n_d);
num_a=length(n_a);
num_s=length(n_s);
N_a=prod(n_a);
N_s=prod(n_s);

SSvalues_MeanMedianStdDev=zeros(length(SSvaluesFn),3); % 3 columns: Mean, Median, and Standard Deviation
d_val=zeros(num_d,1);
a_val=zeros(num_a,1);
s_val=zeros(num_s,1);
PolicyIndexesKron=reshape(PolicyIndexes,[num_d,N_a,N_s]);
SteadyStateDistVec=reshape(SteadyStateDist,[N_a*N_s,1]);
for i=1:length(SSvaluesFn)
    Values=zeros(N_a,N_s);
    for j1=1:N_a
        a_ind=ind2sub_homemade([n_a],j1);
        for jj1=1:num_a
            if jj1==1
                a_val(jj1)=a_grid(a_ind(jj1));
            else
                a_val(jj1)=a_grid(a_ind(jj1)+sum(n_a(1:jj1-1)));
            end
        end
        for j2=1:N_s
            s_ind=ind2sub_homemade([n_s],j2);
            for jj2=1:num_s
                if jj2==1
                    s_val(jj2)=s_grid(s_ind(jj2));
                else
                    s_val(jj2)=s_grid(s_ind(jj2)+sum(n_s(1:jj2-1)));
                end
            end
            d_ind=PolicyIndexesKron(:,j1,j2);
            for kk=1:num_d
                if kk==1
                    d_val(kk)=d_grid(d_ind(kk));
                else
                    d_val(kk)=d_grid(d_ind(kk)+sum(n_d(1:kk-1)));
                end
            end
            Values(j1,j2)=SSvaluesFn{i}(d_val,a_val,s_val,pi_s,p_val);
        end
    end
    
    Values=reshape(Values,[N_a*N_s,1]);
    
    %Mean
    SSvalues_MeanMedianStdDev(i,1)=sum(Values.*SteadyStateDistVec);
    
    %Median
    [SortedValues,SortedValues_index] = sort(Values);
    SortedSteadyStateDistVec=SteadyStateDistVec(SortedValues_index);
    
    SSvalues_MeanMedianStdDev(i,2)=min(SortedValues(cumsum(SortedSteadyStateDistVec)>0.5));
    
    %Standard Deviation
    SSvalues_MeanMedianStdDev(i,3)=sqrt(sum(SteadyStateDistVec.*((Values-SSvalues_MeanMedianStdDev(i,1).*ones(N_a*N_s,1)).^2)));
    
end

end

