# Ocean Features

## Animated Waves

The Animated Waves simulation contains the animated surface shape. This typically contains the ocean waves, but can be modified as required. For example parts of the water can be pushed down below geometry if required.

The animated waves sim can be configured by assigning an Animated Waves Sim Settings asset to the OceanRenderer script in your scene (*Create/Crest/Animated Wave Sim Settings*). The waves will be dampened/attenuated in shallow water if a *Sea Floor Depth* LOD data is used (see below). The amount that waves are attenuated is configurable using the *Attenuation In Shallows* setting.

Crest supports adding custom shape to the water surface. To add some shape, add some geometry into the world which when rendered from a top down perspective will draw the desired displacements. Then assign the *RegisterAnimWavesInput* script which will tag it for rendering into the shape, and apply a material with a shader of type *Crest/Inputs/Animated Waves/...*. This is demonstrated in this tutorial video: https://www.youtube.com/watch?v=sQIakAjSq4Y.

There is an example in the *boat.unity* scene, gameobject *wp0*, where a smoothstep bump is added to the water shape. This is an efficient way to generate dynamic shape. This renders with additive blend, but other blending modes are possible such as alpha blend, multiplicative blending, and min or max blending, which give powerful control over the shape.


## Dynamic Waves

This LOD data is a multi-resolution dynamic wave simulation, which gives dynamic interaction with the water. To turn on this feature, enable the *Create Dynamic Wave Sim* option on the *OceanRenderer* script.

One use case for this is boat wakes. In the *boat.unity* scene, the geometry and shader on the *WaterObjectInteractionSphere0* will render forces into the sim. It has the *RegisterDynWavesInput* script that tags it as input.

After the simulation is advanced, the results are converted into displacements and copied into the displacement textures to affect the final ocean shape. The sim is added on top of the existing Gerstner waves.

Crest supports adding forces into the sim to perturb the waves. To add a force, add some geometry into the world which when rendered from a top down perspective will draw the desired forces. Then assign the *RegisterDynamicWavesInput* script which will tag it for rendering into the shape, and apply a material with a shader of type *Crest/Inputs/Dynamic Waves/...*. The process for adding inputs is demonstrated in this tutorial video: https://www.youtube.com/watch?v=sQIakAjSq4Y.

An example can be found in the boat prefab. Each LOD sim runs independently and it is desirable to add interaction forces into all appropriate sims. The *ObjectWaterInteraction* script takes into account the boat size and counts how many sims are appropriate, and then weights the interaction forces based on this number, so the force is spread evenly to all sims. As noted above, the sim results will be copied into the dynamic waves LODs and then accumulated up the LOD chain to reconstruct a single simulation.

The dynamic waves sim can be configured by assigning a Dynamic Wave Sim Settings asset to the OceanRenderer script in your scene (*Create/Crest/Dynamic Wave Sim Settings*).

## Simulation setup

This is the recommended workflow for configuring the dynamic wave simulation. All of the settings below refer to the *Dynamic Wave Sim Settings*.

1. Set the *Gravity Multiplier* to the lowest value that is satisfactory. Higher values will make the simulated waves travel faster, but make the simulation more unstable and require more update steps / expense.
2. Increase *Damping* as high as possible. Higher values make the sim easier to solve, but makes the waves fade faster and limits their range.
3. Set the *Courant Number* to the highest value which still yields a stable sim. Higher values reduce cost but reduce stability. Put the camera low down near the water while testing as the most detailed waves are the most unstable.
4. Reduce *Max Sim Steps Per Frame* as much as possible to reduce the simulation cost. This may slow down waves in the lower LOD levels, which are the most detailed waves. Hopefully this slight slow down in just the smallest wavelengths is not noticeable/objectionable for the player. If waves are visible travelling too slow, increase it.

The *OceanDebugGUI* script gives the debug overlay in the example content scenes and reports the number of sim steps taken and sim step dt at each frame.

## Foam

The Foam LOD Data is simple type of simulation for foam on the surface. Foam is generated by choppy water (specifically when the surface is *pinched*). Each frame, the foam values are reduced to model gradual dissipation of foam over time.

To turn on this feature, enable the *Create Foam Sim* option on the *OceanRenderer* script, and ensure the *Enable* option is ticked in the *Foam* group on the ocean material.

Crest supports inputing any foam into the system. To add some shape, add some geometry into the world which when rendered from a top down perspective will generate the desired foam values. Then assign the *RegisterFoamInput* script which will tag it for rendering into the shape, and apply a material with a shader of type *Crest/Inputs/Foam/...*. The process for adding inputs is demonstrated in this tutorial video: https://www.youtube.com/watch?v=sQIakAjSq4Y.

