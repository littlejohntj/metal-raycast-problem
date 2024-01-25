//
//  ComputeRaycast.metal
//  MetalRaycastProblem
//
//  Created by Todd Littlejohn on 1/25/24.
//

#include <metal_stdlib>
using namespace metal;
using namespace metal::raytracing;

kernel void compute_raycast( device float* output [[buffer(0)]],
                             acceleration_structure<> as [[buffer(1)]],
                             uint index [[thread_position_in_grid]]) {
    
    intersector<> i;
    
    float3 origin = float3(0, 0, 0);
    float3 direction = float3(1, 0, 0);
    
    ray r(origin, direction);
    
    intersection_result<> result = i.intersect(r, as);
    
    if (result.type == intersection_type::none) {
        output[index] = -1.0;
    } else {
        float distance = result.distance;
        output[index] = distance;
    }
    

}

