#region usings
using System;
using System.ComponentModel.Composition;
using System.Runtime.InteropServices;
using System.Collections.Generic;

using SlimDX;
using SlimDX.Direct3D9;
using VVVV.Core.Logging;
using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.PluginInterfaces.V2.EX9;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;
using VVVV.Utils.SlimDX;

#endregion usings

namespace VVVV.Nodes
{
    [StructLayout(LayoutKind.Sequential)]
    public struct VertexNormT2
    {
        public Vector3 pv;
        public Vector3 nv;
        public Vector2 texcd;
 
        public static readonly VertexFormat Format = VertexFormat.Position | VertexFormat.Normal | VertexFormat.Texture1;
        public static readonly int SizeInByte = 8 * sizeof(float);

    }

	#region PluginInfo
	[PluginInfo(Name = "MeshJoin",Author="vux", Category = "EX9.Geometry", Version = "Advanced", Help = "Basic template which creates a mesh", Tags = "")]
	#endregion PluginInfo
	public class MeshJoin : IPluginEvaluate,IDisposable, IPluginDXMesh
	{
		#region fields & pins
		[Input("Vertices")]
		ISpread<ISpread<Vector3>> FVertices;
		
		[Input("Normals")]
		ISpread<ISpread<Vector3>> FNormals;
		
		[Input("Indices")]
		ISpread<ISpread<int>> FIndices;
		
		[Input("Tex Coords")]
		ISpread<ISpread<Vector2>> FTexCoord;
		
		[Input("Apply", IsBang = true,IsSingle=true)]
		ISpread<bool> FApply;
					
		IDXMeshOut FPinOutMesh;
		
		Dictionary<int, Mesh> FMeshes = new Dictionary<int, Mesh>();
		
		bool FInvalidate = false;
		
		List<VertexNormT2[]> FVertexList = new List<VertexNormT2[]>();
        List<short[]> FIndexList = new List<short[]>();
        
        [ImportAttribute()]
        ILogger FLogger;
        

		#endregion fields & pins

		// import host and hand it to base constructor
		[ImportingConstructor()]
		public MeshJoin(IPluginHost host)
		{
			host.CreateMeshOutput("Mesh",TSliceMode.Dynamic,TPinVisibility.True,out this.FPinOutMesh);
		}

		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			if (this.FApply[0])
			{
//				FLogger.Log(LogType.Debug,"Enter");
				int cnt = Math.Max(this.FIndices.SliceCount,this.FVertices.SliceCount);
				cnt = Math.Max(this.FTexCoord.SliceCount,cnt);
				cnt = Math.Max(this.FNormals.SliceCount,cnt);
				
				this.FVertexList.Clear();
				this.FIndexList.Clear();
				
				for (int i = 0; i < cnt; i++)
				{
					short[] indices = new short[this.FIndices[i].SliceCount];
					for (int j = 0; j < this.FIndices[i].SliceCount; j++)
					{
						indices[j] = Convert.ToInt16(this.FIndices[i][j]);
					}
					
					int MaxVert = Math.Max(this.FVertices[i].SliceCount,
						this.FTexCoord[i].SliceCount);
					MaxVert = Math.Max(this.FNormals.SliceCount,MaxVert);
					
					VertexNormT2[] verts = new VertexNormT2[MaxVert];
					for (int j = 0; j < MaxVert;j++)
					{
						VertexNormT2 v = new VertexNormT2();
						v.pv = this.FVertices[i][j];
						v.texcd = this.FTexCoord[i][j];
						v.nv = this.FNormals[i][j];
						verts[j] = v;
					}
					
					this.FIndexList.Add(indices);
					this.FVertexList.Add(verts);
					
//					FLogger.Log(LogType.Debug,"Slice End");
				}
				
				
				this.InvalidateMesh(cnt);
			}
		}
		
		#region IPluginDXMesh Members
        public void GetMesh(IDXMeshOut ForPin, int OnDevice, out int mesh)
        {
        
            mesh = 0;
            //in case the plugin has several mesh outputpins a test for the pin can be made here to get the right mesh.
            if (ForPin == this.FPinOutMesh)
            {
                if (this.FMeshes.ContainsKey(OnDevice))
                {
                	//this.FLogger.Log(LogType.Debug,this.FMeshes[OnDevice].ComPointer.ToInt32().ToString());
                    mesh = this.FMeshes[OnDevice].ComPointer.ToInt32();
                }
            }
        }
        
        public void DestroyResource(IPluginOut ForPin, int OnDevice, bool OnlyUnManaged)
        {
            try
            {
            	
                if (this.FMeshes.ContainsKey(OnDevice))
                {
                    Mesh m = this.FMeshes[OnDevice];
                    this.FMeshes.Remove(OnDevice);
                    m.Dispose();
                }
            }
            catch
            {

            }
        }
        
        private void RemoveResource(int OnDevice)
        {
            if (this.FMeshes.ContainsKey(OnDevice))
            {
	            Mesh m = FMeshes[OnDevice];
	            FMeshes.Remove(OnDevice);
	            m.Dispose();
	        }
        }
        
        public void UpdateResource(IPluginOut ForPin, int OnDevice)
        {
        	
            if (ForPin == this.FPinOutMesh)
            {
            	
            	
                bool update = this.FMeshes.ContainsKey(OnDevice);
                if (this.FInvalidate)
                {
                    RemoveResource(OnDevice);
                }

                if (!update)
                {
                    this.FInvalidate = true;
                }

                if (this.FInvalidate)
                {
                	
                	
                    Device dev = Device.FromPointer(new IntPtr(OnDevice));

                    List<Mesh> meshes = new List<Mesh>();
                    //Mesh.

                    for (int i = 0; i < this.FVertexList.Count; i++)
                    {
						 
                        Mesh mesh = new Mesh(dev, this.FIndexList[i].Length / 3, this.FVertexList[i].Length, MeshFlags.Dynamic, VertexNormT2.Format);
                        DataStream vS = mesh.LockVertexBuffer(LockFlags.Discard);
                        DataStream iS = mesh.LockIndexBuffer(LockFlags.Discard);
                        
//                        FLogger.Log(LogType.Debug,this.FVertexList[i].Length.ToString());
//                        FLogger.Log(LogType.Debug,this.FIndexList[i].Length.ToString());

                        vS.WriteRange(this.FVertexList[i]);
                        iS.WriteRange(this.FIndexList[i]);

                        mesh.UnlockVertexBuffer();
                        mesh.UnlockIndexBuffer();

                        meshes.Add(mesh);
                        
//                        FLogger.Log(LogType.Debug,meshes.Count.ToString());
                    }
                                       	
                    try 
                    {
                    
                    Mesh merge = Mesh.Concatenate(dev, meshes.ToArray(), MeshFlags.Use32Bit | MeshFlags.Managed);
					this.FMeshes.Add(OnDevice, merge);
					//FLogger.Log(LogType.Debug,meshes.Count.ToString());
					}
					catch (Exception ex)
					{
					//FLogger.Log(LogType.Error,ex.Message);
					}
					
					
					
                   
                    foreach (Mesh m in meshes)
                    {
                        m.Dispose();
                    }

                    dev.Dispose();

                    this.FInvalidate = false;
                }
            }
        }

        #endregion
        
        private void InvalidateMesh(int slicecount)
        {
            this.FInvalidate = true;

            this.FPinOutMesh.SliceCount = slicecount;
            this.FPinOutMesh.MarkPinAsChanged();
        }
        
        public void Dispose()
        {
        
        }
	}
}
