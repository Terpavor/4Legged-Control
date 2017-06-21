function R = forward_kinematics( F )
% arguments: (input)
% 1) F          - 3x1 angles[0 2pi] vector
%
% arguments: (output)
% 1) R          - 3x4 coordinates(in leg coordinate system) matrix
%
% variables:
% 1) L          - 1x3 leg segments' length vector
    global L
    r = [0 0 0 1]';
    R = zeros(4,4);
    tmp = zeros(4,4,4);
    
    tmp(:,:,1) = eye(4); % не обязательно, можно оставить нули
    
    tmp(:,:,2) =    tmp(:,:,1)                  	* ... % не обязательно домножать
                    makehgtform('xrotate',pi+F(1))  * ...
                    makehgtform('translate',[0 0 L(1)]);
    
    tmp(:,:,3) =    tmp(:,:,2)                  	* ...
                    makehgtform('yrotate',F(2))     * ...
                    makehgtform('translate',[0 0 L(2)]);
    
    tmp(:,:,4) =    tmp(:,:,3)                   	* ...
                    makehgtform('yrotate', F(3))  	* ...
                    makehgtform('translate',[0 0 L(3)]);
    
    R(:,1) = r;
    for i=1:4 % не обязательно, можно начать с 2
        R(:,i) = tmp(:,:,i)*r;
    end
    % удаляем последнюю строку [1 1 1 1]
    R = R(1:3,:);
    
    % N точки 1 2 3 4
    %   R = [ 0 0 ? ?   x
    %         0 ? ? ?   y
    %         0 ? ? ? ] z
    %
end

function X1Y2 = eul2hgtform_x1y2( F )
% 
        c = @(x) cos( F(x) );
        s = @(x) sin( F(x) );
        
        X1Y2 = [    c(2),       0,          s(2)        0
                    s(1)*s(2),  c(1),      -c(2)*s(1)   0
                   -c(1)*s(2),  s(1),       c(1)*c(2)   0
                    0           0           0           1];
end



%     tmp(:,:,3) =    makehgtform('xrotate',pi+F(1))* ...
%                     makehgtform('yrotate',F(2)) * ...
%                     makehgtform('translate',[0 0 L(2)]);
%     % эквивалентно следующему:
% %     tmp(:,:,3) =    eul2hgtform_x1y2([pi+F(1) F(2)])    * ...
% %                     makehgtform('translate',[0 0 L(1)]);
%     
%     tmp(:,:,4) =    tmp(:,:,3)                      	* ...
%                     makehgtform('yrotate', F(3))        * ...
%                     makehgtform('translate',[0 0 L(3)]);




%     tmp(:,:,2) =    makehgtform('yrotate',-F(1));%          * ...
%                     %makehgtform('translate',[0 L(1) 0]);
% 
%     tmp(:,:,3) =    tmp(:,:,2) * ...
%                     makehgtform('xrotate',F(2))          * ...
%                     makehgtform('translate',[0 0 -L(1)]);
% 
%     tmp(:,:,4) =    tmp(:,:,3) * ...
%                     makehgtform('yrotate',-F(3))          * ...
%                     makehgtform('translate',[0 0 -L(2)]);
%     R(:,1) = r;
%     for i=2:4
%         R(:,i) = tmp(:,:,i)*r;
%     end










%     R(:,2) =    makehgtform('yrotate',F(1))          * ...
%                 makehgtform('translate',[0 L(1) 0])  * r;
% 
%     R(:,3) =    makehgtform('yrotate',F(1))          * ...
%                 makehgtform('translate',[0 L(1) 0])  * ...
%                 makehgtform('zrotate',F(2))          * ...
%                 makehgtform('translate',[L(2) 0 0])  * r;
% 
%     R(:,4) =    makehgtform('yrotate',F(1))          * ...
%                 makehgtform('translate',[0 L(1) 0])  * ...
%                 makehgtform('zrotate',F(2))          * ...
%                 makehgtform('translate',[L(2) 0 0])  * ...
%                 makehgtform('zrotate',F(3))          * ...
%                 makehgtform('translate',[L(3) 0 0])  * r;
% 
%     R(:,5) =    makehgtform('yrotate',F(1))          * ...
%                 makehgtform('translate',[0 L(1) 0])  * ...
%                 makehgtform('zrotate',F(2))          * ...
%                 makehgtform('translate',[L(2) 0 0])  * ...
%                 makehgtform('zrotate',F(3))          * ...
%                 makehgtform('translate',[L(3) 0 0])  * ...
%                 makehgtform('zrotate',F(4))          * ...
%                 makehgtform('translate',[L(4) 0 0])  * r;


%     R(:,2) =    makehgtform('yrotate',-f1) * ...
%                 makehgtform('translate',[0 -l1 0]) * R(:,1);
%     
%     R(:,3) =    makehgtform('zrotate',-f2) * ... 
%                 makehgtform('translate',[-l2 0 0]) * R(:,2);
%     
%     R(:,4) =    makehgtform('zrotate',-f3) * ... 
%                 makehgtform('translate',[-l3 0 0]) * R(:,3);
%     
%     R(:,5) =    makehgtform('zrotate',-f4) * ... 
%                 makehgtform('translate',[-l4 0 0]) * R(:,4);
    
    %R(:,2) = Ay(-f1)*Ady(-l1)*R(:,1);
    %R(:,3) = Az(-f2)*Adx(-l2)*R(:,2);
    %R(:,4) = Az(-f3)*Adx(-l3)*R(:,3);
    %R(:,5) = Az(-f4)*Adx(-l4)*R(:,4);