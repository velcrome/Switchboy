#region licence/info

//////project name
//Xbox360Controller

//////description
//driver for the Xbox360 gamepad

//////licence
//GNU Lesser General Public License (LGPL)
//english: http://www.gnu.org/licenses/lgpl.html
//german: http://www.gnu.de/lgpl-ger.html

//////language/ide
//C# sharpdevelop

//////dependencies
//VVVV.PluginInterfaces.V1;
//VVVV.Utils.VColor;
//VVVV.Utils.VMath;
//SlimDX;
//SlimDX.XInput;


//////initial author
//r.arcaya based on the spaceNavigator plugin by velcrome and updated by joreg


#endregion licence/info

//use what you need
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Collections.Generic;

using VVVV.PluginInterfaces.V1;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using SlimDX;
using SlimDX.XInput;


//the vvvv node namespace
namespace VVVV.Nodes
{
	
	//class definition
	public class Xbox360ControllerPlugin: IPlugin
	{
		#region field declaration
		
		//the host (mandatory)
		private IPluginHost FHost;
		// Track whether Dispose has been called.
   		private bool FDisposed = false;
   		
		//output pin declaration
        //This are for xbox
        private IValueOut FLeftThumbPin;
        private IValueOut FRightThumbPin;

        private IValueOut FLeftThumbClickPin;
        private IValueOut FRightThumbClickPin;

        private IValueOut FLeftBumperPin;
        private IValueOut FRightBumperPin;

        private IValueOut FLeftTriggerPin;
        private IValueOut FRightTriggerPin;

        private IValueOut FAbuttonPin;
        private IValueOut FBbuttonPin;
        private IValueOut FXbuttonPin;
        private IValueOut FYbuttonPin;

        private IValueOut FUpPin;
        private IValueOut FDownPin;
        private IValueOut FLeftPin;
        private IValueOut FRightPin;

        private IValueOut FBackPin;
        private IValueOut FStartPin;



        private GamepadState FGamepad;





		//a list that holds the state for every button
		
		#endregion field declaration
		
		#region constructor/destructor
		
		public Xbox360ControllerPlugin()
		{
			try
			{
               //implement a tester here, that raises an exception if no gamepad is conected
                //also implement a input pin to select the controller number
             FGamepad = new GamepadState(0);



			}
			catch (COMException e)
			{
				Console.Error.WriteLine("Xbox360Controller: " + e.Message);
			}
		}
		
		// Implementing IDisposable's Dispose method.
		// Do not make this method virtual.
		// A derived class should not be able to override this method.
		public void Dispose()
		{
			Dispose(true);
			// Take yourself off the Finalization queue
			// to prevent finalization code for this object
			// from executing a second time.
			GC.SuppressFinalize(this);
		}
		
		// Dispose(bool disposing) executes in two distinct scenarios.
		// If disposing equals true, the method has been called directly
		// or indirectly by a user's code. Managed and unmanaged resources
		// can be disposed.
		// If disposing equals false, the method has been called by the
		// runtime from inside the finalizer and you should not reference
		// other objects. Only unmanaged resources can be disposed.
		protected virtual void Dispose(bool disposing)
		{
			// Check to see if Dispose has already been called.
			if(!FDisposed)
			{
                if (disposing)
                {
                    
                   
                }
                FGamepad = null;
				// Release unmanaged resources. If disposing is false,
				// only the following code is executed.
                
				
				if (FHost != null)
					FHost.Log(TLogType.Debug, "Xbox360Controller is being deleted");
				
				// Note that this is not thread safe.
				// Another thread could start disposing the object
				// after the managed resources are disposed,
				// but before the disposed flag is set to true.
				// If thread safety is necessary, it must be
				// implemented by the client.
			}
			FDisposed = true;
		}

		// Use C# destructor syntax for finalization code.
		// This destructor will run only if the Dispose method
		// does not get called.
		// It gives your base class the opportunity to finalize.
		// Do not provide destructors in types derived from this class.
        ~Xbox360ControllerPlugin()
		{
			// Do not re-create Dispose clean-up code here.
			// Calling Dispose(false) is optimal in terms of
			// readability and maintainability.
			Dispose(false);
		}
		
		#endregion constructor/destructor
		
		#region node name and infos
		
