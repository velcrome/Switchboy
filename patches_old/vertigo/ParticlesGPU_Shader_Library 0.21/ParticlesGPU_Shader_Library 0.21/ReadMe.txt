Natan Sinigaglia | dottore


This Shader Library comes from a research i did in these 2 years on possibilities offered by GPU.

This text file is temporary, i'm thinking to write a good PDF to explain better all the functions and the algorithms..

=========================================================================

Change Log:

-version 0.21   10/01/11

        changed 1 behaviour:
	-ParticlesGPU_3d_Bicubic_Surface: -added Alpha
					  -transform now works on geometry
					  -added texture support
	-ParticlesGPU_3d_Queue_Surface: -added Alpha
					-transform now works on geometry
					-added texture support

-version 0.2   ...Merry Christmas and happy 2011! :)

	changed 1 behaviour:
	-ParticlesGPU_2d_Dynamic (new emitting approach, better perf)

	added 6 Behaviours:
	-ParticlesGPU_2d_Dynamic_FieldTexture
	-ParticlesGPU_3d_Dynamic_PosCycle
	-ParticlesGPU_3d_Dynamic_PosVelCycle
	-ParticlesGPU_3d_Dynamic_FieldTexture
	-ParticlesGPU_3d_Queue_Surface
	-ParticlesGPU_3d_Bicubic_Surface


-version 0.15  22/11/10

	added 3 behaviours:
	-ParticlesGPU_2d_Queue
	-ParticlesGPU_2d_Verlet
	-ParticlesGPU_3d_Transform


-version 0.1   09/11/10

	behaviours:
	-ParticlesGPU_2d_Static
	-ParticlesGPU_2d_Static Allocation
	-ParticlesGPU_2d_Dynamic
	-ParticlesGPU_3d_Static
	-ParticlesGPU_3d_Static Allocator

========================================================================

I have to thanks:

-Michael Mehling, who teached me many hlsl indispensable functions (holy tex2Dlod) while we were at Node08.

-Viktor Vicsek, who let me discover GPU Sprites function.

-Tonfilm, for many usefull HLSL transform functions taken from his ShaderTransform and for his Bicubic resample shader.