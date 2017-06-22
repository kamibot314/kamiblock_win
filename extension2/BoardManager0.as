package extension2
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.setTimeout;
	
	import extensions.ConnectionManager;
	import extensions.SerialDevice;
	
	import util.JSON;
	import util.SharedObjectManager;
	
	public class BoardManager0
	{
		private static var instance:BoardManager0 = new BoardManager0();
		private static var json:Object;
		
		private var _board:String;
		
		public static function getInstance():BoardManager0
		{
			return instance;
		}
		
		public function BoardManager0()
		{
			_board = SharedObjectManager.sharedManager().getObject("board","KamiBot");
			json = util.JSON.parse(readFile());
			if (boardData == null) {
				_board = "KamiBot";
				SharedObjectManager.sharedManager().setObject("board",_board);
			}
		}
		
		public function onSelectBoard(board:String):void{
			_board = board.toString();
			SharedObjectManager.sharedManager().setObject("board",board);
			Main.app.topBarPart.setBoardTitle();
			
			var success:Boolean = false;
			trace(board);
			if (board.indexOf("Arduino") !== -1) {
				success = Main.app.extensionManager.loadExtension("Arduino");
			} else {
				success = Main.app.extensionManager.loadExtension(board);
				if (!success) {
					trace("Extension " + board + " cannot found Defalut Extension Arduino will be load");
					success = Main.app.extensionManager.loadExtension("Arduino");
					if (!success) {
						trace("Default Extension Arduino cannot load check Extension Dir");
					}
				}
			}
			if(success && SerialDevice.sharedDevice().connected){
				setTimeout(ConnectionManager.sharedManager().onReOpen,1000);
			}
		}
		
		private function readFile() : String
		{
			var myFile:File = File.applicationDirectory.resolvePath("js\\board.json");
			var fileStream:FileStream = new FileStream();
			fileStream.open(myFile, FileMode.READ);
			
			var fileContents:String = fileStream.readUTFBytes(fileStream.bytesAvailable);
			var ret:String = fileContents;
			
			fileStream.close();
			
			return ret;
		}
		
		public function get listBoard() : Array
		{
			var ret:Array = new Array;
			
			for(var i:Object in json) {
				var value:Object = json[i];
				ret.push(value["name"]);
			}
			return ret;
		}
		
		public function get listProcessor() : Array
		{
			var ret:Array = new Array;
			var mcu:Object = boardData["mcu"];
			for(var i:Object in mcu) {
				var value:Object = mcu[i];
				ret.push(value["name"]);
			}
			return ret;
		}
		
		public function set board(board:String) : void
		{
			trace("BoardManager0 set board = " + board);
			SharedObjectManager.sharedManager().setObject("board",_board);
			_board = board;
		}
		
		public function get board() : String
		{
			return _board;
		}
		
		public function get boardData() : Object
		{
			if (_board == null ) throw new Error();
			
			for(var i:Object in json) {
				var value:Object = json[i];
				if (value["name"] == _board) return value; 
			}
			return null;
		}
		
		public function check(board:String):Boolean 
		{
			return (_board == board);
		}
	}
}