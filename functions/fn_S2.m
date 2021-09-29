function S = fn_S2(p,v_params)
% This function 
%  takes the 5-dimensional vector v_params
%  constructs: (coeffs0, ... , coeffs4) and S 

% for the example of Section 2, 

v0 = v_params(1);
v1 = v_params(2);
v2 = v_params(3);
cL = v_params(4);
cH = v_params(5);

coeff4 = (-v2)/(6*(cH - cL)^2);
coeff3 = (2*cL*v2 + v1 - 1)/(6*(cH - cL)^2);
coeff2 = - ((v1 - 1)*cL)/(2*(-cH + cL)^2);
coeff1 = - cL^2*(2*cL*v2 - 3*v1 + 3)/(6*(-cH + cL)^2);
coeff0 = (-2*v2*cL^4 + (4*cH*v2 + 3*v1 - 3)*cL^3 + ((-6*v1 + 6)*cH + 6*v0)*cL^2 - 12*v0*cL*cH - cH^2*(cH^2*v2 + (-2*v1 + 2)*cH - 6*v0))/(6*(cH - cL)^2);


S = coeff4*p^4+coeff3*p^3+coeff2*p^2+coeff1*p+coeff0;

end

