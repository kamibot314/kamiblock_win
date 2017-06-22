package extensions
{
	import com.kamibot.bleextension.BluetoothExtension;
	
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import extension2.ArudinoCompiler;
	import extension2.BoardManager0;
	import extension2.SerialPortManager;
	
	import translation.Translator;
	
	import uiwidgets.DialogBox;
	
	import util.ApplicationManager;
	import util.LogManager;
	
	public class SerialManager extends EventDispatcher
	{
		private var moduleList:Array = [];
		private var _currentList:Array = [];
		private static var _instance:SerialManager;
		private var currentPort:String = "";
		private var _selectPort:String = "";
		public var _main:Main;
		private var _upgradeBytesLoaded:Number = 0;
		private var _upgradeBytesTotal:Number = 0;
		private var _isInitUpgrade:Boolean = false;
		private var _dialog:DialogBox = new DialogBox();
		private var _hexToDownload:String = ""
		
		private var _isMacOs:Boolean = ApplicationManager.sharedManager().system==ApplicationManager.MAC_OS;
		private var _avrdude:String = "";
		private var _avrdudeConfig:String = "";
		private var _lastSentByte:ByteArray = null;
		
		public static function sharedManager():SerialManager{
			if(_instance==null){
				_instance = new SerialManager;
			}
			return _instance;
		}
		
		private var _serial:AIRSerial;
		public function SerialManager()
		{
			_serial = new AIRSerial();
			_avrdude = _isMacOs?"avrdude":"avrdude.exe";
			_avrdudeConfig = _isMacOs?"avrdude_mac.conf":"avrdude.conf";
		}
		public function setMBlock(main:Main):void{
			_main = main;
		}
		public var asciiString:String = "";
		private function onChanged(evt:Event):void{
			var len:uint = _serial.getAvailable();
			if(len>0){
				
				var bytes:ByteArray = _serial.readBytes();
				var s:String;
				s = "";
				for(var i:Number = 0;i<bytes.length;i++){
					s += ("0x"+bytes[i].toString(16))+" ";
				}
				trace(new Date() + " : read: " + s);
				if (bytes.length == 5 && bytes[0] == 0xff && bytes[1] == 0x55 && bytes[2] == 0x1 && bytes[3] == 0xd && bytes[4] == 0xa) {
					sendBytes(_lastSentByte);
					trace("retry send");
				} else {
					ConnectionManager.sharedManager().onReceived(bytes);
				}
			}
			return;
			/*
			
			Sat Jun 11 13:58:59 GMT+0900 2016 : read: 0xff 0x55 0xac 
			Sat Jun 11 13:58:59 GMT+0900 2016 : send: 0xff 0x55 0x5 0xac 0x1 0x1 0xa 0xc 
			Sat Jun 11 13:58:59 GMT+0900 2016 : read: 0x2 0x0 0x0 0x0 0x0 0xd 0xa 0xff 0x55 0xac * 
			*/
			/*
			if(len>0){
			var bytes:ByteArray = _serial.readBytes();
			bytes.position = 0;
			asciiString = "";
			var hasNonChar:Boolean = false;
			var c:uint;
			for(var i:uint=0;i<bytes.length;i++){
			c = bytes.readByte();
			asciiString += String.fromCharCode();
			if(c<30){
			hasNonChar = true;
			}
			}
			if(!hasNonChar)dispatchEvent(new Event(Event.CHANGE));
			bytes.position = 0;
			ParseManager.sharedManager().parseBuffer(bytes);
			}*/
		}
		public function get isConnected():Boolean{
			return _serial.isConnected;
		}
		public function get list():Array{
			try{
				_currentList = formatArray(_serial.list().split(",").sort());
				var emptyIndex:int = _currentList.indexOf("");
				if(emptyIndex>-1){
					_currentList.splice(emptyIndex,emptyIndex+1);
				}
			}catch(e:*){
				
			}
			return _currentList;
		}
		private function formatArray(arr:Array):Array {
			var obj:Object={};
			return arr.filter(function(item:*, index:int, array:Array):Boolean{
				return !obj[item]?obj[item]=true:false
			});
		}
		
		public function update():void{
			if(!_serial.isConnected){
				Main.app.topBarPart.setDisconnectedTitle();
				return;
			}else{
				Main.app.topBarPart.setConnectedTitle(Translator.map("Serial Port")+" "+Translator.map("Connected"));
			}
		}
		
		public function sendBytes(bytes:ByteArray):void{
			//sleep(100);
			if(_serial.isConnected){
				var s:String;
				s = "";
				for(var i:Number = 0;i<bytes.length;i++){
					s += ("0x"+bytes[i].toString(16))+" ";
				}
				trace(new Date() + " : send: " + s);
				bytes.position = 0;
				_lastSentByte = new ByteArray();
				_lastSentByte.writeBytes(bytes);
				//2017/02/14 이승훈
				//return _serial.writeBytes(bytes);
				_serial.writeBytes(bytes);
			}
			//return 0;
		}
		
		function sleep(ms:int):void {
			var init:int = getTimer();
			while(true) {
				if(getTimer() - init >= ms) {
					break;
				}
			}
		}
		public function sendString(msg:String):int{
			return _serial.writeString(msg);
		}
		
		//		public function readBytes():ByteArray{
		//			var len:uint = _serial.getAvailable();
		//			if(len>0){
		//				var bytes:ByteArray = _serial.readBytes();
		//				trace("\n-----------------readBytes----------------------");
		//				var s:String;
		//				s = "";
		//				for(var i:Number = 0;i<bytes.length;i++){
		//					s += ("0x"+bytes[i].toString(16))+" ";
		//				}
		//				trace(s);
		//				trace("------------------readBytesEnd---------------------\n");
		//				bytes.position = 0;
		//				return bytes;
		//			}
		//			return new ByteArray;
		//		}
		
		public function open(port:String,baud:uint=115200):Boolean{
			if(_serial.isConnected){
				//				_serial.close();
				return false;
			}
			var r:uint = _serial.open(port,baud);
			trace("r = " + r);
			if(r==0){
				_serial.removeEventListener(Event.CHANGE,onChanged);
				_serial.addEventListener(Event.CHANGE,onChanged);
				_selectPort = port;
				ArduinoManager.sharedManager().isUploading = false;
				Main.app.topBarPart.setConnectedTitle(Translator.map("Serial Port")+" "+Translator.map("Connected"));
			} else {
//				SerialDevice.sharedDevice().clear(port);
//				ConnectionManager.sharedManager().onClose(_selectPort);
//				_serial.close();
//				DialogBox.notify("열 수 없습", "COM이 안 열리는 군요. ㅜ", Main.app.stage);
//				ConnectionManager.sharedManager().
			}
			return r == 0;
		}
		
		public function close():void{
			if(_serial.isConnected){
				_serial.removeEventListener(Event.CHANGE,onChanged);
				_serial.close();
				ConnectionManager.sharedManager().onClose(_selectPort);
			}
		}
		
		public function toggleConnection(port:String):int{
			trace("toggleConnection: " + port);
			if(SerialPortManager.getInstance().port.indexOf(port)>-1&&_serial.isConnected){
				close();
				trace("Serial close");
			}else{
				if(_serial.isConnected){
					close();
					trace("Serial close");
				}
				trace("Open");
				currentPort = port;
				setTimeout(ConnectionManager.sharedManager().onOpen,100,port);
			}
			return 0;
		}
		public function upgrade(hexFile:String=""):void{
			if(!isConnected){
				return;
			}
			Main.app.track("/OpenSerial/Upgrade");
			executeUpgrade();
			_hexToDownload = hexFile;
			Main.app.topBarPart.setDisconnectedTitle();
			ArduinoManager.sharedManager().isUploading = false;
			/*if(DeviceManager.sharedManager().currentDevice.indexOf("leonardo")>-1){
			_serial.close();
			setTimeout(function():void{
			_serial.open(SerialDevice.sharedDevice().port,1200);
			setTimeout(function():void{
			_serial.close();
			if(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS){
			var timer:Timer = new Timer(500,20);
			timer.addEventListener(TimerEvent.TIMER,checkAvailablePort);
			function onCLoseDialog(e:TimerEvent):void{
			_dialog.cancel();
			}
			timer.addEventListener(TimerEvent.TIMER_COMPLETE,onCLoseDialog);
			timer.start();
			}
			},100);
			},100);
			if(ApplicationManager.sharedManager().system==ApplicationManager.MAC_OS){
			setTimeout(upgradeFirmware,2000);
			}
			}else{*/
			//			_serial.close();
			//			ConnectionManager.sharedManager().onClose(_selectPort);
			
			SerialManager.sharedManager().toggleConnection(_selectPort);
			upgradeFirmware("",_selectPort);
			//			currentPort = "";
			//}
		}
		
		public function openSource():void{
			//			Main.app.track("/OpenSerial/ViewSource");
			//			var file:File = new File(File.applicationStorageDirectory.nativePath+"/mBlock/firmware/"+(DeviceManager.sharedManager().currentBoard.indexOf("mbot")>-1?"mbot_firmware":"mblock_firmware"));
			//			file.openWithDefaultApplication();
		}
		
		public function disconnect():void{
			currentPort = "";
			Main.app.topBarPart.setDisconnectedTitle();
			//			MBlock.app.topBarPart.setBluetoothTitle(false);
			ArduinoManager.sharedManager().isUploading = false;
			_serial.close();
			_serial.removeEventListener(Event.CHANGE,onChanged);
		}
		
		public function reconnectSerial():void{
			toggleConnection(currentPort);
		}
		
		private var process:NativeProcess;
		private function checkAvailablePort(evt:TimerEvent):void{
			
			var lastList:Array = _serial.list().split(",");
			for(var i:* in _currentList){
				var index:int = lastList.indexOf(_currentList[i]);
				if(index>-1){
					lastList.splice(index,1);
				}
			}
			if(lastList.length>0&&lastList[0].indexOf("COM")>-1){
				Timer(evt.target).stop();
				var temp:String = SerialPortManager.getInstance().port;
				SerialPortManager.getInstance().port = lastList[0];
				upgradeFirmware();
				SerialPortManager.getInstance().port = temp;
			}
		}
		
		public function upgradeFirmware(hexfile:String="",currentPort:String=""):void{	
			trace("upgradeFirmware");
			trace("currentDevice = " + BoardManager0.getInstance().boardData.codename);
			trace("hexfile = " + hexfile);
			Main.app.topBarPart.setDisconnectedTitle();
			var file:File = ArduinoManager.sharedManager().arduinoInstallPath.resolvePath(".\\hardware\\tools\\avr\\bin\\avrdude.exe");
			if(!file.exists){
				trace("upgrade fail!");
				return;
			}
			var tf:File;
			var currentDevice:String = BoardManager0.getInstance().boardData.codename;
			if (currentPort == "")currentPort = SerialPortManager.getInstance().port;
			trace("avrdude:",file.nativePath,currentDevice,currentPort,"\n");
			if(NativeProcess.isSupported) {
				var nativeProcessStartupInfo:NativeProcessStartupInfo =new NativeProcessStartupInfo();
				nativeProcessStartupInfo.executable = file;
				var v:Vector.<String> = new Vector.<String>();//Parameters required for external applications
				v.push("-C" + ArduinoManager.sharedManager().arduinoInstallPath.resolvePath(".\\hardware\\RBL\\RBL_nRF51822\\avrdude_conf\\avrdude.conf").nativePath);
				v.push("-v");
				v.push("-V");
				v.push("-pcortex-m0");
				v.push("-cavr109");
				v.push("-P"+currentPort);
				v.push("-b115200");
				v.push("-D");
				if(_hexToDownload.length==0){
					var hexFile_mega2560:String = (File.applicationDirectory.nativePath+"/tools/hex/kamibot.hex");//.split("\\").join("/");
					tf = new File(hexFile_mega2560);
					v.push("-Uflash:w:"+hexFile_mega2560+":i");
				}else{
					tf = new File(_hexToDownload);
					v.push("-Uflash:w:"+_hexToDownload+":i");
				}
				
				nativeProcessStartupInfo.arguments = v;
				trace("arguments = " + v);
				process = new NativeProcess();
				process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA,onStandardOutputData);
				process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
				process.addEventListener(NativeProcessExitEvent.EXIT, onExit);
				process.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onIOError);
				process.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOError);
				process.start(nativeProcessStartupInfo);
				ArduinoManager.sharedManager().isUploading = true;
			} else {
				trace("no support");
			}
		}
		
		private function onStandardOutputData(event:ProgressEvent):void {
			//			_upgradeBytesLoaded+=process.standardOutput.bytesAvailable;
			
			//			_dialog.setText(Translator.map('Executing')+" ... "+_upgradeBytesLoaded+"%");
			LogManager.sharedManager().log(process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable ));
			
		}
		
		private var _isLoadHex:Boolean = false;
		private var _isReadStart:Boolean = false;
		private var _isWritingStart:Boolean = false;
		private var _upgradePresend:Number = 0;
		private var _progress:Number = 0;
		
		public function onErrorData(event:ProgressEvent):void
		{
			var msg:String = process.standardError.readUTFBytes(process.standardError.bytesAvailable);
			//			
			//			var byteArray:ByteArray = new ByteArray();
			//			byteArray.writeUTFBytes("#");
			
			//			var arr:Array = msg.split(DeviceManager.sharedManager().currentDevice.indexOf("leonardo")>-1?"Send: B [42] . [00] . [":(DeviceManager.sharedManager().currentDevice.indexOf("nano")>-1?"Send: t [74] . [00] . [":"Send: d [64] . [00] . ["));
			//			if(msg.indexOf("writing flash (") != -1){
			//				_upgradeBytesTotal = Math.max(3000,Number(msg.split("writing flash (")[1].split(" bytes)")[0]));
			//			}
			//			//			trace("total:",_upgradeBytesLoaded,_upgradeBytesTotal);
			//			_upgradeBytesLoaded+=arr.length>1?Number("0x"+arr[1].split("]")[0]):0;
			//			var progress:Number = Math.min(100,Math.floor(_upgradeBytesLoaded/_upgradeBytesTotal*105));
			//			trace("_upgradeBytesTotal = " + _upgradeBytesTotal + " _upgradeBytesLoaded = " + _upgradeBytesLoaded + " progress = " + progress);
			//			if(progress>=100){
			//				//				setTimeout(_dialog.cancel,2000); 
			//				_dialog.setText(Translator.map('Upload Finish')+" ... "+100+"%");
			//				//				setTimeout(connect,2000,_selectPort);
			//			}else{
			//				_dialog.setText(Translator.map('Uploading')+" ... "+Math.min(100,isNaN(progress)?100:progress)+"%");
			//			}
			LogManager.sharedManager().log(msg);
			updateProgressDialog();
		}
		
		public function onExit(event:NativeProcessExitEvent):void
		{
			ArduinoManager.sharedManager().isUploading = false;
			SerialManager.sharedManager().toggleConnection(_selectPort);
			LogManager.sharedManager().log("Process exited with "+event.exitCode);
			if (event.exitCode == 0) {
				_dialog.setText(Translator.map("Upload Finished"));
			} else {
				_dialog.setText(Translator.map('Upload Faliure Code: ') + event.exitCode + "\n" + Translator.map("Check current board selected"));
			}
			//			setTimeout(open,100,_selectPort);
			//			setTimeout(ConnectionManager.sharedManager().onOpen,100,_selectPort);
			//setTimeout(_dialog.cancel,2000);
		}
		
		public function onIOError(event:IOErrorEvent):void
		{
			LogManager.sharedManager().log(event.toString());
			updateProgressDialog();
		}
		
		private function updateProgressDialog():void {
			_progress++;
			if (_progress > (3 * 10)) _progress = 0;
			var text:String;
			text = Translator.map('Uploading');
			for (var i:Number = 0; i < (_progress / 10); i++) {
				text += ".";
			}
			_dialog.setText(text);
		}
		
		public function executeUpgrade():void {
			if(!_isInitUpgrade){
				_isInitUpgrade = true;
				function cancel():void { process.exit(true);_dialog.cancel(); }
				_dialog.addTitle(Translator.map('Program Upload'));
				_dialog.addButton(Translator.map('Close'), cancel);
			}else{
				_dialog.setTitle(('Program Upload'));
				_dialog.setButton(('Close'));
			}
			_upgradeBytesLoaded = 0;
			_dialog.setText(Translator.map('Uploading'));
			_dialog.showOnStage(_main.stage);
		}
	}
}