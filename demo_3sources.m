clear;
clc
Dataname = '3sources3vbigRnSp';
addpath('.\Measure')
addpath('.\datasets')
% % % ---- parameters for percentDel = 0.5 --------- %
percentDel = 0.5;
lambda1  = 1e-2;%
lambda2  = 1e-4;%
lambda3  = 1e-4;%
beta = 1e-2;%


Datafold = [Dataname,'_percentDel_',num2str(percentDel),'.mat'];
load(Dataname);
load(Datafold);
num_view = length(X);%data number
numClust = length(unique(truth));%
numInst  = length(truth); %
for f = 1:10 % you can choose it from 1~10  indicates randomly pre-formed incomoplete index, the final result is obtained by average
            ind_folds = folds{f};
            load(Dataname);
            truthF = truth;
            clear truth
            for iv = 1:length(X)
                X1 = X{iv}';
                X1 = NormalizeFea(X1,1);%归一化手段
                ind_0 = find(ind_folds(:,iv) == 0);  % indexes of misssing instances 缺失实例的索引
                X1(ind_0,:) = 0;
                Y{iv} = X1';
                H1 = eye(numInst); %构建索引矩阵W
                ind_1 = find(ind_folds(:,iv) == 1);
                H1(ind_1,:) = [];
                H{iv} = H1;
                Ind_ms{iv} = ind_0;
            end
            clear X X1 W1 ind_0
            X = Y;
            clear Y
            Lv=featuregraph(X);

            max_iter = 50;
            dim = numClust;
            [P] = MIMB(X,H,Lv,Ind_ms,lambda1,lambda2,lambda3,beta,max_iter,dim);
            P(isnan(P)) = 0;
            P(isinf(P)) = 1e5;
            new_F = P';
            norm_mat = repmat(sqrt(sum(new_F.*new_F,2)),1,size(new_F,2));
            % avoid divide by zero
            for i = 1:size(norm_mat,1)
                if (norm_mat(i,1)==0)
                    norm_mat(i,:) = 1;
                end
            end
            new_F = new_F./norm_mat;
            %rand('seed',230); %You need to choose the appropriate random seed for kmeans
            pre_labels    = kmeans(real(new_F),numClust,'emptyaction','singleton','replicates',20,'display','off');
            result = ClusteringMeasure(truthF,pre_labels);
            ACC(f) = result(1)*100;
            NMI(f) = result(2)*100;
            Pur(f) = result(3)*100;
            
end
mean_acc = mean(ACC)
mean_nmi = mean(NMI)
mean_pur = mean(Pur)
