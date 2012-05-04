#region usings
using System;
using System.Collections.Generic;
using System.ComponentModel.Composition;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.Streams;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
#endregion usings

namespace VVVV.Nodes
{
	abstract public class MessageNode  {
		public enum TypeEnum
		{
			Value,
			Color,
			Transform
		}
		public enum StateEnum
		{
			New,
			Clean,
			Dirty,
			Kill
		}
		
		public class PinInfo : ICloneable, IComparable {
			public string Name = "";
			public int Count = 0;
			public TypeEnum Type = TypeEnum.Value;
			
			public StateEnum State = StateEnum.New;
			public int Order = 0;
			
			public static bool operator ==(PinInfo a, PinInfo b)
			{
				// If both are null, or both are same instance, return true.
				if (System.Object.ReferenceEquals(a, b))
				return true;
				
				// If one is null, but not both, return false.
				if (((object)a == null) || ((object)b == null))
				return false;
				
				// Return true if the fields match:
				return (a.Name == b.Name) && (a.Type == b.Type) && (a.Order == b.Order);
			}
			public static bool operator !=(PinInfo a, PinInfo b)
			{
				return !(a == b);
			}
			public Object Clone() {
				PinInfo p = new PinInfo();
				
				p.Type = Type;
				p.Count = Count;
				p.Name = Name;
				p.Order = Order;
				p.State = State;
				
				return p;
			}
			
			public int CompareTo(object obj){
    			if (obj is PinInfo) {
      				return this.Order.CompareTo((obj as PinInfo).Order);  // compare user names
    			}
    			throw new ArgumentException("Object is not a PinInfo");
  			}
		}
		
		public static Dictionary<string, Dictionary<string, PinInfo>> PinDictionary = new Dictionary<string, Dictionary<string,PinInfo>>();
		
		public static MessageNode Changed = null;
		public static MessageNode Updated = null;
		
		public Dictionary<string, PinInfo> CurrentPinInfo = new Dictionary<string, PinInfo>();
		
		[Import()]
		protected ILogger FLogger;
		
		[Import()]
		protected IPluginHost FHost;
		
		[Import()]
		protected IIOFactory FIOFactory;
	}
	
	#region PluginInfo
	[PluginInfo(Name = "MConfig", Category = "Spreads", Version = "DynamicPins", Help = "Fully spreadable Configurator for all M-Nodes", Tags = "", AutoEvaluate = true)]
	#endregion PluginInfo
	public class DynamicPinsSpreadsMConfigNode : MessageNode, IPluginEvaluate
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
		
		private bool Init = false;
		
		#endregion fields & pins
		
		// Called when data for any output pin is requested.
		public MessageNode Add()
		{
			int offset = 0;
			
			for (int i=0;i<FID.SliceCount;i++) {
				int count = FName[i].SliceCount;
				string id = FID[i];
				
				Dictionary<string, PinInfo> dict = new Dictionary<string, PinInfo>();
				for (int j = offset;j<offset+count;j++) {
					PinInfo pin = new PinInfo();
					pin.Name = FName[i][j-offset];
					pin.Count = FBinSize[j];
					pin.Type = FType[j];
					pin.Order = j-offset;
					
					dict.Add(pin.Name, pin);
				}
				PinDictionary[id] = dict;
				offset += count;
			}
			return this;
		}
		
		public MessageNode Update() {
			int offset = 0;
			
			for (int i=0;i<FID.SliceCount;i++) {
				int count = FName[i].SliceCount;
				string id = FID[i];
				for (int j = offset;j<offset+count;j++) {
					string pinName = FName[i][j-offset];
					
					if (PinDictionary.ContainsKey(id) && PinDictionary[id].ContainsKey(pinName)) {
						PinDictionary[id][pinName].Count = FBinSize[j];
						PinDictionary[id][pinName].Order = j-offset;
					}
				}
				offset += count;
			}
			return this;
		}
		
