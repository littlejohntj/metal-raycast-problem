If you look in MetalRaycast.swift file you should see the setUpAccelerationStructure function. In here we set up two BoundingBoxes. Then in ComputeRaycast.metal we do the raycast. If there is not intersection found, it should put -1 in the output buffer, else it should put the distance. Right now all i'm getting is -1 so i'm not able to get a successful raycast intersection. 
