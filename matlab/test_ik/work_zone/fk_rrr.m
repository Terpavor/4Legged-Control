function R = ik_rrr( F )
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
    
    tmp(:,:,1) = eye(4); % �� �����������, ����� �������� ����
    
    tmp(:,:,2) =    tmp(:,:,1)                  	* ... % �� ����������� ���������
                    makehgtform('xrotate',pi+F(1))  * ...
                    makehgtform('translate',[0 0 L(1)]);
    
    tmp(:,:,3) =    tmp(:,:,2)                  	* ...
                    makehgtform('yrotate',F(2))     * ...
                    makehgtform('translate',[0 0 L(2)]);
    
    tmp(:,:,4) =    tmp(:,:,3)                   	* ...
                    makehgtform('yrotate', F(3))  	* ...
                    makehgtform('translate',[0 0 L(3)]);
    
    R(:,1) = r;
    for i=1:4 % �� �����������, ����� ������ � 2
        R(:,i) = tmp(:,:,i)*r;
    end
    % ������� ��������� ������ [1 1 1 1]
    R = R(1:3,:);
    
    % N ����� 1 2 3 4
    %   R = [ 0 0 ? ?   x
    %         0 ? ? ?   y
    %         0 ? ? ? ] z
    %
end