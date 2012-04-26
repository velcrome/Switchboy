#region usings
using System;
using System.ComponentModel.Composition;
using System.Collections.Generic;
using System.Text.RegularExpressions;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
#endregion usings

namespace VVVV.Nodes
{
	public enum TypeEnum
	{
		Value,
		Color,
		Transform
	}
	
	
	abstract public class MessageNode : IPluginEvaluate {
		public static Dictionary<string, ISpread<string>> DictionaryName = new Dictionary<string, ISpread<string>>();
		public static Dictionary<string, ISpread<int>> DictionaryBinSize = new Dictionary<string, ISpread<int>>();
		public static Dictionary<string, ISpread<TypeEnum>> DictionaryType = new Dictionary<string, ISpread<TypeEnum>>();
		public static MessageNode Changed = null;	

		abstract public void Evaluate(int SpreadMax);

		[Import()]
		protected ILogger FLogger;

		[Import()]
		protected IPluginHost FHost;
		
		
	}

	
	#region PluginInfo
	[PluginInfo(Name = "MessageConfig", Category = "Value", Help = "Basic template with one value in/out", Tags = "", AutoEvaluate = true)]
	#endregion PluginInfo
	public class MessageConfigNode : MessageNode, IPluginEvaluate
	{
		#region fields & pins
		[Input("MessageID", DefaultString = "Bundle")] 
		IDiffSpread<string> FID;

		[Input("Identifier", DefaultString = "Pin")]
		IDiffSpread<ISpread<string>> FName;

		[Input("Vector Size", DefaultValue = 1.0)]
		IDiffSpread<int> FBinSize;

		[Input("Type")]
		IDiffSpread<TypeEnum> FType;

		[Input("Add", DefaultValue = 0.0, Visibility = PinVisibility.Hidden, IsBang = true, IsSingle=true)]
		ISpread<bool> FAdd;

		[Input("Reset", DefaultValue = 0.0, Visibility = PinVisibility.Hidden, IsBang = true, IsSingle = true)]
		ISpread<bool> FReset;

		[Output("RegisteredEvents")]
		ISpread<string> FRegisteredEvents;

		#endregion fields & pins

		public MessageNode Add()
		{
			Changed = this;
			
			int offset = 0;
			
			for (int i=0;i<FID.SliceCount;i++) {
				int count = FName[i].SliceCount;
				string id = FID[i]; 
				

				if (DictionaryName.ContainsKey(id)) {
					FLogger.Log(LogType.Debug, id  + " already present, has been updated.");
					DictionaryName[id] = (ISpread<string>)FName[i].Clone();
					DictionaryBinSize[id] = (ISpread<int>)FBinSize.GetRange<int>(offset, count).Clone();
					DictionaryType[id] = (ISpread<TypeEnum>)FType.GetRange<TypeEnum>(offset, count).Clone();
				}
				else {
					FLogger.Log(LogType.Debug, id  + " added.");
					DictionaryName.Add(id, (ISpread<string>)FName[i].Clone());
					DictionaryBinSize.Add(id, (ISpread<int>)FBinSize.GetRange<int>(offset, count).Clone());
					DictionaryType.Add(id, (ISpread<TypeEnum>)FType.GetRange<TypeEnum>(offset, count).Clone());
				}
			
				offset += count;
			}
			
			return this;
		}

		public void Reset() {
			FLogger.Log(LogType.Debug, "Reset");

			DictionaryName.Clear();
			DictionaryBinSize.Clear();
			DictionaryType.Clear();
		}
		
		override public void Evaluate(int SpreadMax)
		{
			if (FReset[0]) Reset();
			
			if (FBinSize.IsChanged || FAdd[0]) {
				Changed = Add();
			} else if (MessageNode.Changed == this) MessageNode.Changed = null;
			
			FRegisteredEvents.AssignFrom(DictionaryName.Keys);
		}
	}

	#region PluginInfo
	[PluginInfo(Name = "MessageSender", Category = "Value", Help = "Basic template with one value in/out", Tags = "", AutoEvaluate=true)]
	#endregion PluginInfo
	public class MessageSenderNode : MessageNode, IPluginEvaluate
	{
		#region fields & pins
		[Input("MessageID", DefaultString = "Bundle", IsSingle=true)] 
		IDiffSpread<string> FID;