Foam can be masked by using the *FoamOverride* material.

The foam sim can be configured by assigning a Foam Sim Settings asset to the OceanRenderer script in your scene (*Create/Crest/Foam Sim Settings*). There are also parameters on the material which control the appearance of the foam.

## Sea Floor Depth

This LOD data provides a sense of water depth. More information about how this is used is in the **Shorelines and shallow water** section below.

## Clip Surface

This data drives clipping of the ocean surface, as in carving out holes. This can be useful for hollow vessels or low terrain that goes below sea level. Data can come from geometry, convex hulls or a texture. The system can also be configured to clip everything by default and include only where needed which is useful if water is only required in limited area(s), and this use case is described below.

To turn on this feature, enable the *Create Clip Surface Data* option on the *OceanRenderer* script, and ensure the *Enable* option is ticked in the *Clip Surface* group on the ocean material.

The data contains 0-1 values. Holes are carved into the surface when the values is greater than 0.5.

Overlapping meshes will not work correctly in all cases. There will be cases where one mesh will overwrite another resulting in ocean surface appearing where it should not. Overlapping boxes aligned on the axes will work well whilst spheres may have issues.

Clip areas can be added by adding geometry that covers the desired hole area to the scene and then assigning the *RegisterClipSurfaceInput* script. See the *FloatingOpenContainer* object in the *boat.unity* scene for an example usage.

To use other available shaders like *ClipSurfaceRemoveArea* or *ClipSurfaceRemoveAreaTexture*: create a material, assign to renderer and disable *Assign Clip Surface Material* option. For the *ClipSurfaceRemoveArea* shaders, the geometry should be added from a top down perspective and the faces pointing upwards.

The system can be configured to clip everything by default and include water only where needed, which is useful if water is only required in limited area(s). This is configured by the *Default Clipping State* setting on the *OceanRenderer* component. It can be set to *Everything Clipped* and then a clipping input with shader type *Crest/Inputs/Clip Surface/Include Area* will include areas of water.

As a final feature, the *Clip Below Terrain* toggle on the ocean material will clip the surface underneath the land. Note that this works purely from a depth cache and does not required the *Create Clip Surface Data* option enabled on the *OceanRenderer* component and is therefore more efficient.

## Shadow

To enable shadowing of the ocean surface, data is captured from the shadow maps Unity renders. These shadow maps are always rendered in front of the viewer. The Shadow LOD Data then reads these shadow maps and copies shadow information into its LOD textures.

To turn on this feature, enable the *Create Shadow Data* option on the *OceanRenderer* script, and ensure the *Shadowing* option is ticked on the ocean material.

It stores two channels - one channel is normal shadowing, and the other jitters the lookup and accumulates across many frames to blur and soften the shadow data. The latter channel is used to affect scattered light within the water volume.

The shadow sim can be configured by assigning a Shadow Sim Settings asset to the OceanRenderer script in your scene (*Create/Crest/Shadow Sim Settings*). In particular, the soft shadows are very soft by default, and may not appear for small/thin shadow casters. This can be configured using the *Jitter Diameter Soft* setting.

There will be times when the shadow jitter settings will cause shadows or light to leak. An example of this is when trying to create a dark room during daylight. At the edges of the room the jittering will cause the ocean on the inside of the room (shadowed) to sample outside of the room (not shadowed) resulting in light at the edges. Reducing the *Jitter Diameter Soft* can solve this, but we have also provided a *Register Shadow Input* component which can override shadow data. This component bypasses jittering and gives you full control.

Currently in the built-in render pipeline, shadows only work when the primary camera is set to Forward rendering.

## Flow

Flow is the horizontal motion of the water volumes. It is used in the *whirlpool.unity* scene to rotate the waves and foam around the vortex. It does not affect wave directions, but transports the waves horizontally. This horizontal motion also affects physics.

To turn on this feature, enable the *Create Flow Sim* option on the *OceanRenderer* script, and ensure the *Flow* option is ticked on the ocean material.

Crest supports adding any flow velocities to the system. To add flow, add some geometry into the world which when rendered from a top down perspective will draw the desired displacements. Then assign the *RegisterFlowInput* script which will tag it for rendering into the flow, and apply a material with a shader of type *Crest/Inputs/Flow/...*. The *Crest/Inputs/Flow/Add Flow Map* shader writes a flow texture into the system. It assumes the x component of the flow velocity is packed into 0-1 range in the red channel, and the z component of the velocity is packed into 0-1 range in the green channel. The shader reads the values, subtracts 0.5, and multiplies them by the provided scale value on the shader. The process of adding ocean inputs is demonstrated in the following video: https://www.youtube.com/watch?v=sQIakAjSq4Y.