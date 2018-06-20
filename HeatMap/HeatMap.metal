//
//  HeatMap.metal
//  HeatMap
//
//  Created by Andrew Zimmer on 6/18/18.
//  Copyright © 2018 AndrewZimmer. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>

struct MyNodeBuffer {
    float4x4 modelTransform;
    float4x4 modelViewTransform;
    float4x4 normalTransform;
    float4x4 modelViewProjectionTransform;
};

typedef struct {
    float3 position [[ attribute(SCNVertexSemanticPosition) ]];
    float2 uv [[ attribute(SCNVertexSemanticTexcoord0)]];
} MyVertexInput;

struct SimpleVertex
{
    float4 position [[position]];
    float2 uv [[texcoord0]];
};

half4 ColorForHeat(float heat) {
    float pval = 4.0 * (1.0 - heat) + 0.99;
    float lb = pval - floor (pval);
    int pvalCategory = abs(int(floor(pval)));
    
    switch (pvalCategory) {
        case 0:
            return half4(1.0, 1.0 - lb, 1.0 - lb, heat);
            
        case 1:
            return half4(1.0, lb, 0.0, heat);
            
        case 2:
            return half4(1.0 - lb, 1.0, 0.0, heat);
            
        case 3:
            return half4(0.0, 1.0, lb, heat);
            
        case 4:
            return half4(0.0, 1.0 - lb, 1.0, heat);
            
        case 5:
            return half4(0.0, 0.0, 1.0 - lb, heat);
    }
    
    return half4(1.0, 1.0, 1.0, heat);
}

vertex SimpleVertex heatMapVert(MyVertexInput in [[ stage_in ]],
                             constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                             constant MyNodeBuffer& scn_node [[buffer(1)]])
{
    SimpleVertex vert;
    vert.position = float4(in.position, 1.0);
    vert.uv = in.uv;
    
    return vert;
}

fragment half4 heatMapFrag(SimpleVertex in [[stage_in]],
                           device r8unorm<float> *heatmapTexture [[buffer(0)]])
{
    // This has a rounding error. Fix by using a real texture2D for displaying the heatmap instead of a dang buffer.    
    int x = round(in.uv.x * 375 * 3);
    int y = round(in.uv.y * 812 * 3);
    int index = x + y * 375 * 3;
    
    float value = heatmapTexture[index];
    return ColorForHeat(value);
}


