#region usings
using System;
using System.ComponentModel.Composition;
using System.Collections.Generic;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
#endregion usings

namespace VVVV.Nodes
{
	#region PluginInfo
	[PluginInfo(Name = "MeshBeamerCombination", Category = "Transform", Help = "Basic template with one transform in/out", Tags = "matrix")]
	#endregion PluginInfo
	public class TransformMeshBeamerCombinationNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Vertices")]
		ISpread<ISpread<Vector3D>> FVerticesInput;

		[Input("Indices")]
		ISpread<ISpread<int>> FIndicesInput;

		[Input("Transform")]
		ISpread<Matrix4x4> FTransform;

		[Input("WallBelongsToBeamer")]
		ISpread<int> FWallBelongsToBeamerID;

		[Input("UseBeamer")]
		ISpread<int> FUseBeamerID;

		[Input("Reset")]
		ISpread<bool> FReset;
		
		[Output("Vertices")]
		ISpread<ISpread<Vector3D>> FVerticesOutput;

		[Output("Indices")]
		ISpread<ISpread<int>> FIndicesOutput;
		
		[Output("BeamerID")]
		ISpread<int> FBeamerID;

		
		[Import()]
		ILogger FLogger;
		#endregion fields & pins

		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			
			if (FReset[0]) {
				SortedDictionary<int, List<ISpread<Vector3D>>> vertex = new  SortedDictionary<int, List<ISpread<Vector3D>>>();				
				Dictionary<int, List<ISpread<int>>> index = new  Dictionary<int, List<ISpread<int>>>();				
				Dictionary<int, List<Matrix4x4>> transform = new  Dictionary<int, List<Matrix4x4>>();				

				int max = Math.Max(Math.Max(Math.Max(FWallBelongsToBeamerID.SliceCount, FVerticesInput.SliceCount), FIndicesInput.SliceCount), FTransform.SliceCount);
				
				for (int i=0;i<max;i++) {
				
					try {
						if (vertex[FWallBelongsToBeamerID[i]].Count == 0) {};
					}
					catch (Exception e) {
						vertex[FWallBelongsToBeamerID[i]] = new List<ISpread<Vector3D>>();
						index[FWallBelongsToBeamerID[i]] = new List<ISpread<int>>();
						transform[FWallBelongsToBeamerID[i]] = new List<Matrix4x4>();
					}
				
						
					vertex[FWallBelongsToBeamerID[i]].Add(FVerticesInput[i]);
					index[FWallBelongsToBeamerID[i]].Add(FIndicesInput[i]);
					transform[FWallBelongsToBeamerID[i]].Add(FTransform[i]);
			
				}

				int[] keys = new int[vertex.Keys.Count];
				vertex.Keys.CopyTo(keys, 0);
				
			
				int count = 0;
				for (int i=0;i<keys.Length;i++) {
					bool contained = false;
					for (int j=0; j<FUseBeamerID.SliceCount;j++) {
						if (keys[i] == FUseBeamerID[j]) {
							contained = true;
						}						
					}
					if (contained) count++;
				}
				
				FVerticesOutput.SliceCount = count;
				FIndicesOutput.SliceCount = count;
				FBeamerID.SliceCount = count;
				
				int counter = 0;
			
				for (int i = 0; i < keys.Length; i++) {
					
					bool contained = false;
					for (int j=0; j<FUseBeamerID.SliceCount;j++) {
						if (keys[i] == FUseBeamerID[j]) contained = true;	
					}
					
					if (contained) {					
						int slicecountIndices = 0;
						int slicecountVertices = 0;
						for (int j = 0;j<vertex[keys[i]].Count;j++) {
							slicecountVertices += vertex[keys[i]][j].SliceCount;
							slicecountIndices += index[keys[i]][j].SliceCount;
						}
						FVerticesOutput[counter].SliceCount = slicecountVertices;
						FIndicesOutput[counter].SliceCount = slicecountIndices;
					
						slicecountIndices = 0;
						slicecountVertices = 0;
						for (int j = 0;j<vertex[keys[i]].Count;j++) {
							for (int v = 0;v<vertex[keys[i]][j].SliceCount;v++) {
								FVerticesOutput[counter][v+slicecountVertices] = transform[keys[i]][j] * vertex[keys[i]][j][v];
							}				

							for (int v = 0;v<index[keys[i]][j].SliceCount;v++) {
								FIndicesOutput[counter][v+slicecountIndices] = index[keys[i]][j][v]+slicecountVertices;
							}				
							
							slicecountVertices += vertex[keys[i]][j].SliceCount;
							slicecountIndices += index[keys[i]][j].SliceCount;
						}
						FBeamerID[counter] = keys[i];
						counter++;
	
						
					}
				}
			}
		}
	}
}
