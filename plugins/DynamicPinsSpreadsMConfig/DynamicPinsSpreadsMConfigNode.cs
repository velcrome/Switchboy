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
			
			public int valueSize() {
				int m = 0;
				switch (Type) {
					case TypeEnum.Value: m = 1;
					break;
					case TypeEnum.Color: m = 4;
					break;
					case TypeEnum.Transform: m = 16;
					break;
				}
				return m * Count;
			}
			
			public void Spread2Stream(ISpread spread, ref ISpread<double> stream) {
				
				switch (Type) {
					case TypeEnum.Color:
						for (int i =0;i<Count;i++) {
							RGBAColor c = ((ISpread<RGBAColor>) spread)[i];
							stream.Add(c.A);
							stream.Add(c.R);
							stream.Add(c.G);
							stream.Add(c.B);
						}
					break;
					case TypeEnum.Transform:
						for (int i =0;i<Count;i++) {
							Matrix4x4 m = ((ISpread<Matrix4x4>) spread)[i];
							stream.Add(m.m11);stream.Add(m.m12);stream.Add(m.m13);stream.Add(m.m14);
							stream.Add(m.m21);stream.Add(m.m22);stream.Add(m.m23);stream.Add(m.m24);
							stream.Add(m.m31);stream.Add(m.m32);stream.Add(m.m33);stream.Add(m.m34);
							stream.Add(m.m41);stream.Add(m.m42);stream.Add(m.m43);stream.Add(m.m44);
						}
					break;	
					case TypeEnum.Value:
						for (int i =0;i<Count;i++) {
							double v = ((ISpread<double>)spread)[i];
							stream.Add(v);
							
						}
					break;
				}
			}
			
			public void Stream2Spread(IDiffSpread<double> stream, int offset, ref ISpread spread) {
				int count = valueSize();
				spread.SliceCount = 0;
				switch (Type) {
					case TypeEnum.Color:
						for (int i=offset;i<offset+count;i+=4) {
							RGBAColor c = new RGBAColor();
							c.A = stream[i];
							c.R = stream[i+1];
							c.G = stream[i+2];
							c.B = stream[i+3];
							((ISpread<RGBAColor>)spread).Add(c);
						}
					break;
					case TypeEnum.Transform:
						for (int i=offset;i<offset+count;i+=16) {
							Matrix4x4 m = new Matrix4x4();
							m.m11 = stream[i+ 0];m.m12 = stream[i+ 1];m.m13 = stream[i+ 2];m.m14 = stream[i+ 3];
							m.m21 = stream[i+ 4];m.m22 = stream[i+ 5];m.m23 = stream[i+ 6];m.m24 = stream[i+ 7];
							m.m31 = stream[i+ 8];m.m32 = stream[i+ 9];m.m33 = stream[i+10];m.m34 = stream[i+11];
							m.m41 = stream[i+12];m.m42 = stream[i+13];m.m43 = stream[i+14];m.m44 = stream[i+15];
							((ISpread<Matrix4x4>)spread).Add(m);
						}
					break;	
					case TypeEnum.Value:
						for (int i=offset;i<offset+count;i++) {
							((ISpread<double>)spread).Add(stream[i]);
						}					
					break;
				}
				
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
	
	public class DynamicPinsSpreadsMNode : MessageNode, IPluginEvaluate, IPartImportsSatisfiedNotification
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
		

		protected bool Input;
		
		protected Dictionary<string, IIOContainer> FIO = new Dictionary<string, IIOContainer>();
		protected Dictionary<IDiffSpread, bool> FValidIO = new Dictionary<IDiffSpread, bool>();
		protected Dictionary<IDiffSpread, int> FValidIOCount = new Dictionary<IDiffSpread, int>();
		
		#endregion fields & pins
		public void OnImportsSatisfied()
		{
			FIOFactory.Created += HandlePluginCreated;
			// Add all our config pins to dictionaries
			FValidIO[FCName] = FValidIO[FCBinSize] = FValidIO[FCType] = false;
			FValidIOCount[FCName] = FValidIOCount[FCBinSize] = FValidIOCount[FCType] = 0;
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
//			each slice of each config pin will call back here. must wait till all have arrived
			FValidIOCount[sender]++;
			if (FValidIOCount[sender] == sender.SliceCount)
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
						FLogger.Log(LogType.Debug, name+" removed. "+CurrentPinInfo[name].Type.ToString());
						FIO[name].Dispose();
						FIO.Remove(name);
					}
					CurrentPinInfo[name].State = StateEnum.Clean;
					
					IOAttribute ioAttribute;
					if (Input) {
						ioAttribute = new InputAttribute(name);
					} else ioAttribute = new OutputAttribute(name);

					ioAttribute.Visibility = PinVisibility.True;
					ioAttribute.Order = CurrentPinInfo[name].Order;
					
					FLogger.Log(LogType.Debug, "create " + (Input?"input ":"output ")+ ioAttribute.Order.ToString() + " " + name);
					
					Type ioType;
					switch (CurrentPinInfo[name].Type) {
						case TypeEnum.Color:
							if (Input) ioType = typeof(IDiffSpread<RGBAColor>);
								else ioType = typeof(ISpread<RGBAColor>);
						break;
						case TypeEnum.Transform:
							if (Input) ioType = typeof(IDiffSpread<Matrix4x4>);
								else ioType = typeof(ISpread<Matrix4x4>);
						break;
						default:
							if (Input) ioType = typeof(IDiffSpread<double>);
								else ioType = typeof(ISpread<double>);
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
//			FLogger.Log(LogType.Debug, "SAVE");
			
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
				
//					FLogger.Log(LogType.Debug, "save to config " + CurrentPinInfo[name].Count + " " + name);
				}
			}
			
