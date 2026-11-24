-- Compatibilité avec les zones du fichier source, sans dépendance PolyZone.
PolyZone = {}
function PolyZone:Create(points, options)
    local z = {points=points, name=options.name}
    function z:isPointInside(p)
        local inside, j = false, #self.points
        for i,a in ipairs(self.points) do
            local b = self.points[j]
            if (a.y > p.y) ~= (b.y > p.y) and p.x < (b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x then inside = not inside end
            j = i
        end
        return inside
    end
    return z
end
