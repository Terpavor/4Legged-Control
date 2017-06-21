function F = inverse_kinematics( g, varargin)
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
    global L
    nVarargs = length(varargin);
    
    if(nVarargs > 0)
        F = varargin{1};
    else
        F = [0 0 0]';
    end
    if(nVarargs > 1)
        precision = varargin{2};
    else
        precision = 0.1;
    end
    if(nVarargs > 2)
        beta = varargin{3};
    else
        beta = 0.55;
    end
    if(nVarargs > 3)
        max_iterations  = varargin{4};
    else
        max_iterations = 100;
    end
    
    min_sum = min(abs(L(2)-L(3)), abs(L(3)-L(2)));

    
    dist = g - [0 L(1) 0]';
    norm(dist)
    
    sum(L(2:end))
    
    if    ( norm(dist) > sum(L(2:end)) ) % проверка на максимальное расстояние
        g = dist/norm(dist)*(L(2)+L(3)) + [0 L(1) 0]';
        fprintf('g is too far\nnew g = (%5.3f; %5.3f; %5.3f)\n', g);
    elseif( norm(dist) == 0 )
        fprintf('g is too close, singular matrix\n');
        return;
    elseif( norm(dist) < min_sum ) % проверка на минимальное расстояние
        g = dist/norm(dist)*min_sum + [0 L(1) 0]';
        fprintf('g is too close\nnew g = (%5.3f; %5.3f; %5.3f)\n', g);
    end
    
    for i=1:max_iterations
        J = jacobianest(@A_last_point, F)'; % вычисляем матрицу Якоби
        J_inv = pinv(J);                    % Псевдоинверсия матрицы Якоби
        
        e = A_last_point(F);                % Положение схвата
        error = g - e;                      % Ошибка
        if(norm(error) < precision)
            F = wrapTo2Pi(F);
            return;
        end
        d_e = beta*error;                   % Новое перемещение схвата
        d_F = J_inv'*d_e;                   % Вычисляем изменение углов
        F = F+d_F;                          % Применяем изменение углов
    end
    
    F = wrapTo2Pi(F);
    fprintf('max_iterations = %d reached!\ntry to change beta, precision, max_iterations\n', max_iterations);
end

% =======================================
%      sub-function
% =======================================
function R = A_last_point( F )
    R = A(F);
    R = R(1:3,4);
end % sub-function end

% =======================================
%      sub-function
% =======================================
function res = PermsRep(v,k)
%  from https://www.mathworks.com/matlabcentral/fileexchange/30433-blind-channel-estimation-for-stbc-using-higher-order-statistics/content/PermsRep.m
%  PERMSREP Permutations with replacement.
%  
%  PermsRep(v, k) lists all possible ways to permute k elements out of 
%  the vector v, with replacement.

    if nargin<1 || isempty(v)    
        error('v must be non-empty')
    else
        n = length(v);
    end

    if nargin<2 || isempty(k)
        k = n;
    end

    v = v(:).'; %Ensure v is a row vector
    for i = k:-1:1
        tmp = repmat(v,n^(k-i),n^(i-1));
        res(:,i) = tmp(:);
    end
end % sub-function end



    %     d_F(1) = J(:,1)'*d_e;
    %     d_F(2) = J(:,2)'*d_e;
    %     d_F(3) = J(:,3)'*d_e;
    