		//provide node infos
		public static IPluginInfo PluginInfo
		{
			get
			{
				//fill out nodes info
				IPluginInfo Info = new PluginInfo();
				Info.Name = "Xbox360Controller";
				Info.Category = "Devices";
				Info.Version = "";
				Info.Help = "Offers support for the Xbox 360 controller. It uses the SlimDX version of XInput";
				Info.Bugs = "Work in progress";
				Info.Credits = "r.arcaya";
				Info.Warnings = "";
				
				//leave below as is
				System.Diagnostics.StackTrace st = new System.Diagnostics.StackTrace(true);
				System.Diagnostics.StackFrame sf = st.GetFrame(0);
				System.Reflection.MethodBase method = sf.GetMethod();
				Info.Namespace = method.DeclaringType.Namespace;
				Info.Class = method.DeclaringType.Name;
				return Info;
				//leave above as is
			}
		}

		public bool AutoEvaluate
		{
			//return true if this node needs to calculate every frame even if nobody asks for its output
			get {return false;}
		}

		#endregion node name and infos
		
		#region pin creation
		
		//this method is called by vvvv when the node is created
		public void SetPluginHost(IPluginHost Host)
		{
			//assign host
			FHost = Host;

			//create inputs

			//create outputs
            FHost.CreateValueOutput("Left Thumbstick", 2, null, TSliceMode.Dynamic, TPinVisibility.True, out FLeftThumbPin);
            FLeftThumbPin.SetSubType2D(-1d, 1d, 0.001, 0, 0, false, false, false);
            FLeftThumbPin.SliceCount = 1;

            FHost.CreateValueOutput("Right Thumbstick", 2, null, TSliceMode.Dynamic, TPinVisibility.True, out FRightThumbPin);
            FRightThumbPin.SetSubType2D(-1d, 1d, 0.001, 0, 0, false, false, false);
            FRightThumbPin.SliceCount = 1;

            FHost.CreateValueOutput("Left Thumbstick Click", 1, null, TSliceMode.Dynamic, TPinVisibility.True, out FLeftThumbClickPin);
            FLeftThumbClickPin.SetSubType(0, 1, 1, 0, true, false, false);
            FLeftThumbClickPin.SliceCount = 1;

            FHost.CreateValueOutput("Right Thumbstick Click", 1, null, TSliceMode.Dynamic, TPinVisibility.True, out FRightThumbClickPin);
            FRightThumbClickPin.SetSubType(0, 1, 1, 0, true, false, false);
            FRightThumbClickPin.SliceCount = 1;

            FHost.CreateValueOutput("Left Trigger", 1, null, TSliceMode.Dynamic, TPinVisibility.True, out FLeftTriggerPin);
            FLeftTriggerPin.SetSubType(0, 1, 0.001, 0, false, false, true);
            FLeftTriggerPin.SliceCount = 1;

            FHost.CreateValueOutput("Right Trigger", 1, null, TSliceMode.Dynamic, TPinVisibility.True, out FRightTriggerPin);
            FRightTriggerPin.SetSubType(0, 1, 0.001, 0, false, false, true);
            FRightTriggerPin.SliceCount = 1;

            FHost.CreateValueOutput("Left Bumper", 1, null, TSliceMode.Dynamic, TPinVisibility.True, out FLeftBumperPin);
            FLeftBumperPin.SetSubType(0, 1, 1, 0, true, false, false);
            FLeftBumperPin.SliceCount = 1;

            FHost.CreateValueOutput("Right Bumper", 1, null, TSliceMode.Dynamic, TPinVisibility.True, out FRightBumperPin);
            FRightBumperPin.SetSubType(0, 1, 1, 0, true, false, false);
            FRightBumperPin.SliceCount = 1;

            FHost.CreateValueOutput("A", 1, null, TSliceMode.Dynamic, TPinVisibility.True, out FAbuttonPin);
            FAbuttonPin.SetSubType(0, 1, 1, 0, true, false, false);
            FAbuttonPin.SliceCount = 1;

            FHost.CreateValueOutput("B", 1, null, TSliceMode.Dynamic, TPinVisibility.True, out FBbuttonPin);
            FBbuttonPin.SetSubType(0, 1, 1, 0, true, false, false);
            FBbuttonPin.SliceCount = 1;

            FHost.CreateValueOutput("X", 1, null, TSliceMode.Dynamic, TPinVisibility.True, out FXbuttonPin);
            FXbuttonPin.SetSubType(0, 1, 1, 0, true, false, false);
            FXbuttonPin.SliceCount = 1;

            FHost.CreateValueOutput("Y", 1, null, TSliceMode.Dynamic, TPinVisibility.True, out FYbuttonPin);
            FYbuttonPin.SetSubType(0, 1, 1, 0, true, false, false);
            FYbuttonPin.SliceCount = 1;

            FHost.CreateValueOutput("Up", 1, null, TSliceMode.Dynamic, TPinVisibility.True, out FUpPin);
            FUpPin.SetSubType(0, 1, 1, 0, true, false, false);
            FUpPin.SliceCount = 1; 
            
            FHost.CreateValueOutput("Down", 1, null, TSliceMode.Dynamic, TPinVisibility.True, out FDownPin);
            FDownPin.SetSubType(0, 1, 1, 0, true, false, false);
            FDownPin.SliceCount = 1;

            FHost.CreateValueOutput("Left", 1, null, TSliceMode.Dynamic, TPinVisibility.True, out FLeftPin);
            FLeftPin.SetSubType(0, 1, 1, 0, true, false, false);
            FLeftPin.SliceCount = 1;

            FHost.CreateValueOutput("Right", 1, null, TSliceMode.Dynamic, TPinVisibility.True, out FRightPin);
            FRightPin.SetSubType(0, 1, 1, 0, true, false, false);
            FRightPin.SliceCount = 1;

            FHost.CreateValueOutput("Start", 1, null, TSliceMode.Dynamic, TPinVisibility.True, out FStartPin);
            FStartPin.SetSubType(0, 1, 1, 0, true, false, false);
            FStartPin.SliceCount = 1;

            FHost.CreateValueOutput("Back", 1, null, TSliceMode.Dynamic, TPinVisibility.True, out FBackPin);
            FBackPin.SetSubType(0, 1, 1, 0, true, false, false);
            FBackPin.SliceCount = 1;

            //poner los otros aca





         
		}

