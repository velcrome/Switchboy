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
	[PluginInfo(Name = "Histogram", Category = "Value", Help = "Basic template with one value in/out", Tags = "")]
	#endregion PluginInfo
	public class ValueHistogramNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Input", DefaultValue = 1.0)]
		ISpread<int> FInput;

		[Input("Minimum BPM", DefaultValue = 100)]
		ISpread<int> FMin;

		[Output("BPM")]
		ISpread<int> FBPMOut;

		[Output("BPMCount")]
		ISpread<int> FBPMCount;
		
		[Import()]
		ILogger FLogger;
		
		Dictionary<int, int> histogram = new Dictionary<int, int>();
		#endregion fields & pins

		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			histogram.Clear();
			
			for (int i = 0; i < SpreadMax; i++) {
				int bpm = FInput[i];
				
				if (bpm <= 0) break;
				
				while (bpm > 2*FMin[0]) bpm /= 2;
				while (bpm < FMin[0]) bpm *= 2;
				
				if ( histogram.ContainsKey(bpm))
					histogram[bpm]++;
					else histogram.Add(bpm, 1);
				
				
			}
			FBPMCount.SliceCount = FBPMOut.SliceCount= histogram.Count;
			
			int index = 0;
			foreach (int k in histogram.Keys) {
				FBPMOut[index] = k;
				FBPMCount[index] = histogram[k];
				index++;
				
			}
			
			
		
			
			//FLogger.Log(LogType.Debug, "hi tty!");
		}
	}
}