		[Input("Save", DefaultValue = 0.0, Visibility = PinVisibility.Hidden, IsBang = true)]
		ISpread<bool> FSave;
		
		// ConfigPins to save necessary Data for a patch reload
		IDiffSpread<string> FCName;
		IDiffSpread<int> FCBinSize;
		IDiffSpread<TypeEnum> FCType;
		
		[Output("Initialized", Visibility = PinVisibility.Hidden)]
		ISpread<bool> FInitialized;
		
		[Output("Data")]
		ISpread<double> FData;
		
		Dictionary<String, IPluginIn> pins = new Dictionary<String, IPluginIn>();
		Dictionary<String, int> cBinSize = new Dictionary<String, int>();
		Dictionary<String, TypeEnum> cType = new Dictionary<String, TypeEnum>();

		bool initialized = false;
		bool freshInit = true;
		
		#endregion fields & pins
		
		[ImportingConstructor]
		public MessageSenderNode([Config("ConfigName")] IDiffSpread<string> configName, [Config("ConfigBinSize")] IDiffSpread<int> configBinSize, [ConfigAttribute("ConfigType")] IDiffSpread<TypeEnum> configType) {
			FCName = configName;
			FCBinSize = configBinSize;
			FCType = configType;
			
			FCName.Changed += ChangeHandler;
			FCBinSize.Changed += ChangeHandler;
			FCType.Changed += ChangeHandler;
		}
		
		public void ChangeHandler(IDiffSpread s) {
			Create();
		}
		
		
		public void Save() {
			ISpread<int> FBinSize = DictionaryBinSize[FID[0]];
			ISpread<string> FName = DictionaryName[FID[0]];
			ISpread<TypeEnum> FType = DictionaryType[FID[0]];
			
			FCName.SliceCount = FCType.SliceCount = FCBinSize.SliceCount = FBinSize.SliceCount;
			for (int i=0;i<FBinSize.SliceCount;i++) {
				FCBinSize[i] = FBinSize[i];
				FCType[i] = FType[i];
				FCName[i] = FName[i];
			}
			
		}
		

		public void Create() { 
			Dictionary<String, IPluginIn> newPins = new Dictionary<String, IPluginIn>();
			
			
			for (int i=0;i<FCBinSize.SliceCount;i++) {
				string key = FCName[i];
				TypeEnum type = FCType[i];
				int size = FCBinSize[i];

				if (type == TypeEnum.Color) size *= 4;
				if (type == TypeEnum.Transform) size *= 16;
				
//				FLogger.Log(LogType.Debug, key + " -> Type: " + type.ToString() + " -> " + size.ToString() + " doubles");
				bool doNew = false;
				
				if (pins.ContainsKey(key)) {
					if (cType[key] != type) {
						IPluginIn pin = pins[key];
						FHost.DeletePin(pin);
						cBinSize.Remove(key);
						cType.Remove(key);
						doNew = true;
					} else {
						if ((cBinSize[key] != size)) {
							IPluginIn pin = pins[key];
							newPins.Add(key, pin);
							cBinSize[key] = size;
//							cType[key] = type; // already correct
							newPins[key].Order = i;
						} else {
							newPins.Add(key, pins[key]);
							newPins[key].Order = i;
							
						}
					}					
					pins.Remove(key);
				} else doNew = true;
				
				
				if (doNew){
					IPluginIn pin = null;
					switch (type) {
						case TypeEnum.Value:
							IValueIn valuePin;
							FHost.CreateValueInput(key, 1, new string[] {""}, TSliceMode.Dynamic, TPinVisibility.True, out valuePin);
							pin = valuePin;
							break;
						case TypeEnum.Color:
							IColorIn colorPin;
							FHost.CreateColorInput(key, TSliceMode.Dynamic, TPinVisibility.True, out colorPin);
							pin = colorPin;
							break;
						case TypeEnum.Transform:
							ITransformIn transformPin;
							FHost.CreateTransformInput(key, TSliceMode.Dynamic, TPinVisibility.True, out transformPin);
							pin = transformPin;
							break;
					}
					newPins.Add(key, pin);
					cBinSize.Add(key, size);
					cType.Add(key, type);
					pin.Order = i;
				}
			}
			
			foreach (string key in pins.Keys) {
				FHost.DeletePin(pins[key]);
				cBinSize.Remove(key);
				cType.Remove(key);
				
			}

			initialized = true;
			freshInit = true;
			pins = newPins;
		}
		
