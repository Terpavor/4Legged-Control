function Points = cyclogram_CoM_shift( old_point, new_point, nPoints )
%     
    Vertex(1,:) = old_point;
    Vertex(2,:) = new_point;
    
    
    vector = Vertex(2,:) - Vertex(1,:);
    Points = [      Vertex(1,1) + vector(1) .* linspace(0,1,nPoints)
                    Vertex(1,2) + vector(2) .* linspace(0,1,nPoints)
                    Vertex(1,3) + vector(3) .* linspace(0,1,nPoints) ];
%                 
end