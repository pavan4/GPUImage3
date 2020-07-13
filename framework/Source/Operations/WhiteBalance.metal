#include <metal_stdlib>
#include "OperationShaderTypes.h"
using namespace metal;

constant half3 warmFilter = half3(0.93, 0.54, 0.0);

typedef struct
{
    float temperature;
    float tint;
    float3x3 RGBtoYIQ;
    float3x3 YIQtoRGB;
} WhiteBalanceUniform;

fragment half4 whiteBalanceFragmentShader(SingleInputVertexIO fragmentInput [[stage_in]],
                                  texture2d<half> inputTexture [[texture(0)]],
                                  constant WhiteBalanceUniform& uniform [[ buffer(1) ]])
{
    constexpr sampler quadSampler;
    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    
    half3 yiq = half3x3(uniform.RGBtoYIQ) * color.rgb; //adjusting tint
    yiq.b = clamp(yiq.b + uniform.tint*0.5226*0.1, -0.5226, 0.5226);
    half3 rgb = half3x3(uniform.YIQtoRGB) * yiq;
    
    half3 processed = half3(
                          (rgb.r < 0.5 ? (2.0 * rgb.r * warmFilter.r) : (1.0 - 2.0 * (1.0 - rgb.r) * (1.0 - warmFilter.r))), //adjusting temperature
                          (rgb.g < 0.5 ? (2.0 * rgb.g * warmFilter.g) : (1.0 - 2.0 * (1.0 - rgb.g) * (1.0 - warmFilter.g))),
                          (rgb.b < 0.5 ? (2.0 * rgb.b * warmFilter.b) : (1.0 - 2.0 * (1.0 - rgb.b) * (1.0 - warmFilter.b))));
    
    return half4(mix(rgb, processed, uniform.temperature), color.a);
}
