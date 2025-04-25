//
//  TextEffects.fsh
//  anim-editor
//
//  Created by José Puma on 25-04-25.
//

precision highp float;

varying vec2 v_tex_coord;
uniform sampler2D u_texture;
uniform vec4 u_textColor;

// Efectos
uniform float u_hasShadow;
uniform vec4 u_shadowColor;
uniform vec2 u_shadowOffset;
uniform float u_shadowBlur;

uniform float u_hasStroke;
uniform vec4 u_strokeColor;
uniform float u_strokeWidth;

uniform float u_hasGlow;
uniform vec4 u_glowColor;
uniform float u_glowRadius;


// Función para aplicar blur gaussiano (aproximado)
vec4 gaussianBlur(sampler2D tex, vec2 uv, float radius) {
    vec4 color = vec4(0.0);
    float totalWeight = 0.0;
    float offset = 1.0 / 300.0; // Ajustar según sea necesario

    for (float i = -radius; i <= radius; i++) {
        float weight = exp(-0.5 * (i / radius) * (i / radius));
        color += texture2D(tex, uv + vec2(i * offset, 0.0)) * weight;
        color += texture2D(tex, uv + vec2(0.0, i * offset)) * weight;
        totalWeight += 2.0 * weight;
    }
    return color / totalWeight;
}

void main() {
    vec4 finalColor = texture2D(u_texture, v_tex_coord) * u_textColor;

    if (finalColor.a == 0.0) {
        gl_FragColor = vec4(0.0,0.0,0.0,0.0);
        return;
    }

    // Sombra
    if (u_hasShadow > 0.5) {
        vec4 shadowColor = u_shadowColor;
        vec2 shadowUV = v_tex_coord - u_shadowOffset;
        vec4 shadow = texture2D(u_texture, shadowUV) * shadowColor;
        if (u_shadowBlur > 0.0) {
            shadow = gaussianBlur(u_texture, shadowUV, u_shadowBlur) * shadowColor;
        }
        finalColor = mix(finalColor, shadow, shadowColor.a); // Mezclar sombra
    }

    // Borde
   if (u_hasStroke > 0.5) {
        float alpha = texture2D(u_texture, v_tex_coord).a;
        if (alpha > 0.0 && (
            texture2D(u_texture, v_tex_coord + vec2(u_strokeWidth/300.0, 0.0)).a == 0.0 ||
            texture2D(u_texture, v_tex_coord - vec2(u_strokeWidth/300.0, 0.0)).a == 0.0 ||
            texture2D(u_texture, v_tex_coord + vec2(0.0, u_strokeWidth/300.0)).a == 0.0 ||
            texture2D(u_texture, v_tex_coord - vec2(0.0, u_strokeWidth/300.0)).a == 0.0))
           {
            finalColor = u_strokeColor;
           }
    }

    // Glow
    if (u_hasGlow > 0.5) {
        vec4 glow = gaussianBlur(u_texture, v_tex_coord, u_glowRadius) * u_glowColor;
        finalColor = max(finalColor, glow); // Mezclar brillo
    }

    gl_FragColor = finalColor;
}
