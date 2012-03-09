#region usings
using System;
using System.Collections.Generic;
using System.Linq;
using System.ComponentModel.Composition;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
#endregion usings

namespace VVVV.Nodes
{
	public interface ILocatable
	{
		Vector3D Position {get; set;}
		Vector3D LastPosition {get;}
		Vector3D LastVelocity {get;}
		void Step();
	}

	public interface IScalable
	{
		Vector3D Scaling {get; set;}
	}
		
	public static class LocatableExtensions
	{
		public static Vector3D GetVelocity(this ILocatable loc)
		{
			return loc.Position - loc.LastPosition;
		}		
	} 
	
	[PluginInfo(Name = "GetPosition", Category = "Particle", Help = "", Tags = "")]
	public class ParticleGetPositionNode : IPluginEvaluate
	{
		[Input("Input")]			ISpread<ILocatable> FInput;

		[Output("Position")]		ISpread<Vector3D> FPosition;
		[Output("Last Position")]	ISpread<Vector3D> FLastPosition;

		public void Evaluate(int SpreadMax)
		{
			SpreadMax = FInput.SliceCount;
			FPosition.SliceCount = SpreadMax;
			FLastPosition.SliceCount = SpreadMax;

			for (int i = 0; i < SpreadMax; i++)
			{
				FPosition[i] = FInput[i].Position;
				FLastPosition[i] = FInput[i].LastPosition;
			}
		}
	} 
		
	[PluginInfo(Name = "GetVelocity", Category = "Particle", Help = "", Tags = "")]
	public class ParticleGetVelocityNode : IPluginEvaluate
	{
		[Input("Input")]			ISpread<ILocatable> FInput;

		[Output("Velocity")]		ISpread<Vector3D> FVelocity;
		[Output("Last Velocity")]	ISpread<Vector3D> FLastVelocity;

		public void Evaluate(int SpreadMax)
		{
			SpreadMax = FInput.SliceCount;
			FVelocity.SliceCount = SpreadMax;
			FLastVelocity.SliceCount = SpreadMax;

			for (int i = 0; i < SpreadMax; i++)
			{
				FVelocity[i] = FInput[i].GetVelocity();
				FLastVelocity[i] = FInput[i].LastVelocity;
			}
		}
	}
		
	[PluginInfo(Name = "GetScaling", Category = "Particle", Help = "", Tags = "")]
	public class ParticleGetScalingNode : IPluginEvaluate
	{
		[Input("Input")]		ISpread<IScalable> FInput;

		[Output("Scaling")]		ISpread<Vector3D> FScaling;

		public void Evaluate(int SpreadMax)
		{
			SpreadMax = FInput.SliceCount;			
			FScaling.SliceCount = SpreadMax;

			for (int i = 0; i < SpreadMax; i++)
				FScaling[i] = FInput[i].Scaling;
		}
	}
	
	public class ParticleSetPositionNode<T> : IPluginEvaluate where T : ILocatable
	{
		[Input("Input")]		ISpread<T> FInput;
		[Input("Position")]		ISpread<Vector3D> FPosition;

		[Output("Output")]		ISpread<T> FOutput;
		[Output("Velocity")]	ISpread<Vector3D> FVelocity;

		public void Evaluate(int SpreadMax)
		{
			SpreadMax = FInput.CombineWith(FPosition);			
			FOutput.SliceCount = SpreadMax;
			FVelocity.SliceCount = SpreadMax;

			for (int i = 0; i < SpreadMax; i++)
			{
				var p = FInput[i];
				
				p.Position = FPosition[i];								
			
				FOutput[i] = p;
				FVelocity[i] = p.GetVelocity();
			}
		}
	}
		
	public class ParticleStepNode<T> : IPluginEvaluate where T : ILocatable
	{
		[Input("Input")]		ISpread<T> FInput;

		[Output("Output")]		ISpread<T> FOutput;

		public void Evaluate(int SpreadMax)
		{
			SpreadMax = FInput.SliceCount;		
			FOutput.SliceCount = SpreadMax;

			for (int i = 0; i < SpreadMax; i++)
			{
				var p = FInput[i];				
				p.Step();			
				FOutput[i] = p;
			}
		}
	}
		
	public class ParticleSetVelocityNode<T> : IPluginEvaluate where T : ILocatable
	{
		[Input("Input")]		ISpread<T> FInput;
		[Input("Velocity")]		ISpread<Vector3D> FVelocity;

		[Output("Output")]		ISpread<T> FOutput;

		public void Evaluate(int SpreadMax)
		{
			SpreadMax = FInput.CombineWith(FVelocity);			
			FOutput.SliceCount = SpreadMax;
			FVelocity.SliceCount = SpreadMax;

			for (int i = 0; i < SpreadMax; i++)
			{
				T p = FInput[i];				
				p.Position = p.LastPosition + FVelocity[i];
				FOutput[i] = p; 
			}
		}
	}
		
	public class ParticleSetScalingNode<T> : IPluginEvaluate where T : IScalable
	{
		[Input("Input")]		ISpread<T> FInput;
		[Input("Scaling")]		ISpread<Vector3D> FScaling;

		[Output("Output")]		ISpread<T> FOutput;

		public void Evaluate(int SpreadMax)
		{
			SpreadMax = FInput.CombineWith(FScaling);			
			FOutput.SliceCount = SpreadMax;

			for (int i = 0; i < SpreadMax; i++)
			{
				var p = FInput[i];				
				p.Scaling = FScaling[i];											
				FOutput[i] = p;
			}
		}
	}
				
	public class ParticleSetStateNode<T> : IPluginEvaluate
	{
		[Input("Channel", IsSingle = true)]		ISpread<string> FChannel;

		[Input("Input")]		ISpread<T> FInput;

		public void Evaluate(int SpreadMax)
		{
			ParticleGetStateNode<T>.State[FChannel[0]] = FInput.ToArray(); 
		}
	}
		
	public class ParticleGetStateNode<T> : IPluginEvaluate
	{
		public static Dictionary<string, T[]> State = new Dictionary<string, T[]>();
		
		[Input("Channel", IsSingle = true)]		ISpread<string> FChannel;

		[Output("Output")]		ISpread<T> FOutput;

		public void Evaluate(int SpreadMax)
		{
			if (State.ContainsKey(FChannel[0]))
			{				
				var myValues = State[FChannel[0]];
				
				SpreadMax = myValues.GetLength(0);
				FOutput.SliceCount = SpreadMax;
	
				for (int i = 0; i < SpreadMax; i++)
					FOutput[i] = myValues[i];
			}						
		}
	}
		
    public class FlatCons<T> : IPluginEvaluate
    {
        [Input("Input", IsPinGroup = true)]
        protected ISpread<ISpread<T>> Input;

        [Output("Output")]
        protected ISpread<T> Output;

        public void Evaluate(int SpreadMax)
        {
            SpreadMax = 0;
            for (var i = 0; i < Input.SliceCount; i++)
                SpreadMax += Input[i].SliceCount;

            Output.SliceCount = SpreadMax;

            int k = 0;
            for (var i = 0; i < Input.SliceCount; i++)
            {
                var input = Input[i];

                for (var j = 0; j < input.SliceCount; j++)
                {
                    Output[k] = input[j];
                    k++;
                }
            }
        }
    }
}
