#region usings
using System;
using System.ComponentModel.Composition;
using System.Runtime.InteropServices;
using System.Collections.Generic;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
#endregion usings

namespace VVVV.Nodes
{	
	[StructLayout(LayoutKind.Sequential)]
	public struct MyParticle : ILocatable, IScalable
	{
		public static int MAXID = 0;
		public Vector3D Position {get; set;}
		private Vector3D FLastPosition;
		public Vector3D LastPosition 
		{
			get 
			{
				return FFirstFrame ? Position : FLastPosition;
			}
		}
		public Vector3D LastVelocity {get; set;}
		public Vector3D Scaling {get; set;}
		
		private bool FFirstFrame;
		public List<Vector3D> positionHistory;
		public List<double> widthHistory;
		
		public int Age;
		public double Seed;
		public RGBAColor color;
		public int ID_Number;
		
		public MyParticle Init()
		{
			FFirstFrame = true;
			Scaling = new Vector3D(1, 1, 1);
			LastVelocity = new Vector3D(0, 0, 0);
			Age = 0;
			ID_Number = MAXID;
			MAXID++;
			color = new RGBAColor();
			positionHistory= new List<Vector3D>();
			widthHistory = new List<double>();
			return this;
		}	
		
		public void Step()
		{
			LastVelocity = Position-LastPosition;
			FLastPosition = Position;
			Age++;
			FFirstFrame = false;
		}	
	}
			
	[PluginInfo(Name = "Create", Category = "MyParticle", Version = "", Help = "create my own particles", Tags = "")]
	public class MyParticleCreateNode : IPluginEvaluate
	{
		[Input("Count", IsSingle = true, DefaultValue = 1)]		
		ISpread<int> FCount;
		
		[Input("Seed", DefaultValue = 1)]		
		ISpread<double> FSeed;

		[Input("Age", DefaultValue = 0)]		
		ISpread<int> FAge;		
		
//		[Input("ID", DefaultValue = 0)]
//		ISpread<int> FID;

		[Output("Output")]		ISpread<MyParticle> FOutput;
		
		public void Evaluate(int SpreadMax)
		{
			SpreadMax = FCount[0];
			FOutput.SliceCount = SpreadMax;

			for (int i = 0; i < SpreadMax; i++) {
				MyParticle p = new MyParticle().Init();
				p.Seed = FSeed[i];
				p.Age = FAge[i];
//				p.ID_Number = FID[i];
				FOutput[i] = p;
			}
		}
	}
		
	[PluginInfo(Name = "SetPosition", Category = "MyParticle", Help = "Set new Position", Tags = "")]
	public class MyParticleSetPositionNode : ParticleSetPositionNode<MyParticle>
	{
	}	
	
	[PluginInfo(Name = "SetVelocity", Category = "MyParticle", Help = "Position = LastPosition + Velocity", Tags = "")]
	public class MyParticleSetVelocityNode : ParticleSetVelocityNode<MyParticle>
	{
	}	 
	
	[PluginInfo(Name = "Step", Category = "MyParticle", Help = "Acknowledge one step in the animation. Typically used once per Frame.", Tags = "")]
	public class MyParticleStepNode : ParticleStepNode<MyParticle>
	{
	}	
	  
	[PluginInfo(Name = "SetScaling", Category = "MyParticle", Help = "Set new Scaling", Tags = "")]
	public class MyParticleSetScalingNode : ParticleSetScalingNode<MyParticle>
	{
	}		
	
	[PluginInfo(Name = "Cons", Category = "MyParticle", Help = "", Tags = "")]
	public class MyParticleConsNode : FlatCons<MyParticle>
	{ 
	}	
	
	[PluginInfo(Name = "SetState", Category = "MyParticle", AutoEvaluate = true, Help = "", Tags = "")]
	public class MyParticleSetStateNode : ParticleSetStateNode<MyParticle>
	{
	}	 

	[PluginInfo(Name = "GetState", Category = "MyParticle", Help = "", Tags = "")]
	public class MyParticleGetStateNode : ParticleGetStateNode<MyParticle>
	{
	}
	
	[PluginInfo(Name = "GetAge", Category = "MyParticle", Help = "", Tags = "")]
	public class MyParticleGetAgeNode : IPluginEvaluate
	{
		[Output("Age")]		
		ISpread<int> FAge;
		
