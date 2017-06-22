package extensions
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import extension2.SerialPortManager;
	
	import interpreter.Thread;
	
	import translation.Translator;
	
	import uiwidgets.DialogBox;
	
	import util.LogManager;
	
	public class ConnectionManager extends EventDispatcher
	{
		private static var _instance:ConnectionManager;
		public var extensionName:String = "";
		public function ConnectionManager()
		{
		}
		
		public static function sharedManager():ConnectionManager{
			if(_instance==null){
				_instance = new ConnectionManager;
			}
			return _instance;
		}
		
		public function onConnect(name:String):void{
			switch(name){
				//				case "discover_bt":{
				//					BluetoothManager.sharedManager().discover();
				//					break;
				//				}
				//				case "clear_bt":{
				//					BluetoothManager.sharedManager().clearHistory();
				//					break;
				//				}
				//				case "netframework":{
				//					navigateToURL(new URLRequest("http://www.microsoft.com/en-us/download/details.aspx?id=30653"));
				//					break;
				//				}
				case "view_source":{
					SerialManager.sharedManager().openSource();
					break;
				}
				case "scratch_firmware":{
					SerialManager.sharedManager().upgrade();
					break;
				}
					//				case "connect_network":{
					//					SocketManager.sharedManager().probe("custom");
					//					break;
					//				}
				case "driver":{
					Main.app.track("/OpenSerial/InstallDriver");
					var fileDriver:File;
					if (flash.system.Capabilities.supports64BitProcesses) {
						fileDriver = new File(File.applicationDirectory.nativePath+"/Arduino/drivers/dpinst-amd64.exe");
					} else {
						fileDriver = new File(File.applicationDirectory.nativePath+"/Arduino/drivers/dpinst-x86.exe");
					}
					fileDriver.openWithDefaultApplication();
					break;
				}
					//				case "connect_hid":{
					//					if(!HIDManager.sharedManager().isConnected){
					//						HIDManager.sharedManager().onOpen();
					//					}else{
					//						HIDManager.sharedManager().onClose();
					//					}
					//					break;
					//				}
				default:{
					if(name.indexOf("serial_")>-1){
						SerialManager.sharedManager().toggleConnection(name.split("serial_").join(""));
					}
					//					
					//					if(name.indexOf("bt_")>-1){
					//						BluetoothManager.sharedManager().connect(name.split("bt_").join(""));
					//					}
					//					
					//					if(name.indexOf("net_")>-1){
					//						SocketManager.sharedManager().probe(name.split("net_")[1]);
					//					}
					
					if(name.indexOf("controller_firmware_")>-1){
						SerialManager.sharedManager().upgrade(File.applicationDirectory.resolvePath("tools/hex/"+name.split("controller_firmware_")[1]+".hex").nativePath);
						trace("tools/hex/"+name.split("controller_firmware_")[1]+".hex" + " upload...");
					}
				}
			}
		}
		
		public function open(port:String,baud:uint=115200):Boolean{
			LogManager.sharedManager().log("connecting:"+port);
			if(port){
				if(port.indexOf("COM")>-1||port.indexOf("/dev/tty.")>-1){
					return SerialManager.sharedManager().open(port,baud);
				}else if(port.indexOf(" (")>-1){
					return BluetoothManager.sharedManager().open(port);
				}else if(port.indexOf("HID")>-1){
					return HIDManager.sharedManager().open();
				}else{
					return SocketManager.sharedManager().open(port);
				}
			}
			return false;
		}
		
		public function onClose(port:String):void{
			SerialDevice.sharedDevice().clear(port);
			if(!SerialDevice.sharedDevice().connected){
				Main.app.topBarPart.setDisconnectedTitle();
			}else{
				if(SerialManager.sharedManager().isConnected){
					Main.app.topBarPart.setConnectedTitle(Translator.map("Serial Port")+" "+Translator.map("Connected"));
				}else{
					Main.app.topBarPart.setConnectedTitle(Translator.map("Network")+" "+Translator.map("Connected"));
				}
			}
			this.dispatchEvent(new Event(Event.CLOSE));
		}
		
		public function onRemoved(extName:String = ""):void{
			extensionName = extName;
			this.dispatchEvent(new Event(Event.REMOVED));
		}
		
		public function onOpen(port:String):void{
			SerialPortManager.getInstance().port = port;
			this.dispatchEvent(new Event(Event.CONNECT));
		}
		
		public function onReOpen():void{
			if(SerialPortManager.getInstance().port!=""){
				this.dispatchEvent(new Event(Event.CONNECT));
			}
		}
		
		private var _bytes:ByteArray;
		public function onReceived(bytes:ByteArray):void{
			_bytes = bytes;
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		
		/**
		 * step 1 - first time: _state = SEND
		 * step 2 - send signal:  _state = WAIT
		 * step 3 - recive response:   _state = GOTONEXT
		 */
		private var _state:uint = SEND;
		
		public static const SEND:uint = 0;
		public static const WAIT:uint = 1;
		public static const GOTONEXT:uint = 2;
		
		public var greenFlag:Boolean = false;
		
		private var _timerId:uint = 0;
		private var _responseCount:uint= 0;
		
		private function sleep(ms:int):void {
			var init:int = getTimer();
			while(true) {
				if(getTimer() - init >= ms) {
					break;
				}
			}
		}
		
		//private var _async:Boolean = false;
		public function sendBytes(bytes:ByteArray):void{
			//_async = async;
			//if (async) {
			//	SerialManager.sharedManager().sendBytes(bytes);
			//	if (_timerId == 0) _timerId = setTimeout(onTimeout,5000);
			//} else {
				
//				if (bytes.length >= 4 && bytes[0] == 0xff && bytes[1] == 0x55 && bytes[2] == 0x2 && bytes[3] == 0x0 && bytes[4] == 0x4) {
//			if(preBytes== bytes){
//				return;
//			}else{
//				preBytes = bytes;
//			}
				if (bytes[0] == 0xff && bytes[1] == 0x55 && bytes[2] == 0x2 && bytes[3] == 0x0 && bytes[4] == 0x4) {
					setState(SEND);
					SerialManager.sharedManager().sendBytes(bytes);
					sleep(200);
					//setState(WAIT);
					return;
				}
				
				switch(_state)
				{
					case SEND:
					{
						var timeoutCount:int = -1;
						if (bytes.length == 7) {
							if (bytes[5] == 0x64) {
								timeoutCount = bytes[6];
							}
						} else if (bytes.length == 6) {
							if (bytes[5] == 0x65 || bytes[5] == 0x66 || bytes[5] == 0x67) {
								timeoutCount = 1;
							}
						}
						
						if(SerialManager.sharedManager().isConnected && bytes.length > 0){
							bytes.position = 0;
							SerialManager.sharedManager().sendBytes(bytes);
							setState(WAIT);
							Main.app.interp.doYield();
							
							if (timeoutCount == -1) {
								if (_timerId == 0) _timerId = setTimeout(onTimeout,1000);
								trace("set time out " + (1000));
							} else {
								if (_timerId == 0) _timerId = setTimeout(onTimeout2,10000 * timeoutCount);
								trace("set time out " + (10000 * timeoutCount));
							}
							
						}
						// step 1. first comes
						break;
					}
					case WAIT://if first run block, send bytes and set waitng state 
					{
						Main.app.interp.doYield();//wating for response(bytes is send)
						// step 2. waiting response
						break;
					}
					case GOTONEXT:
					{
						setState(SEND);
						// step 4. goto next block (no nothing: if not yield, interpreter automatically go to next block)
						break;
					}
						
					default:
					{
						break;
					}
				//}
			}
		}
		
		
		//clear timeout when stop flag pressed
		public function clearTimeoutTimer():void {
			clearTimeout(_timerId);
			_timerId = 0;
		}
		
		private function onTimeout():void {
			trace("onTimeout");
			var dialog:DialogBox = new DialogBox();
			dialog.addTitle("No response from KamiBot");
			dialog.addText("No response from KamiBot. Please ensure that your KamiBot is turned on.");
			function onCancel():void{
				dialog.cancel();
			}
			dialog.addButton("OK",onCancel);
			dialog.showOnStage(Main.app.stage);
			Main.app.runtime.stopAll();
			setState(SEND);
			_timerId = 0;
		}
		
		private function onTimeout2():void {
			trace("onTimeout2");
			var dialog:DialogBox = new DialogBox();
			dialog.addTitle("KamiBot Unable to detect any line");
			dialog.addText("KamiBot Unable to detect any line. Please place your KamiBot on the line.");
			function onCancel():void{
				dialog.cancel();
			}
			dialog.addButton("OK",onCancel);
			dialog.showOnStage(Main.app.stage);
			Main.app.runtime.stopAll();
			setState(SEND);
			_timerId = 0;
		}
		
		public function setState(state:uint):void {
			_state = state;
			trace("_state = " + _state);
		}
		
		public function readBytes():ByteArray{
			clearTimeoutTimer();
			//if (!_async) {
			_responseCount += _bytes.length;
			if (_responseCount >= 4) {//response reqired unless 4 bytes (sometimes response 1 and 3 bytes)
				if (_state == WAIT) setState(GOTONEXT);
				_responseCount = 0;
				// step 3. recive response, go to next block
			}
			//}
			if(_bytes){
				return _bytes;
			}
			return new ByteArray;
		}
	}
}