		public void Reset() {
			FLogger.Log(LogType.Debug, "Reset");
			PinDictionary.Clear();
		}
		public void Evaluate(int SpreadMax)
		{
			if (FReset[0]) Reset();
			
			if (MessageNode.Changed == this) MessageNode.Changed = null;
			if (MessageNode.Updated == this) MessageNode.Updated = null;
			
			if (!Init) {
				MessageNode.Changed = Add();
				Init = true;
			}

			
			if (FAdd[0] && (FAdd.IsChanged || FID.IsChanged || FName.IsChanged ||FBinSize.IsChanged || FType.IsChanged)) {
				MessageNode.Changed = Add();
			} else if (FBinSize.IsChanged) {
				MessageNode.Updated = Update();
			}
			
			FRegisteredEvents.AssignFrom(PinDictionary.Keys);
		}
	}
	
	#region PluginInfo
	[PluginInfo(Name = "MSend", Category = "Spreads", Version = "DynamicPins", Help = "Basic template with a dynamic amount of in- and outputs", Tags = "")]
	#endregion PluginInfo
	public class DynamicPinsSpreadsMSendNode : MessageNode, IPluginEvaluate, IPartImportsSatisfiedNotification
	{
		#region fields & pins
		[Input("MessageID", DefaultString = "Bundle", IsSingle=true)]
		IDiffSpread<string> FID;
		
		Spread<IIOContainer> FPins = new Spread<IIOContainer>();
		
		[Input("Save", DefaultValue = 0.0, Visibility = PinVisibility.True, IsBang = true)]
		ISpread<bool> FSave;
		
		[Input("Reset", DefaultValue = 0.0, Visibility = PinVisibility.Hidden, IsBang = true)]
		ISpread<bool> FReset;

		// ConfigPins to save necessary Data for a patch reload
		[Config("Pin Name", DefaultString = "Pin")]
		IDiffSpread<string> FCName;
		
		[Config("VectorSize", DefaultValue = 1.0)]
		IDiffSpread<int> FCBinSize;
		
		[Config("Type")]
		IDiffSpread<TypeEnum> FCType;
		
		[Output("Initialized", Visibility = PinVisibility.Hidden, Order=1337)]
		ISpread<bool> FInitialized;
		
		[Output("Data")]
		ISpread<double> FData;
		
		Dictionary<string, IIOContainer> FIO = new Dictionary<string, IIOContainer>();
		Dictionary<IDiffSpread, bool> FValidIO = new Dictionary<IDiffSpread, bool>();
		
		
		#endregion fields & pins
		public void OnImportsSatisfied()
		{
			FIOFactory.Created += HandlePluginCreated;
			// Add all our config pins to this dictionary
			FValidIO[FCName] = false;
			FValidIO[FCBinSize] = false;
			FValidIO[FCType] = false;
		}
		
		
		private void HandlePluginCreated(object sender, EventArgs args)
		{
			FLogger.Log(LogType.Debug, "HandlePluginCreated()");
			FIOFactory.Created -= HandlePluginCreated;
			// Registering this late we avoid the special case that changed event
			// for config pins gets fired immediatly after the plugin has been created.
			FCName.Changed += HandleStartConfig;
			FCType.Changed += HandleStartConfig;
			FCBinSize.Changed += HandleStartConfig;
		}
		
		private void HandleStartConfig(IDiffSpread sender)
		{
			FValidIO[sender] = true;
			
			bool allConfigPinsReady = true;
			foreach (var key in FValidIO.Keys) {
				if (!FValidIO[key]) allConfigPinsReady = false;
			}
			
			if (allConfigPinsReady) {
				FCName.Changed -= HandleStartConfig;
				FCType.Changed -= HandleStartConfig;
				FCBinSize.Changed -= HandleStartConfig;
				SaveFromConfig();
				Create();
			}
		}
		
		private void HandleChangeConfig(IDiffSpread sender)
		{
//			FLogger.Log(LogType.Debug, "HandleChangeConfig()" + sender.ToString());
			SaveFromConfig();
		}
		
		public void Create() {
			int i = 0;
			foreach (string name in CurrentPinInfo.Keys) {
				switch (CurrentPinInfo[name].State) {
					case StateEnum.Kill:
					if (FIO.ContainsKey(name)) {
						FIO[name].Dispose();
						FIO.Remove(name);
					}
					break;
					
					case StateEnum.Dirty:
					goto case StateEnum.New;
					
					case StateEnum.New:
					
					if (FIO.ContainsKey(name)) {
						FIO[name].Dispose();
						FIO.Remove(name);
					}
					CurrentPinInfo[name].State = StateEnum.Clean;
					
					IOAttribute ioAttribute = new InputAttribute(name);
					ioAttribute.Visibility = PinVisibility.True;
					ioAttribute.Order = CurrentPinInfo[name].Order;
					
//					FLogger.Log(LogType.Debug, "create " + ioAttribute.Order.ToString() + " " + name);
					
					Type ioType;
					switch (CurrentPinInfo[name].Type) {
						case TypeEnum.Color:
						ioType = typeof(IDiffSpread<RGBAColor>);
						break;
						case TypeEnum.Transform:
						ioType = typeof(IDiffSpread<Matrix4x4>);
						break;
						default:
						ioType = typeof(IDiffSpread<double>);
						break;
					}
					
					FIO[name] = FIOFactory.CreateIOContainer(ioType, ioAttribute);
					goto case StateEnum.Clean;
					
					case StateEnum.Clean:
					i++;
					CurrentPinInfo[name].State = StateEnum.Clean;
					break;
				}
			}
			// CleanUp
			string[] keys = new string[CurrentPinInfo.Count];
			CurrentPinInfo.Keys.CopyTo(keys, 0);
			foreach (string name in keys) {
				if (CurrentPinInfo[name].State == StateEnum.Kill) CurrentPinInfo.Remove(name);
					else CurrentPinInfo[name].State = StateEnum.Clean;

			}
		}
		
		public void SaveToConfig() {
			FLogger.Log(LogType.Debug, "SAVE");
			
			FCBinSize.Changed -= HandleChangeConfig;
			FCName.Changed -= HandleChangeConfig;
			FCType.Changed -= HandleChangeConfig;
			
			int sliceCount = 0;
			foreach(string name in CurrentPinInfo.Keys) 
				if (CurrentPinInfo[name].State != StateEnum.Kill) sliceCount++;
			
			FCBinSize.SliceCount = FCName.SliceCount = FCType.SliceCount = sliceCount;
			
			foreach(string name in CurrentPinInfo.Keys) {
				
				if (CurrentPinInfo[name].State != StateEnum.Kill) {
					int order = CurrentPinInfo[name].Order;
					FCBinSize[order] = CurrentPinInfo[name].Count;
					FCName[order] = CurrentPinInfo[name].Name;
					FCType[order] = CurrentPinInfo[name].Type;
				
//					FLogger.Log(LogType.Debug, "save to config " + order.ToString() + " " + name);
					
				}
			}
			
//			FCBinSize.Changed += HandleChangeConfig;
//			FCName.Changed += HandleChangeConfig;
//			FCType.Changed += HandleChangeConfig;
			
		}
		
		public void SaveFromConfig() {
			FLogger.Log(LogType.Debug, "Load from Config");
			
			// all pins are suspect
			foreach(string name in CurrentPinInfo.Keys) {
				CurrentPinInfo[name].State = StateEnum.Kill;
			}
			
			for (int i=0;i<FCName.SliceCount;i++) {
				string name = FCName[i];
				PinInfo p = new PinInfo();
				p.Name = name;
				p.Type = FCType[i];
				p.Count = FCBinSize[i];
				p.Order = i;
				
				if (CurrentPinInfo.ContainsKey(name)) {
					// pin with this name is already present
					if ( p != CurrentPinInfo[name]) {
						// either needs to be updated...
						CurrentPinInfo[name].State = StateEnum.Dirty;
					} else {
						// or kept.
						CurrentPinInfo[name].State = StateEnum.Clean;
					}
				} else {
					// pin with this name is not present
					CurrentPinInfo[name] = p;
					CurrentPinInfo[name].State = StateEnum.New;
				}
			}
		}
		
		
		public void SaveFromStatic()
		{
			FLogger.Log(LogType.Debug, "Load from Static");
			Dictionary<string, PinInfo> pinDict = PinDictionary[FID[0]];
			
			foreach(string name in CurrentPinInfo.Keys) {
				CurrentPinInfo[name].State = StateEnum.Kill;
			}

			foreach(string name in pinDict.Keys) {
				if (CurrentPinInfo.ContainsKey(name)) {
					// pin with this name is already present
					if ( pinDict[name] != CurrentPinInfo[name]) {
						// pin with this name is already present
						CurrentPinInfo[name].State = StateEnum.Dirty;
					} else 	{
						// or kept.
						CurrentPinInfo[name].State = StateEnum.Clean;
					}
				} else {
					// pin with this name is not present
					CurrentPinInfo[name] = (PinInfo)pinDict[name].Clone();
					CurrentPinInfo[name].State = StateEnum.New;
				}
			}
		}
		
		
		public void Evaluate(int SpreadMax)
		{
			if (FReset[0]) {
				CurrentPinInfo.Clear();
				SaveToConfig();
				
				foreach (string pin in FIO.Keys) {
					FIO[pin].Dispose();
				}
				FIO.Clear();				
//				Create();
				
			}
			
			
			if (FSave[0]) {
				if (PinDictionary.ContainsKey(FID[0])) {
					SaveFromStatic();
					SaveToConfig();
					Create();
				}
				else {
					FLogger.Log(LogType.Debug, "No MConfig Scheme with the name "+FID[0]+" detected.");
					Create();
				}
			}
			
			if (MessageNode.Updated != null) {
				if (PinDictionary.ContainsKey(FID[0])) {
					SaveFromStatic();
					SaveToConfig();
				}
			}
			
			
			for (int i=0;i<CurrentPinInfo.Count;i++) {
//				PinInfo[] pins = Array.Sort(CurrentPinInfo.Values);
				
				
			}
			
		}
		
	}
}
