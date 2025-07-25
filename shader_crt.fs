// CRT effect shader
const float screenCurve = 6.5;
const float vignetteStrength = 0.36;
const float gammaBoost = 1.08;

vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{	
	// curving
	vec2 centered_coords = texture_coords * 2.0 - 1.0;
	vec2 coord_offset = centered_coords.yx / screenCurve;
	vec2 curved_coords = centered_coords + centered_coords * coord_offset * coord_offset;
	vec2 uncentered_curved_coords = (curved_coords + 1.0) / 2.0;

	vec2 target_coords = uncentered_curved_coords;

	// other effects
	vec3 cutoff = vec3(step(abs(curved_coords.x), 1.0) * step(abs(curved_coords.y), 1.0));
	vec3 scanlines = vec3(sin(8.0 * target_coords.y * 180.0) * 0.1 + 0.8);
	vec3 vignette = vec3(length(pow(abs(centered_coords), vec2(4.0)) / 3.0));

	// combine effects
    vec4 pixel_color = Texel(texture, target_coords);
	vec3 shader_color = pixel_color.rgb * cutoff * scanlines * gammaBoost;
	shader_color -= vignette * vignetteStrength;
    return vec4(shader_color, 1.0);
}
