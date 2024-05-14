function [P] = MIMB(X,H,Lv,Ind_ms,lambda1,lambda2,lambda3,beta,max_iter,dim)
alpha = ones(length(X),1)/length(X);
PPP = 0;
r=3;
for iv = 1:length(X)
   rand('seed',iv*100);
   linshi_U = rand(size(X{iv},1),dim);
   if size(X{iv},1) > dim
        U{iv} = orth(linshi_U);
   else
       U{iv} = (orth(linshi_U'))';
   end
   rand('seed',iv*1000);
   B{iv} = rand(size(X{iv},1),size(H{iv},1));
   PPP = PPP+U{iv}'*(X{iv}+B{iv}*H{iv});
   inv_Lv{iv} = inv(lambda1*Lv{iv}+2*eye(size(Lv{iv},1)));
end
clear linshi_U
P = PPP/length(X);
alpha_r = alpha.^r;
% -----------  ³õÊ¼»¯  S F------------ %
rand('seed',666);
S = rand(size(X{1},2),size(X{1},2));
S = S - diag(diag(S));
S = (S'+S)/2;
Ls = diag(sum(S,2))-S;%L=D-W
[F, ~, ev] = eig1(Ls,dim, 0);
for iter = 1:max_iter %µü´úmax
    % ------------- P -------------- %
    Temp1 = 0;
    Temp2 = 0;
    for iv = 1:length(X)
        Temp1 = Temp1+alpha_r(iv)*(U{iv}'*(X{iv}+B{iv}*H{iv}));
        Temp2 = Temp2+alpha_r(iv);
    end
    Temp1 = Temp1 + lambda2*P*S;
    Temp2 = Temp2*P + +lambda2*(P*P')*P;
    P=P.*(Temp1./Temp2);
    P(isnan(P)) = 0;
    P(isinf(P)) = 1e5;
    % ------------- S --------------- %
    sum_F = sum(F.^2, 2);
    Df = bsxfun(@plus, sum_F, bsxfun(@plus, sum_F', -2 * (F * F')));
    Df = Df - diag(diag(Df));
    linshi_P = P'*P;
    for i=1:size(linshi_P,1)
        Dp = linshi_P(i,:);
        S(i,:) = (Dp - (lambda3/(4*lambda2))*Df(i,:));
    end
    for is = 1:size(S,1)
        ind = [1:size(S,1)];
        ind(is) = [];
        S(is,ind) = EProjSimplex_new(S(is,ind));
    end
    % --------------- F --------------- %
    LS = (S+S')/2;
    LS = diag(sum(LS)) - LS;
    [F, ~, ev] = eig1(LS, dim, 0);
    % -------- U{v} B{v}--------------- %
    NormX = 0;
    for iv = 1:length(X)
       % -------- U{v} --------- %
       linshi = X{iv}+B{iv}*H{iv};
       temp = linshi*P';
       temp(isnan(temp)) = 0;
       temp(isinf(temp)) = 1e10;
       [Gs,~,Vs] = svd(temp,'econ');
       Gs(isnan(Gs)) = 0;
       Vs(isnan(Vs)) = 0;
       U{iv} = Gs*Vs'; 
       clear Gs Vs
       % ------- B{v} ------- %
       linshi  = U{iv}*P;
       linshi1 = linshi(:,Ind_ms{iv});
       B{iv} = inv_Lv{iv}*(2*linshi1);
       Rec_error(iv) = norm(X{iv}+B{iv}*H{iv}-U{iv}*P,'fro')^2+lambda1*trace(B{iv}'*Lv{iv}*B{iv})+norm(U{iv}'*(X{iv}+B{iv}*H{iv})-P,'fro')^2+beta*(norm(U{iv},'fro')^2);
       NormX = NormX + norm(X{iv},'fro')^2;
    end
    % -------update alpha -------- %
    HH = bsxfun(@power,Rec_error, 1/(1-r));     % h = h.^(1/(1-r));
    alpha = bsxfun(@rdivide,HH,sum(HH)); % alpha = H./sum(H);
    alpha_r = alpha.^r;
    % -------- obj ------------ %
    obj(iter) = (alpha_r*Rec_error'+lambda2*norm(S-P'*P,'fro')^2+lambda3*trace(F'*LS*F))/NormX;
    if iter > 2 && abs(obj(iter)-obj(iter-1))<1e-5
        iter
        break;
    end
end
end