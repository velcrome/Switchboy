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
		IDiffSpread<ISpread<Vector3D>> FVerticesInput;

		[Input("Indices")]
		IDiffSpread<ISpread<int>> FIndicesInput;

		[Input("Transform")]
		IDiffSpread<Matrix4x4> FTransform;

		[Input("WallBelongsToBeamer")]
		IDiffSpread<int> FWallBelongsToBeamerID;

		[Input("UseBeamer")]
		IDiffSpread<int> FUseBeamerID;

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
			
			if (FVerticesInput.IsChanged || FIndicesInput.IsChanged || FTransform.IsChanged || FWallBelongsToBeamerID.IsChanged || FUseBeamerID.IsChanged) {
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
				FBeamerID.SliceCount = 0;
				
				for (int i = 0;  i < FUseBeamerID.SliceCount; i++) {
					int key = FUseBeamerID[i];
					
					if (vertex.ContainsKey(key)) { 
						int slicecountIndices = 0;
						int slicecountVertices = 0;
						for (int j = 0;j<vertex[key].Count;j++) {
							slicecountVertices += vertex[key][j].SliceCount;
							slicecountIndices += index[key][j].SliceCount;
						}
					
						FVerticesOutput[i].SliceCount = slicecountVertices;
						FIndicesOutput[i].SliceCount = slicecountIndices;
					
						slicecountIndices = 0;
						slicecountVertices = 0;
					
						for (int j = 0;j<vertex[key].Count;j++) {
							for (int v = 0;v<vertex[key][j].SliceCount;v++) {
								FVerticesOutput[i][v+slicecountVertices] = transform[key][j] * vertex[key][j][v];
							}				
							for (int v = 0;v<index[key][j].SliceCount;v++) {
								FIndicesOutput[i][v+slicecountIndices] = index[key][j][v]+slicecountVertices;
							}				
								
							slicecountVertices += vertex[key][j].SliceCount;
							slicecountIndices += index[key][j].SliceCount;
						}
					
						FBeamerID.Add(key);
					}				
				}
			}
		}
	}
}
