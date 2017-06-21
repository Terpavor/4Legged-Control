function [F, warn_msg] = inverse_kinematics(g, varargin)
% arguments: (input)
% 1) g          - target point
% 2) signum     - +1 or -1: defines 1 of 2 possible IK solutions(configurations)
%                 Not used in 'jacobian' method.
% 3) method     - 'algebraic', 'trigonometric', 'circles', 'jacobian'
% 4-7) ...      - other arguments to 'jacobian' method
%
% arguments: (output)
% 1) F          - 3x1 angles[0 2pi] vector
% 2) warn_msg   - warning message if target point is unreachable
%
% variables:
% 1) L          - 1x3 leg segments' length vector

    global L    
    
    n_varargs = length(varargin);
    
    if(n_varargs > 0)   signum = varargin{1};
    else                signum = +1;
    end
    if(n_varargs > 1) 	method = varargin{2};
    else                method = 'algebraic';
    end
    bounds = deg2rad([ 	-60     60
                        -160    160
                        -160    160]);
    
    F = zeros(3,1);
    warn_msg = '';
    
    
    x = g(1);
    y = g(2);
    z = g(3);
    
    %% Ќаходим F(1)
    %F(1) = pi- atan2(y, z);
    F(1) = wrapToPi(   pi/2+ atan2(z, y)   );
    
    %% ѕровер€ем ограничени€ на угол F(1)
