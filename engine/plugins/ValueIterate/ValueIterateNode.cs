#region usings
using System;
using System.ComponentModel.Composition;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
#endregion usings

namespace VVVV.Nodes
{
	#region PluginInfo
	[PluginInfo(Name = "Iterate", Category = "Value", Help = "Basic template with one value in/out", Tags = "")]
	#endregion PluginInfo
	public class ValueIterateNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Input", DefaultValue = 1.0)]
		IDiffSpread<double> FInput;

		[Input("Vector Size", DefaultValue = 1.0)]
		IDiffSpread<int> FSize;

		[Input("Frames Interval", DefaultValue = 1.0)]
		IDiffSpread<double> FInterval;

		[Input("Reset", DefaultValue = 0.0)]
		ISpread<bool> FReset;

		[Output("Output")]
		ISpread<double> FOutput;

		[Output("Progress")]
		ISpread<double> FProgress;

		[Import()]
		ILogger FLogger;

		int pointer = 0;
		int interval = 0;
	#endregion fields & pins

		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			SpreadMax = (int)Math.Ceiling((double)FInput.SliceCount / (double)FSize[0])*FSize[0];
			if (FInput.IsChanged || FReset[0] || FSize.IsChanged) {
				pointer = 0;
			}
			
			FOutput.SliceCount = FSize[0];
			
			if (pointer < SpreadMax) {
				for (int i=0;i<FSize[0];i++) {
					FOutput[i] = FInput[pointer + i];
					
				}
				interval++;
				if (interval >= FInterval[0]) {
					pointer+=FSize[0];
					interval = 0;
				}
				FProgress[0] = (double)pointer / (double)FInput.SliceCount;
			} else {
			}
			
			
			//FLogger.Log(LogType.Debug, "hi tty!");
		}
	}
}