//			FCBinSize.Changed += HandleChangeConfig;
//			FCName.Changed += HandleChangeConfig;
//			FCType.Changed += HandleChangeConfig;
			
		}
		
		public void SaveFromConfig() {
//			FLogger.Log(LogType.Debug, "Load from Config");
			
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
//			FLogger.Log(LogType.Debug, "Getting Data from Static about "+FID[0]);
			Dictionary<string, PinInfo> pinDict = PinDictionary[FID[0]];
			
			foreach(string name in CurrentPinInfo.Keys) {
				CurrentPinInfo[name].State = StateEnum.Kill;
			}

			foreach(string name in pinDict.Keys) {
				if (CurrentPinInfo.ContainsKey(name)) {
					// pin with this name is already present
					if ( pinDict[name] != CurrentPinInfo[name]) {
						// pin with this name is not up to date, so flag it dirty
						CurrentPinInfo[name] = (PinInfo)pinDict[name].Clone();
						CurrentPinInfo[name].State = StateEnum.Dirty;
					} else 	{
						// pin did not change type or name, so just update BinSize on the fly
						CurrentPinInfo[name].Count = ((PinInfo)pinDict[name]).Count;
						CurrentPinInfo[name].State = StateEnum.Clean;
					}
				} else {
					// pin with this name is not present
					CurrentPinInfo[name] = (PinInfo)pinDict[name].Clone();
					CurrentPinInfo[name].State = StateEnum.New;
				}
			}
		}
		

		public bool ReConfigurate() {
			bool changed = false;
			
			if (FReset[0]) {
				CurrentPinInfo.Clear();
				SaveToConfig();
				
				foreach (string pin in FIO.Keys) {
					FIO[pin].Dispose();
				}
				FIO.Clear();
				changed = true;
			}
			
			if (FSave[0]) {
				FLogger.Log(LogType.Debug, "Applying MConfig Scheme with the name "+FID[0]+".");
				if (PinDictionary.ContainsKey(FID[0])) {
					SaveFromStatic();
					SaveToConfig();
					Create();
					changed = true;
				}
				else {
					FLogger.Log(LogType.Debug, "No MConfig Scheme with the name "+FID[0]+" detected.");
					Create();
					changed = true;
				}
			}
			
			if (MessageNode.Updated != null) {
				if (PinDictionary.ContainsKey(FID[0])) {
				FLogger.Log(LogType.Debug, "Quickfixing MConfig Scheme with the name "+FID[0]+".");
					SaveFromStatic();
					SaveToConfig();
					changed = true;
				}
			}	
			return changed;
		}
		
		public virtual void Evaluate(int SpreadMax)
		{

		}
	}

	#region PluginInfo
	[PluginInfo(Name = "MSend", Category = "Spreads", Version = "DynamicPins", Help = "Basic template with a dynamic amount of in- and outputs", Tags = "", AutoEvaluate=true)]
	#endregion PluginInfo
	public class DynamicPinsSpreadsMSendNode : DynamicPinsSpreadsMNode {
		[Output("Data")]
		ISpread<double> FData;

		public DynamicPinsSpreadsMSendNode():base() {
			Input = true;
		}

		public override void Evaluate(int SpreadMax)
		{
			bool changed = ReConfigurate();

			foreach (IIOContainer pin in FIO.Values) {
				try {
					if (((IDiffSpread)(pin.RawIOObject)).IsChanged) changed = true;
					
				} catch (Exception e) {
					FLogger.Log(LogType.Debug, e.ToString());	
				}
			}

			changed = true;
			
			if (changed) {
				FData.SliceCount = 0;

				int count = CurrentPinInfo.Count;
				PinInfo[] pins = new PinInfo[count];
				
				CurrentPinInfo.Values.CopyTo(pins, 0);
				Array.Sort(pins);

				try {
					for (int i=0;i<count;i++) {
//						FLogger.Log(LogType.Debug, i.ToString() + " " +pins[i].Name + " " +pins[i].valueSize());
						if (FIO.ContainsKey(pins[i].Name))
							pins[i].Spread2Stream((ISpread)(FIO[pins[i].Name].RawIOObject), ref FData);
					}
				} catch (Exception e) {
					FLogger.Log(LogType.Debug, "Input Pin not ready. "+e.ToString());
				}
			}
		}
	}

	#region PluginInfo
	[PluginInfo(Name = "MReceive", Category = "Spreads", Version = "DynamicPins", Help = "Basic template with a dynamic amount of in- and outputs", Tags = "", AutoEvaluate=true)]
	#endregion PluginInfo
	public class DynamicPinsSpreadsMReceiveNode : DynamicPinsSpreadsMNode {
		[Input("Data")]
		IDiffSpread<double> FData;
		
		public DynamicPinsSpreadsMReceiveNode():base() {
			Input = false;
		}
		
		public override void Evaluate(int SpreadMax)
		{
			bool changed = ReConfigurate();
			
			if (changed || FData.IsChanged) {
				
				int count = CurrentPinInfo.Count;
				PinInfo[] pins = new PinInfo[count];
				
				CurrentPinInfo.Values.CopyTo(pins, 0);
				Array.Sort(pins);

				int offset = 0;
				for (int i=0;i<count;i++) {
					string name = pins[i].Name;

					try {
						if (FIO.ContainsKey(name)) {
							ISpread spread = (ISpread) (FIO[name].RawIOObject);
							pins[i].Stream2Spread(FData, offset, ref spread );
						}
				
						
					}	catch (Exception e) {
						FLogger.Log(LogType.Debug, "Output Pin not ready. "+e.ToString());
					}
					offset += pins[i].valueSize();
					
				}
			}
		}
	}
}
