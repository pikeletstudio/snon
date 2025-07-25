// glow effect shader
uniform float threshold = 0.5;
const vec4 minColor = vec4(1.0, 1.0, 1.0, 0.0);


vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{	
	vec4 pixel_color = Texel(texture, texture_coords);
	vec4 stencil;
	if (dot (pixel_color, minColor) < threshold)
    {
        stencil = pixel_color;
    }
    else
    {
        stencil = vec4(0.0);
    }

    stencil = stencil * color;


	// --- 
	vec4 blur = vec4(0);
	const int diff = 2;
    for (int x = -diff; x < diff + 1; x++)
    {
        for (int y = -diff; y < diff + 1; y++)
        {
            vec2 offset = vec2(x,y) / vec2(1000, 800) * 2.0;
            blur += Texel(texture, texture_coords + offset);
        }
    }
    
    blur /= 35.0;
    return (pixel_color + blur + stencil * 0.3) / 1.2;

}