		#endregion pin creation
		
		#region mainloop
		
		public void Configurate(IPluginConfig Input)
		{
			//nothing to configure in this plugin
			//only used in conjunction with inputs of type cmpdConfigurate
		}
		
		//here we go, thats the method called by vvvv each frame
		//all data handling should be in here
		public void Evaluate(int SpreadMax)
		{
            FGamepad.Update();

            

            FLeftThumbPin.SetValue2D(0, (double)FGamepad.LeftStick.Position.X, (double)FGamepad.LeftStick.Position.Y);
            FRightThumbPin.SetValue2D(0, (double)FGamepad.RightStick.Position.X, (double)FGamepad.RightStick.Position.Y);

            FLeftThumbClickPin.SetValue(0, Bool2Double(FGamepad.LeftStick.Clicked));
            FRightThumbClickPin.SetValue(0, Bool2Double(FGamepad.RightStick.Clicked));

            FLeftTriggerPin.SetValue(0, (double)FGamepad.LeftTrigger);
            FRightTriggerPin.SetValue(0, (double)FGamepad.RightTrigger);

            FLeftBumperPin.SetValue(0, Bool2Double(FGamepad.LeftShoulder));
            FRightBumperPin.SetValue(0, Bool2Double(FGamepad.RightShoulder));

            FAbuttonPin.SetValue(0, Bool2Double(FGamepad.A));
            FBbuttonPin.SetValue(0, Bool2Double(FGamepad.B));
            FXbuttonPin.SetValue(0, Bool2Double(FGamepad.X));
            FYbuttonPin.SetValue(0, Bool2Double(FGamepad.Y));

            FUpPin.SetValue(0, Bool2Double(FGamepad.DPad.Up));
            FDownPin.SetValue(0, Bool2Double(FGamepad.DPad.Down));
            FLeftPin.SetValue(0, Bool2Double(FGamepad.DPad.Left));
            FRightPin.SetValue(0, Bool2Double(FGamepad.DPad.Right));

            FStartPin.SetValue(0, Bool2Double(FGamepad.Start));
            FBackPin.SetValue(0, Bool2Double(FGamepad.Back));

		}
		#endregion mainloop
		

        double Bool2Double(bool button)
        {
            double returnValue;
            if (button == true)
            {returnValue = 1d;} else {returnValue = 0d;}
            return returnValue;




        }
	}

    // SlimDX Wrapper developed by
    // Zaknafein/Renaud Bédard of The Instruction Limit
    // http://theinstructionlimit.com

    public class GamepadState
    {
        uint lastPacket;
   
        public GamepadState(UserIndex userIndex)
        {
            UserIndex = userIndex;
            Controller = new Controller(userIndex);

        }

