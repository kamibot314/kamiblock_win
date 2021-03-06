package extensions
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import extension2.SerialPortManager;

	public class SerialDevice
	{
		private static var _instance:SerialDevice;
		private var _ports:Array = [];
		
		public function SerialDevice()
		{
		}
		
		public static function sharedDevice():SerialDevice{
			if(_instance==null){
				_instance = new SerialDevice;
			}
			return _instance;
		}
		
//		public function set port(v:String):void{
//			if(_ports.indexOf(v)==-1){
//				_ports.push(v);
//			}
//		}
//		
//		public function get port():String{
//			if(_ports.length>0){
//				return _ports[_ports.length-1];
//			}
//			return "";
//		}
//		
//		public function get ports():Array{
//			return _ports;
//		}
		
		public function onConnect(port:String):void{
//			this.port = port;
			SerialPortManager.getInstance().port = port;
		}
		
		public function open(param:Object,openedHandle:Function):void{
			var stopBits:uint = param.stopBits
			var bitRate:uint = param.bitRate;
			var ctsFlowControl:uint = param.ctsFlowControl;
//			if(ConnectionManager.sharedManager().open(this.port,bitRate)){
//				openedHandle(this);
//				ConnectionManager.sharedManager().removeEventListener(Event.CHANGE,onReceived);
//				ConnectionManager.sharedManager().addEventListener(Event.CHANGE,onReceived);
//			}else{
//				ConnectionManager.sharedManager().onClose(this.port);
//			}
			ConnectionManager.sharedManager().open(SerialPortManager.getInstance().port,bitRate);
			openedHandle(this);
			ConnectionManager.sharedManager().removeEventListener(Event.CHANGE,onReceived);
			ConnectionManager.sharedManager().addEventListener(Event.CHANGE,onReceived);	
		}
		
		private var _receiveHandlers:Array=[];
		public function clear(v:String):void{
			var index:int = _ports.indexOf(v);
			_ports.splice(index);
			_receiveHandlers.splice(index);
			
			isFirst = true;
			ParseManager.sharedManager().clearFirmVersion();
		}
		
		public function set_receive_handler(name:String,receiveHandler:Function):void{
			if(receiveHandler!=null){
				for(var i:uint = 0;i<_receiveHandlers.length;i++){
					if(name==_receiveHandlers[i].name){
						_receiveHandlers.splice(i);
						break;
					}
				}
				_receiveHandlers.push({name:name,handler:receiveHandler});
			}
		}
		
		public function setTimer():void {
			trace("setTimer");
			_timerId = setTimeout(function():void{ Main.app.topBarPart.updateVersionUnknown();trace("updateVersionUnknown"); },15000);
		}
		
		public function clearTimer():void {
			trace("clearTimer");
			if (_timerId != 0) {
				clearTimeout(_timerId);
				_timerId = 0;
			}
		}
		
		public function send(bytes:Array):void{
			var buffer:ByteArray = new ByteArray();
			for(var i:uint=0;i<bytes.length;i++){
				buffer.writeByte(bytes[i]);
			}
			ConnectionManager.sharedManager().sendBytes(buffer);
			buffer.clear();
		}
		
		private var _timerId:int = 0;
		private var l:uint = 0;
		private var _receivedBuffer:ByteArray;
		private var _receivedBytes:Array;
		private var isFirst:Boolean = true;
		private function onReceived(evt:Event):void{
			if(_receiveHandlers.length>0){
				_receivedBuffer = ConnectionManager.sharedManager().readBytes();
				if (isFirst && _receivedBuffer.length > 2) {
					ParseManager.sharedManager().queryVersion();
					isFirst = false;
				} else {
					if (ParseManager.sharedManager().isFirmVersionDetected()) {
						ParseManager.sharedManager().parseFirmVersion(_receivedBuffer);
					}
					
					_receivedBytes = [];
					while(_receivedBuffer.bytesAvailable){
						_receivedBytes.push(_receivedBuffer.readUnsignedByte());
					}
	//				trace(bytes)
					if(_receivedBytes.length>0){
	//					l+=receivedBytes.length;
	//					trace("time:",getTimer()-l,_receivedBuffer.length);
	//					l = getTimer();
						for(var i:uint=0;i<_receiveHandlers.length;i++){
							var receiveHandler:Function = _receiveHandlers[i].handler;
							if(receiveHandler!=null){
								try{
									receiveHandler(_receivedBytes);
								}catch(err:*){
									trace(err);
								}
							}
						}
					}
				}
				_receivedBuffer.clear();
			}
		}
		
		public function get connected():Boolean{
			return SerialManager.sharedManager().isConnected;
		}
//		public function close():void{
//			ConnectionManager.sharedManager().close();
//		}
	}
}