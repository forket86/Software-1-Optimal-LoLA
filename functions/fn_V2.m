function V = fn_V2(p,v_params)
% This function 
%  takes the 5-dimensional vector v_params
%  constructs: (coeffs0, ... , coeffs4) and V 

% for the example of Section 2, 

v0 = v_params(1);
v1 = v_params(2);
v2 = v_params(3);
cL = v_params(4);
cH = v_params(5);

coeff4 = -v2/(6*(-cH+cL)^2);
coeff3 = (2*v2*cL+v1-2)/(6*(-cH+cL)^2);
coeff2 = -(cL*(v1-2))/(2*(-cH+cL)^2);
coeff1 = -((v2*cL - (3*v1)/2 + 3)*cL^2)/(3*(-cH + cL)^2);
coeff0 = (-v2*cH^4 + (2*v1 - 4)*cH^3 + (6*cL + 6*v0)*cH^2 + (4*cL^3*v2 - 6*cL^2*v1 - 12*cL*v0)*cH - 2*v2*cL^4 + 3*v1*cL^3 + 6*v0*cL^2)/(6*(-cH + cL)^2);

V = coeff4 * p^4 + coeff3 * p^3 + coeff2 * p^2 + coeff1 * p + coeff0;

end