        public readonly UserIndex UserIndex;
        public readonly Controller Controller;

        public DPadState DPad { get; private set; }
        public ThumbstickState LeftStick { get; private set; }
        public ThumbstickState RightStick { get; private set; }

        public bool A { get; private set; }
        public bool B { get; private set; }
        public bool X { get; private set; }
        public bool Y { get; private set; }

        public bool RightShoulder { get; private set; }
        public bool LeftShoulder { get; private set; }

        public bool Start { get; private set; }
        public bool Back { get; private set; }

        public float RightTrigger { get; private set; }
        public float LeftTrigger { get; private set; }

        public bool Connected
        {
            get { return Controller.IsConnected; }
        }

        public void Vibrate(float leftMotor, float rightMotor)
        {
            Controller.SetVibration(new Vibration
            {
                LeftMotorSpeed = (ushort)(MathHelper.Saturate(leftMotor) * ushort.MaxValue),
                RightMotorSpeed = (ushort)(MathHelper.Saturate(rightMotor) * ushort.MaxValue)
            });
        }

        public void Update()
        {
            // If not connected, nothing to update
            if (!Connected) return;

            // If same packet, nothing to update
            State state = Controller.GetState();
            if (lastPacket == state.PacketNumber) return;
            lastPacket = state.PacketNumber;

            var gamepadState = state.Gamepad;

            // Shoulders
            LeftShoulder = (gamepadState.Buttons & GamepadButtonFlags.LeftShoulder) != 0;
            RightShoulder = (gamepadState.Buttons & GamepadButtonFlags.RightShoulder) != 0;

            // Triggers
            LeftTrigger = gamepadState.LeftTrigger / (float)byte.MaxValue;
            RightTrigger = gamepadState.RightTrigger / (float)byte.MaxValue;

            // Buttons
            Start = (gamepadState.Buttons & GamepadButtonFlags.Start) != 0;
            Back = (gamepadState.Buttons & GamepadButtonFlags.Back) != 0;

            A = (gamepadState.Buttons & GamepadButtonFlags.A) != 0;
            B = (gamepadState.Buttons & GamepadButtonFlags.B) != 0;
            X = (gamepadState.Buttons & GamepadButtonFlags.X) != 0;
            Y = (gamepadState.Buttons & GamepadButtonFlags.Y) != 0;

            // D-Pad
            DPad = new DPadState((gamepadState.Buttons & GamepadButtonFlags.DPadUp) != 0,
                                 (gamepadState.Buttons & GamepadButtonFlags.DPadDown) != 0,
                                 (gamepadState.Buttons & GamepadButtonFlags.DPadLeft) != 0,
                                 (gamepadState.Buttons & GamepadButtonFlags.DPadRight) != 0);

            // Thumbsticks
            LeftStick = new ThumbstickState(
                Normalize(gamepadState.LeftThumbX, gamepadState.LeftThumbY, Gamepad.GamepadLeftThumbDeadZone),
                (gamepadState.Buttons & GamepadButtonFlags.LeftThumb) != 0);
            RightStick = new ThumbstickState(
                Normalize(gamepadState.RightThumbX, gamepadState.RightThumbY, Gamepad.GamepadRightThumbDeadZone),
                (gamepadState.Buttons & GamepadButtonFlags.RightThumb) != 0);
        }

        static Vector2 Normalize(short rawX, short rawY, short threshold)
        {
            var value = new Vector2(rawX, rawY);
            var magnitude = value.Length();
            var direction = value / (magnitude == 0 ? 1 : magnitude);

            var normalizedMagnitude = 0.0f;
            if (magnitude - threshold > 0)
                normalizedMagnitude = Math.Min((magnitude - threshold) / (short.MaxValue - threshold), 1);

            return direction * normalizedMagnitude;
        }

        public struct DPadState
        {
            public readonly bool Up, Down, Left, Right;

            public DPadState(bool up, bool down, bool left, bool right)
            {
                Up = up; Down = down; Left = left; Right = right;
            }
        }

        public struct ThumbstickState
        {
            public readonly Vector2 Position;
            public readonly bool Clicked;

            public ThumbstickState(Vector2 position, bool clicked)
            {
                Clicked = clicked;
                Position = position;
            }
        }
    }

    public static class MathHelper
    {
        public static float Saturate(float value)
        {
            return value < 0 ? 0 : value > 1 ? 1 : value;
        }
    }
 
}