		public override void Evaluate(int SpreadMax)
		{
			if (FID.IsChanged) initialized = false;

			if (FSave[0] || MessageNode.Changed != null) {
				Save();
				Create();
			}
			
			freshInit = false;
			FInitialized.SliceCount = 1;
			FInitialized[0] = initialized;
			
			int totalCount = 0;
			foreach (string key in pins.Keys) {
				int count = cBinSize[key];
				totalCount+=count;
			} 
			FData.SliceCount = totalCount;
			totalCount = 0;
			foreach (string key in pins.Keys) {
				int count = cBinSize[key]; // count is the count of values, not binsize of input
				double tmp;

//				FLogger.Log(LogType.Debug, key+" -> "+cType[key].ToString()+" "+totalCount);

				switch (cType[key]) {
					case TypeEnum.Value:
						for (int i=0;i<count;i++) {
							((IValueIn)pins[key]).GetValue(i, out tmp);
							FData[i+totalCount] = tmp;
						}
						break;
					case TypeEnum.Color:
						RGBAColor col;
						
						for (int c=0;c<count/4;c++) {
							((IColorIn)pins[key]).GetColor(c ,out col); 
							FData[c*4+totalCount +0] = col.A;
							FData[c*4+totalCount +1] = col.R;
							FData[c*4+totalCount +2] = col.G;
							FData[c*4+totalCount +3] = col.B;
						}
						break;
					case TypeEnum.Transform:
						Matrix4x4 trans;
						
						for (int m=0;m<count/16;m++) {
							((ITransformIn)pins[key]).GetMatrix(m, out trans);
							for (int i=0;i<16;i++) FData[i+m*16+totalCount] = trans[i];
							
						}
						break;					
				}
				totalCount+=count;
			}
		}
	}

	#region PluginInfo
	[PluginInfo(Name = "MessageReceiver", Category = "Value", Help = "Basic template with one value in/out", Tags = "", AutoEvaluate = true)]
	#endregion PluginInfo

	public class MessageReceiverNode : MessageNode, IPluginEvaluate
	{
		#region fields & pins
		[Input("MessageID", DefaultString = "Bundle", IsSingle=true)] 
		IDiffSpread<string> FID;

		[Input("Data", DefaultValue = 0.0)]
		IDiffSpread<double> FData;

		[Input("Save", DefaultValue = 0.0, Visibility = PinVisibility.Hidden, IsBang = true)]
		ISpread<bool> FSave;

		
		// ConfigPins to save necessary Data for a patch reload
		IDiffSpread<string> FCName;
		IDiffSpread<int> FCBinSize;
		IDiffSpread<TypeEnum> FCType;

		[Output("Initialized", Visibility = PinVisibility.Hidden)]
		ISpread<bool> FInitialized;

		Dictionary<String, IPluginOut> pins = new Dictionary<String, IPluginOut>();
		Dictionary<String, int> cBinSize = new Dictionary<String, int>();
		Dictionary<String, TypeEnum> cType = new Dictionary<String, TypeEnum>();
		bool initialized = false;
		bool freshInit = true;

		#endregion fields & pins

		[ImportingConstructor()]
		public MessageReceiverNode([Config("ConfigName")]IDiffSpread<string> configName,[Config("ConfigBinSize")]IDiffSpread<int> configBinSize, [Config("ConfigType")]IDiffSpread<TypeEnum> configType)
		{
			FCName = configName;
			FCBinSize = configBinSize;
			FCType = configType;

			FCName.Changed += ChangeHandler;
			FCBinSize.Changed += ChangeHandler;
			FCType.Changed += ChangeHandler;
		}

		public void ChangeHandler(IDiffSpread s)
		{
			Create();
		}


		public void Save()
		{
			ISpread<int> FBinSize = DictionaryBinSize[FID[0]];
			ISpread<string> FName = DictionaryName[FID[0]];
			ISpread<TypeEnum> FType = DictionaryType[FID[0]];
			
			FCName.SliceCount = FCType.SliceCount = FCBinSize.SliceCount = FBinSize.SliceCount;
			for (int i=0;i<FBinSize.SliceCount;i++) {
				FCBinSize[i] = FBinSize[i];
				FCType[i] = FType[i];
				FCName[i] = FName[i];
			}
		}