		[Input("Input")]		
		ISpread<MyParticle> FInput;
		
		public void Evaluate(int SpreadMax)
		{
			FAge.SliceCount = SpreadMax;

			for (int i = 0; i < SpreadMax; i++)
				FAge[i] = FInput[i].Age;
		}		
		
	}	
	
	[PluginInfo(Name = "GetSeed", Category = "MyParticle", Help = "", Tags = "")]
	public class MyParticleGetSeedNode : IPluginEvaluate
	{
		[Output("Seed")]		
		ISpread<double> FSeed;
		
		[Input("Input")]		
		ISpread<MyParticle> FInput;
		
		public void Evaluate(int SpreadMax)
		{
			FSeed.SliceCount = SpreadMax;

			for (int i = 0; i < SpreadMax; i++)
				FSeed[i] = FInput[i].Seed;
		}		
		
	}	
	
	[PluginInfo(Name = "GetID", Category = "MyParticle", Help = "", Tags = "")]
	public class MyParticleGetIDNode : IPluginEvaluate
	{
		[Output("Particle ID")]		
		ISpread<int> FID;
		
		[Input("Input")]		
		ISpread<MyParticle> FInput;
		
		public void Evaluate(int SpreadMax)
		{
			FID.SliceCount = SpreadMax;

			for (int i = 0; i < SpreadMax; i++)
				FID[i] = FInput[i].ID_Number;
		}		
		
	}
	
	[PluginInfo(Name = "SetColor", Category = "MyParticle", Help = "", Tags = "")]
	public class MyParticleSetColorNode : IPluginEvaluate
	{
		[Input("Input")]		
		ISpread<MyParticle> FInput;

		[Input("Color")]
		ISpread<RGBAColor> FColor;

		[Output("Particle ID")]
		ISpread<MyParticle> FOutput;

		
		
		public void Evaluate(int SpreadMax)
		{
			FOutput.SliceCount = FInput.SliceCount;

			for (int i = 0; i < SpreadMax; i++) {	
				MyParticle p = FInput[i];
				p.color = FColor[i];
				FOutput[i] = p;
			}
			
		}
		
	}
	
	[PluginInfo(Name = "GetColor", Category = "MyParticle", Help = "", Tags = "")]
	public class MyParticleGetColorNode : IPluginEvaluate
	{
		[Input("Input")]		
		ISpread<MyParticle> FInput;

		[Output("Color")]
		ISpread<RGBAColor> FColor;
		
		public void Evaluate(int SpreadMax)
		{
			FColor.SliceCount = FInput.SliceCount;

			for (int i = 0; i < SpreadMax; i++) {	
				MyParticle p = FInput[i];
				FColor[i] = p.color;
			}
			
		}
		
	}	
	[PluginInfo(Name = "History", Category = "MyParticle", Help = "", Tags = "")]
	public class MyParticleHistoryNode : IPluginEvaluate
	{
		[Input("Input")]		
		ISpread<MyParticle> FInput;

		[Input("Width")]
		ISpread<double> FWidthIn;
		
		[Input("Save")]		
		ISpread<bool> FSave;
		
		[Output("Output")]		
		ISpread<MyParticle> FOutput;

		[Output("Position")]
		ISpread<ISpread<Vector3D>> FPosition;
		
		[Output("Width")]
		ISpread<ISpread<double>> FWidthOut;
		
		[Output("Particle ID")]
		ISpread<int> FID;

		public void Evaluate(int SpreadMax)
		{
			SpreadMax = FInput.SliceCount;

			FWidthOut.SliceCount = FID.SliceCount = FOutput.SliceCount = FPosition.SliceCount = SpreadMax;
			
			for (int i = 0; i < SpreadMax; i++) {
				if (FSave[i]) {
					FInput[i].positionHistory.Add(FInput[i].LastPosition);
					FInput[i].widthHistory.Add(FWidthIn[i]);					
				}
				FPosition[i].AssignFrom(FInput[i].positionHistory);
				FWidthOut[i].AssignFrom(FInput[i].widthHistory);
				
				
				FOutput[i] = FInput[i];
				FID[i] = FInput[i].ID_Number;
				
			}
			
			
			
		}		
		
	}		
}
