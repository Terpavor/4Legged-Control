function Points = cyclogram_make_one_step( old_point, new_point, nPoints )
%     
%     Vertex(1,:) = point+[+1 0 0]'.*len;
%     Vertex(2,:) = point+[0 0 0]'.*len;
%     
%     
%     vector = Vertex(2,:) - Vertex(1,:);
%     Points = [      Vertex(1,1) + vector(1) .* linspace(0,1,nPoints)
%                     Vertex(1,2) + vector(2) .* linspace(0,1,nPoints)
%                     Vertex(1,3) + vector(3) .* linspace(0,1,nPoints) ];
%                 
%     Points = empty();

    Points = old_point;
    for a = deg2rad(180) : -deg2rad(180)/(nPoints-3) : deg2rad(0)
        newPoints = (new_point+old_point)/2+[cos(a) 0 sin(a)]'*norm(new_point-old_point)/2;
        Points = cat(2, Points, newPoints);
    end
    newPoints = (new_point+old_point)/2+[cos(0) 0 sin(0)]'*norm(new_point-old_point)/2;
    Points = cat(2, Points, newPoints);
    %Vertex(i,:) = point+[-1 0 0]'.*len;
end