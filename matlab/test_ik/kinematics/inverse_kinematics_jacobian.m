function [F, warn_msg] = inverse_kinematics_jacobian( g, varargin)
% arguments: (input)
% 1) g - target point
% 2) F - initial angles
% 3) precision
% 4) beta - step
% 5) max_iterations
%
% arguments: (output)
% F - angles
%
% variables:
% e - end effector point
% 
    warn_msg = '';
    n_varargs = length(varargin);
    
    if(n_varargs > 0)   F = varargin{1};
    else                F = [0 0 0 0]';
    end
    if(n_varargs > 1) 	precision = varargin{2};
    else                precision = 0.1;
    end
    if(n_varargs > 2)  	beta = varargin{3};
    else                beta = 0.55;
    end
    if(n_varargs > 3)	max_iterations  = varargin{4};
    else                max_iterations = 100;
    end
    
    for i=1:max_iterations
        J = jacobianest(...         % ��������� ������� �����
            @forward_kinematics_last_point, F)';
        J_inv = pinv(J);         	% �������������� ������� �����
        
        e = forward_kinematics_last_point(F);       	
                                    % ��������� ������
        error = g - e;             	% ������
        if(norm(error) < precision)
            F = wrapTo2Pi(F);
            return;
        end
        d_e = beta*error;         	% ����� ����������� ������
        d_F = J_inv'*d_e;         	% ��������� ��������� �����
        F = F+d_F;                 	% ��������� ��������� �����
    end
    
    F = wrapTo2Pi(F);
    warn_msg = sprintf( ...
    'max_iterations = %d reached!\ntry to change beta, precision, max_iterations\n', max_iterations);
end

% =======================================
%      sub-function
% =======================================
function R = forward_kinematics_last_point( F )
    R = forward_kinematics(F);
    R = R(1:3,end);
end % sub-function end
