		public void Create() { 
			Dictionary<String, IPluginOut> newPins = new Dictionary<String, IPluginOut>();
			
			
			for (int i=0;i<FCBinSize.SliceCount;i++) {
				string key = FCName[i];
				TypeEnum type = FCType[i];
				int size = FCBinSize[i];

				if (type == TypeEnum.Color) size *= 4;
				if (type == TypeEnum.Transform) size *= 16;
				
//				FLogger.Log(LogType.Debug, key + " -> Type: " + type.ToString() + " -> " + size.ToString() + " doubles");
				

				bool doNew = false;
				
				if (pins.ContainsKey(key)) {
					if (cType[key] != type) {
						IPluginOut pin = pins[key];
						FHost.DeletePin(pin);
						cBinSize.Remove(key);
						cType.Remove(key);
						doNew = true;
					} else {
						if ((cBinSize[key] != size)) {
							IPluginOut pin = pins[key];
							newPins.Add(key, pin);
							cBinSize[key] = size;
//							cType[key] = type; // already correct
							newPins[key].Order = i;
						} else {
							newPins.Add(key, pins[key]);
							newPins[key].Order = i;
							
						}
					}					
					pins.Remove(key);
				} else doNew = true;
				
				
				if (doNew){
					IPluginOut pin = null;
					switch (type) {
						case TypeEnum.Value:
							IValueOut valuePin;
							FHost.CreateValueOutput(key, 1, new string[] {""}, TSliceMode.Dynamic, TPinVisibility.True, out valuePin);
							pin = valuePin;
							break;
						case TypeEnum.Color:
							IColorOut colorPin;
							FHost.CreateColorOutput(key, TSliceMode.Dynamic, TPinVisibility.True, out colorPin);
							pin = colorPin;
							break;
						case TypeEnum.Transform:
							ITransformOut transformPin;
							FHost.CreateTransformOutput(key, TSliceMode.Dynamic, TPinVisibility.True, out transformPin);
							pin = transformPin;
							break;
					}
					newPins.Add(key, pin);
					cBinSize.Add(key, size);
					cType.Add(key, type);
					pin.Order = i;
				}
			}
			
			foreach (string key in pins.Keys) {
				FHost.DeletePin(pins[key]);
				cBinSize.Remove(key);
				cType.Remove(key);
				
			}

			initialized = true;
			freshInit = true;
			pins = newPins;
		}

		override public void Evaluate(int SpreadMax)
		{
			if (FID.IsChanged) initialized = false;
			
			if (MessageNode.Changed != null || FSave[0]) {
				Save();
				Create();
			}

			FInitialized.SliceCount = 1;
			FInitialized[0] = initialized;

			if (!FData.IsChanged && !freshInit) return;
			freshInit = false;

			int totalCount = 0;
			foreach (string key in pins.Keys) {
				int count = cBinSize[key]; // count is the count of values, not binsize of input
				double tmp;

				switch (cType[key]) {
					case TypeEnum.Value:
						pins[key].SliceCount = count;

					for (int i=0;i<count;i++) {
							((IValueOut)pins[key]).SetValue(i, FData[i+totalCount]);
						}
						break;
					
					case TypeEnum.Color:
						pins[key].SliceCount = count/4;
						for (int c=0;c<count/4;c++) {
							RGBAColor col = new RGBAColor();
							col.A = FData[c*4+totalCount +0];
							col.R = FData[c*4+totalCount +1];
							col.G = FData[c*4+totalCount +2];
							col.B = FData[c*4+totalCount +3];
							
							((IColorOut)pins[key]).SetColor(c, col);
						}

						break;

					case TypeEnum.Transform:
						
						pins[key].SliceCount = count/16;
						for (int m=0;m<count/16;m++) {
							Matrix4x4 trans = new Matrix4x4();
							for (int i=0;i<16;i++) {
								trans[i] = FData[i+m*16+totalCount];
							}
							((ITransformOut)pins[key]).SetMatrix(m, trans);
						}
						break;					
				}
				totalCount+=count;

			}
		}
	}
}
