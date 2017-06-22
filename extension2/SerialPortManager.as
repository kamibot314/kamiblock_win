package extension2
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.system.Capabilities;
	
	import extensions.ArduinoManager;
	
	import util.JSON;
	
	public class SerialPortManager extends EventDispatcher
	{
		
		private static var _instance:SerialPortManager = new SerialPortManager();
		private var json:Object;
		
		private var process:NativeProcess;
		private var stdout:String = "";
		private var stderr:String = "";
		private var map:Object;
		private var _list:Array = new Array();
		private var _port:String;
		private var _func:Function;
		private var _x:uint;
		
		public static function getInstance():SerialPortManager{
			return _instance;
		}
		
		public function SerialPortManager()
		{
			json = parseJSON();
		}
		
		private function parseJSON():Object {
			var file:File = File.applicationDirectory.resolvePath(".\\js\\vendor.json");
			
			var fileStream:FileStream = new FileStream(); 
			fileStream.open(file, FileMode.READ);
			
			var s:String = fileStream.readUTFBytes(fileStream.bytesAvailable);
			
			fileStream.close();
			
			return util.JSON.parse(s);
		}
		
		public function getVendor(s:String):String {
			return map[s];
		}
		
		public function listPort(func:Function = null, x:uint = 0):void {
			_func = func;
			_x = x;
			map = new Object();
			
			var listComPorts:File = ArduinoManager.sharedManager().arduinoInstallPath.resolvePath(".\\hardware\\tools\\listComPorts.exe");
			
			var startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			startupInfo.executable = listComPorts;
			
			process = new NativeProcess;
			process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			process.addEventListener(NativeProcessExitEvent.EXIT, onExit);
			process.start(startupInfo);
			trace("listComPorts start");
		}
		
		private function onOutputData(event:ProgressEvent):void 
		{
			stdout += process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable);
		}
		
		private function onExit(event:NativeProcessExitEvent):void
		{
			var split:Array = stdout.split("\r\n");
			for (var i:uint; i < split.length -1; i++) {
				var split2:Array = splitString(split[i]);
				map[split2[0]] = parseSerialPort(split2[1],split2[2]);
				_list.push(split2[0]);
			}
			
			trace("listComPorts end");
			_func(_x);
		}
		
		//[0] PortNumber, [1] Vendor, [3] Type
		private function splitString(s:String):Array {
			var ret:Array = new Array();
			var split:Array = s.split(" - ");
			
			ret.push(split[0]);
			ret.push(split[1]);
			ret.push((split[2] as String).split("\\")[0]);
			return ret;
		}
		
		public function get list():Array {
			return _list;
		}
		
		private function parseSerialPort(vendor:String,deviceType:String):String {
			for (var i:uint = 0; i < json.length; i++) {
				if (json[i]["vendor"] != null && json[i]["vendor"] == vendor) {
					return json[i]["name"];
				}
				if (json[i]["device_type"] != null && json[i]["device_type"] == deviceType) {
					return json[i]["name"];
				}
			}
			return null;
		}
		
		public function set port(port:String):void {
			if (_list.indexOf(port) != -1) _port = port;
			else throw new Error();
		}
		
		public function get port(): String {
			if (_port != null) return _port;
			else return "";
		}
	}
}