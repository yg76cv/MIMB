function [Lv] = featuregraph(X)
for iv = 1:length(X)
                options = [];
                options.NeighborMode = 'KNN';
                options.k = 23;% initialize neighbor
                options.WeightMode = 'Binary';      % Binary  HeatKernel
                Z1 = full(constructW(X{iv},options));%�õ�һ�����������Ľ���ͼ
                Z1 = (Z1+Z1')/2;
                Lv{iv} = diag(sum(Z1,2))-Z1;%�����Lv
            end
end