%     if F(1) < bounds(1,1) || F(1) > bounds(1,2)
% %         if      F(1) < bounds(1,1)            i = 1;
% %         elseif  F(1) > bounds(1,2)            i = 2;
% %         end
% %         normal = [0 cos(bounds(1,i)) sin(bounds(1,i))]';
% %         new_g = g-dot(g, normal)*normal;
% %         dist = norm(new_g-g);
% %         g = new_g;
% %         F(1) = bounds(1,i);
%         for i=1:2
%             normal{i} = [0 cos(bounds(1,i)) sin(bounds(1,i))]';
%             new_g{i} = g-dot(g, normal{i})*normal{i};
%             dist(i) = norm(new_g{i}-g);
%         end
%         [~, min_i] = min(dist);
%         g = new_g{min_i};
%         F(1) = bounds(1,min_i);
%         
%         tmp_msg = sprintf('angle F(1)=%f was outside the range\n', F(1));
%         warn_msg = sprintf('%s%s',warn_msg,tmp_msg); % как strcat
%     end
    
    %% ѕровер€ем ближнюю и дальную мертвые зоны(сферы)
    [g, tmp_msg] = dead_zone_check(g, F(1));
    warn_msg = sprintf('%s%s',warn_msg,tmp_msg); % как strcat
    
    %% Ќаходим F(2) и F(3) одним из методов инверсной кинематики
    
    x = g(1);
    y = g(2);
    z = g(3);
    
    switch method
        case 'algebraic' % решение 1
            new_norm_g = norm(g + [0 -sin(F(1)) cos(F(1))]'*L(1));
            z_ = dot(g, [0 sin(pi+F(1)) -cos(pi+F(1))]')+L(1); %norm([cos(pi+F(1)) sin(pi+F(1))]*norm

            cos_f3 = (new_norm_g^2-L(2)^2-L(3)^2)/(2*L(2)*L(3));
            sin_f3 = -signum*sqrt(1-cos_f3^2);
            F(3) = atan2(sin_f3, cos_f3);

            F(2) = pi/2+ atan2(z_, x) - atan2(L(3)*sin_f3, L(2)+L(3)*cos_f3);
    
        case 'trigonometric' % решение 2
            % найдем p2p4 вычита€ p1p2=L(1)(повернутый на F(1)) из p1p4
            new_norm_g = norm(g - [0; sin(F(1)); -cos(F(1))]*L(1));
            %new_norm_g = norm(g - L(1)/sqrt(y*y+z*z)*[0; y; z]);
            % найдем вспомогательный угол из треугольника p2 p4 (0,gz_)
            F_21 = asin( x / new_norm_g );
            % другой вспомогательный угол через теорему косинусов
            F_22 = signum*acos( (L(2)^2 + new_norm_g^2 - L(3)^2) / (2*L(2)*new_norm_g) );
            F(2) = F_21 + F_22;
            % также теорема косинусов
            %F(3) = pi+ signum*acos( (L(2)^2 + L(3)^2 - new_norm_g^2) / (2*L(2)*L(3)) );
            F(3) = signum*(   -pi+acos( (L(2)^2 + L(3)^2 - new_norm_g^2) / (2*L(2)*L(3)) )   );
        
        case 'circles' % решение 3
            z_ = dot(g, [0 sin(pi+F(1)) -cos(pi+F(1))]')+L(1);
            
            if 1
                % http://e-maxx.ru/algo/circles_intersection
                % http://e-maxx.ru/algo/circle_line_intersection
                A = -2*x;
                B = -2*z_;
                C = x^2 + z_^2 + L(2)^2 - L(3)^2;

                x_0 = -A*C/(A^2+B^2);
                z_0 = -B*C/(A^2+B^2);

                d = sqrt(L(2)^2 - C^2/(A^2+B^2));
                mult = sqrt(d^2/(A^2+B^2));

                ax  = x_0 + signum*B*mult;
                az_ = z_0 - signum*A*mult;
            else
                % http://www.litunovskiy.com/gamedev/intersection_of_two_circles/
                d_sq = x*x + z_*z_;
                d = sqrt(d_sq); % - L_1
                
                b = (L(3)*L(3) - L(2)*L(2) + d_sq)/(2*d);
                a = d - b;
                h = sqrt(L(2)*L(2) - a*a);
                
                opos0 = a/d*[x, z_];
                pos1 = opos0 + h/d*signum*[z_, -x];

                ax = pos1(1);
                ay = pos1(2);
            end
            
            F(2) = pi/2 + atan2(az_,ax);
            F(3) = pi/2 - F(2) + atan2(z_-az_,x-ax);
            
        case 'jacobian' % решение 4
            if n_varargs < 3
                error('set arguments to jacobian method.\nsee inverse_kinematics_jacobian.m\n')
            end
            [F, tmp_msg] = inverse_kinematics_jacobian(g, varargin{3:end});
            warn_msg = strcat(warn_msg, tmp_msg);
    end
    
    for i=2:3
        if      F(i) < bounds(i,1)            F(i) = bounds(i,1);
        elseif  F(i) > bounds(i,2)            F(i) = bounds(i,2);
        end
    end
    
    % дл€ проверки движени€:
%     F(1) = 0;
%     F(2) = 0;
%     F(3) = 0;
    
    % ѕровер€ем решение на наличие ошибок    
    if any(~isreal(F)) % если, например, cos(...) > 1 || cos(...) < -1
        c = cellstr(num2str(F,'%1.1f'));
        error('F has complex number:\nF(1) = %s\nF(2) = %s\nF(3) = %s\n', c{:} );
    end
    
    F = wrapToPi(F);
end

function [new_g, msg] = dead_zone_check(g, F_1)

    global L        
    
    % мЄртва€ зона вблизи
    min_dist = abs(L(2)-L(3)) + 10*eps;
    % мЄртва€ зона вдалеке
    max_dist = L(2)+L(3) - 10*eps;
    % всЄ это - относительно L1
    L(1);
    -sin(F_1);
    F_1;
    L_1_vector = [0 -sin(F_1) cos(F_1)]'*(-L(1));
    dist = g - L_1_vector;
    if    ( norm(dist) > max_dist ) % проверка на максимальное рассто€ние
        new_g = dist/norm(dist)*max_dist + L_1_vector;
        msg = sprintf('g is too far\nnew g = (%5.3f; %5.3f; %5.3f)\n', g);
    elseif( norm(dist) == 0 )       % ошибка
        error('g is too close, singular matrix\n');
    elseif( norm(dist) < min_dist)  % проверка на минимальное рассто€ние
        new_g = dist/norm(dist)*min_dist + L_1_vector;
        msg = sprintf('g is too close\nnew g = (%5.3f; %5.3f; %5.3f)\n', g);
    else                            % точка g достижима
        new_g = g;        
        msg = '';
    end
end
    

    
%     F(1) = pi- atan2(y, z);
% 
%     F_21 = asin( x / norm(g) );
%     F_22 = acos( (L(1)^2 + norm(g)^2 - L(2)^2) / (2*L(1)*norm(g)) );
%     F(2) = F_21 + F_22;
% 
%     F(3) = pi+ acos( (L(1)^2 + L(2)^2 - norm(g)^2) / (2*L(1)*L(2)) );
