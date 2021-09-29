function [F_out,err2] = fn_getFfromSecondOrderStat(G_observed,N,F_guess)

% Num nodes 
T=length(G_observed);

%Formula for second order stats
G=@(F) 1-((1-F).^N+N*F.*(1-F).^(N-1));

%% Back out F from G, pretending we do not know it
options = optimoptions('fsolve','Display','iter','MaxFunctionEvaluations',100000,'MaxIterations',100000,'Algorithm','levenberg-marquardt','OptimalityTolerance',1e-14,'StepTolerance',1e-14,'FunctionTolerance',1e-14);
if isempty(F_guess)
    F_guess=linspace(0,1,T);
end
[F_out, fval]=fsolve(@(F) G_observed-G(F),F_guess,options);
%Step 1
err1=max(abs(fval));

for c_iter=1:T
    [F_out(c_iter), fval(c_iter)]=fzero(@(Fc) G_observed(c_iter)-G(Fc),F_out(c_iter));
end
%Step 2
err2=max(abs(fval));

end

