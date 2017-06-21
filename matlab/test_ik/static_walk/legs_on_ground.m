function leg_i = legs_on_ground(R, ground_height)
    leg_i = [];
    leg_count = length(R);
    for i=1:leg_count
        if R{i}(3,end) < ground_height + 0.02
            leg_i = [leg_i  i];
        end
    end
end