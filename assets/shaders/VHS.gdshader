shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

uniform bool overlay = false;

uniform float scanlines_opacity : hint_range(0.0, 1.0) = 0.4;
uniform float scanlines_width : hint_range(0.0, 0.5) = 0.25;
uniform float grille_opacity : hint_range(0.0, 1.0) = 0.3;
uniform vec2 resolution = vec2(640.0, 480.0);

uniform bool pixelate = true;

uniform bool roll = true;
uniform float roll_speed = 8.0;
uniform float roll_size : hint_range(0.0, 100.0) = 15.0;
uniform float roll_variation : hint_range(0.1, 5.0) = 1.8;
uniform float distort_intensity : hint_range(0.0, 0.2) = 0.05;

uniform float noise_opacity : hint_range(0.0, 1.0) = 0.4;
uniform float noise_speed = 5.0;

uniform float static_noise_intensity : hint_range(0.0, 1.0) = 0.06;

uniform float aberration : hint_range(-1.0, 1.0) = 0.03;
uniform float brightness = 1.4;
uniform bool discolor = true;

uniform float warp_amount : hint_range(0.0, 5.0) = 1.0;
uniform bool clip_warp = false;

uniform float vignette_intensity = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;

vec2 random(vec2 uv){
	uv = vec2(dot(uv, vec2(127.1,311.7)),
		dot(uv, vec2(269.5,183.3)));
	return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}

float noise(vec2 uv) {
	vec2 uv_index = floor(uv);
	vec2 uv_fract = fract(uv);
	vec2 blur = smoothstep(0.0, 1.0, uv_fract);

	return mix(
		mix(dot(random(uv_index), uv_fract),
			dot(random(uv_index + vec2(1.0,0.0)), uv_fract - vec2(1.0,0.0)), blur.x),
		mix(dot(random(uv_index + vec2(0.0,1.0)), uv_fract - vec2(0.0,1.0)),
		dot(random(uv_index + vec2(1.0,1.0)), uv_fract - vec2(1.0,1.0)), blur.x),
        blur.y
    ) * 0.5 + 0.5;
}

vec2 warp(vec2 uv){
    vec2 delta = uv - 0.5;
    float delta2 = dot(delta, delta);
    float delta4 = delta2 * delta2;
    float delta_offset = delta4 * warp_amount;
    return uv + delta * delta_offset;
}

float border(vec2 uv){
    float radius = min(warp_amount, 0.08);
    radius = max(min(abs(radius * 2.0), 1.0), 1e-5);
    vec2 abs_uv = abs(uv * 2.0 - 1.0) - vec2(1.0) + radius;
    float dist = length(max(vec2(0.0), abs_uv)) / radius;
    float square = smoothstep(0.96, 1.0, dist);
    return clamp(1.0 - square, 0.0, 1.0);
}

float vignette(vec2 uv){
    uv *= 1.0 - uv;
    float v = uv.x * uv.y * 15.0;
    return pow(v, vignette_intensity * vignette_opacity);
}

void fragment()
{
    vec2 uv = overlay ? warp(SCREEN_UV) : warp(UV);
    vec2 text_uv = uv;
    vec2 roll_uv = vec2(0.0);
    float time = roll ? TIME : 0.0;

    if (pixelate) {
        text_uv = ceil(uv * resolution) / resolution;
    }

    float roll_line = 0.0;
    if (roll || noise_opacity > 0.0) {
        roll_line = smoothstep(0.3, 0.9, sin(uv.y * roll_size - (time * roll_speed)));
        roll_line *= roll_line * smoothstep(0.3, 0.9,
            sin(uv.y * roll_size * roll_variation - (time * roll_speed * roll_variation)));
        roll_uv = vec2(roll_line * distort_intensity * (1.0 - UV.x), 0.0);
    }

    vec4 text;
    if (roll) {
        text.r = texture(SCREEN_TEXTURE, text_uv + roll_uv * 0.8 + vec2(aberration, 0.0) * 0.1).r;
        text.g = texture(SCREEN_TEXTURE, text_uv + roll_uv * 1.2 - vec2(aberration, 0.0) * 0.1).g;
        text.b = texture(SCREEN_TEXTURE, text_uv + roll_uv).b;
        text.a = 1.0;
    } else {
        text.r = texture(SCREEN_TEXTURE, text_uv + vec2(aberration, 0.0) * 0.1).r;
        text.g = texture(SCREEN_TEXTURE, text_uv - vec2(aberration, 0.0) * 0.1).g;
        text.b = texture(SCREEN_TEXTURE, text_uv).b;
        text.a = 1.0;
    }

    float r = text.r;
    float g = text.g;
    float b = text.b;

    uv = warp(UV);

    if (grille_opacity > 0.0){
        float gr = smoothstep(0.85, 0.95, abs(sin(uv.x * resolution.x * 3.14159)));
        float gg = smoothstep(0.85, 0.95, abs(sin(1.05 + uv.x * resolution.x * 3.14159)));
        float gb = smoothstep(0.85, 0.95, abs(sin(2.1 + uv.x * resolution.x * 3.14159)));

        r = mix(r, r * gr, grille_opacity);
        g = mix(g, g * gg, grille_opacity);
        b = mix(b, b * gb, grille_opacity);
    }

    text.rgb = clamp(vec3(r, g, b) * brightness, 0.0, 1.0);

    if (scanlines_opacity > 0.0){
        float s = smoothstep(scanlines_width, scanlines_width + 0.5,
            abs(sin(uv.y * resolution.y * 3.14159)));
        text.rgb = mix(text.rgb, text.rgb * vec3(s), scanlines_opacity);
    }

    text.rgb *= border(uv);
    text.rgb *= vignette(uv);

    if (clip_warp){
        text.a = border(uv);
    }

    COLOR = text;
}