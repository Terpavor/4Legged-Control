function [F, is_outside, warn_msg] = angle_bounds_check(F)

    warn_msg = '';
    is_outside = false;
    
    bounds = ...
            [ 	-90     90
                -(180-20)     180-20
                0       160];
    bounds = (deg2rad(bounds));
    
    
    if      F(1) < bounds(1,1)
        is_outside = true;
        tmp_msg = sprintf('angle F(%d)=%f < %f\n', 1,F(1),bounds(1,1));
        warn_msg = sprintf('%s%s',warn_msg,tmp_msg);
        F(1) = bounds(1,1);
    elseif  F(1) > bounds(1,2)
        is_outside = true;
        tmp_msg = sprintf('angle F(%d)=%f > %f\n', 1,F(1),bounds(1,2));
        warn_msg = sprintf('%s%s',warn_msg,tmp_msg);
        F(1) = bounds(1,2);
    end
    if is_outside
        R = forward_kinematics(F);
        g = R(1:3,end);
        [F, tmp_msg] = inverse_kinematics(g, -1);
        warn_msg = sprintf('%s%s',warn_msg,tmp_msg);
    end
    
    if      F(2) < bounds(2,1)
        is_outside = true; 
        tmp_msg = sprintf('angle F(%d)=%f < %f\n', 2,F(2),bounds(2,1));
        warn_msg = sprintf('%s%s',warn_msg,tmp_msg);
        F(2) = bounds(2,1);
    elseif  F(2) > bounds(2,2)
        is_outside = true; 
        tmp_msg = sprintf('angle F(%d)=%f > %f\n', 2,F(2),bounds(2,2));
        warn_msg = sprintf('%s%s',warn_msg,tmp_msg);
        F(2) = bounds(2,2);
    end
%     if      F(2) > bounds(2,1) && F(2) < bounds(2,2)
%         is_outside = true; 
%         tmp_msg = sprintf('angle F(%d)=%f ~ %f\n', 2,F(2),bounds(2,1));
%         warn_msg = sprintf('%s%s',warn_msg,tmp_msg);
%         F(2) = bounds(2,1);
%     end
    
    if      F(3) < bounds(3,1)
        is_outside = true; 
        tmp_msg = sprintf('angle F(%d)=%f < %f\n', 3,F(3),bounds(3,1));
        warn_msg = sprintf('%s%s',warn_msg,tmp_msg);
        F(3) = bounds(3,1);
    elseif  F(3) > bounds(3,2)
        is_outside = true; 
        tmp_msg = sprintf('angle F(%d)=%f > %f\n', 3,F(3),bounds(3,2));
        warn_msg = sprintf('%s%s',warn_msg,tmp_msg);
        F(3) = bounds(3,2);
    end
%     F_out = F_in;
%     bounds = ...
%             [     270    90
%                 180    160
%                 0    160];
%     bounds = (deg2rad(bounds))
%     for i = 2:3
%         if      F_in(i) < bounds(i,1)  is_outside = true; F_out(i) = bounds(i,1);
%         elseif  F_in(i) > bounds(i,2)  is_outside = true; F_out(i) = bounds(i,2);
%         end
%     end
%     
end

