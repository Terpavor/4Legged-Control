function supporting_polygon = get_supporting_polygon(R, ground_height)

    sp_i = legs_on_ground(R, ground_height);

    supporting_polygon = [];
    for i = sp_i
        supporting_polygon = [supporting_polygon, R{i}(:,end)];
    end
    supporting_polygon(3,:) = ground_height; % проецируем на землю
end