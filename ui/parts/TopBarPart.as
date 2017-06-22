/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// TopBarPart.as
// John Maloney, November 2011
//
// This part holds the Scratch Logo, cursor tools, screen mode buttons, and more.

package ui.parts {
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	
	import assets.Resources;
	
	import extension2.BoardManager0;
	import extension2.SerialPortManager;
	
	import extensions.ExtensionManager;
	import extensions.ParseManager;
	import extensions.ScratchExtension;
	import extensions.SerialDevice;
	
	import translation.Translator;
	
	import uiwidgets.CursorTool;
	import uiwidgets.IconButton;
	import uiwidgets.Menu;
	import uiwidgets.SimpleTooltips;
	
	import util.ApplicationManager;

	public class TopBarPart extends UIPart {
	
		private var shape:Shape;
		protected var languageButton:IconButton;
	
		protected var fileMenu:IconButton;
		protected var editMenu:IconButton;
	//	protected var examplesMenu:IconButton;
		
		protected var connectMenu:IconButton;
		protected var deviceMenu:IconButton;
//		protected var extensionMenu:IconButton;
		
	//	protected var serialMenu:IconButton;
	//	protected var bluetoothMenu:IconButton;
	//	protected var socketMenu:IconButton;
		protected var shareMenu:IconButton;
		protected var faqMenu:IconButton;
		protected var aboutMenu:IconButton;
		
		private var copyTool:IconButton;
		private var cutTool:IconButton;
		private var growTool:IconButton;
		private var shrinkTool:IconButton;
		private var helpTool:IconButton;
		private var toolOnMouseDown:String;
	
		private var stateNotice:TextField = new TextField;
		private var mcNotice:Sprite = new Sprite;
		private const stateNoticeFormat:TextFormat = new TextFormat(CSS.font, 12, CSS.white, true,null,null,null,null,"right");
	
		public function TopBarPart(app:Main) {
			this.app = app;
			addButtons();
			refresh();
		}
	
		protected function addButtons():void {
			addChild(shape = new Shape());
			addChild(languageButton = new IconButton(app.setLanguagePressed, 'languageButton'));
			languageButton.x = 9;
			languageButton.isMomentary = true;
			addTextButtons();
			addToolButtons();
		}
	
		public static function strings():Array {
			if (Main.app) {
				Main.app.showFileMenu(Menu.dummyButton());
				Main.app.showEditMenu(Menu.dummyButton());
				//MBlock.app.showSerialMenu(Menu.dummyButton());
				Main.app.showExamplesMenu(Menu.dummyButton());
			}
			return ['File', 'Edit', 'Tips', 'Duplicate', 'Delete', 'Grow', 'Shrink', 'Block help', 'Offline Editor'];
		}
	
		protected function removeTextButtons():void {
			if (fileMenu.parent&&connectMenu.parent) {
				removeChild(fileMenu);
				removeChild(editMenu);
	//			removeChild(examplesMenu);
				removeChild(connectMenu);
				removeChild(deviceMenu);
	//			removeChild(serialMenu);
				if(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS){
	//				removeChild(bluetoothMenu);
				}
//				removeChild(extensionMenu);
				if(ApplicationManager.sharedManager().isCatVersion){
					removeChild(shareMenu);
					removeChild(faqMenu);
				}
				removeChild(aboutMenu);
				removeChild(mcNotice);
//				mcNotice.removeEventListener(MouseEvent.CLICK,onClickLink); 
			}
		}
	
		public function updateTranslation():void {
			removeTextButtons();
			addTextButtons();
			updateState();
			refresh();
		}
		public function updateState(state:String = ""):void{
			if (state == "") stateNotice.text = Translator.map("");
			else stateNotice.text = Translator.map(state);
		}
		
		public function updateVersion():void{
			var enabledExtensions:Array = Main.app.extensionManager.enabledExtensions();
			if (enabledExtensions.length > 0) {
				var ext:ScratchExtension = enabledExtensions.pop() as ScratchExtension;
				if(ParseManager.sharedManager().firmVersion !== ext.firmware){
					updateState(Translator.map("Program update required ") + "v" +  ParseManager.sharedManager().firmVersion );
				}else{
					updateState(Translator.map("Latest version ") + "v" +  ParseManager.sharedManager().firmVersion);
				}
			}
		}
		
		public function updateVersionUnknown():void{
			updateState(Translator.map("Program not detected."));
			//updateState(Translator.map("Program not detected! Please upload KamiBot program."));
		}
		
//		public function updateClicker():void{
//			stateNotice.visible = true;
//		}
//		private function onClickLink(evt:MouseEvent):void{
//			setTimeout(updateClicker,2000);
//		}
		public function setWidthHeight(w:int, h:int):void {
			this.w = w;
			this.h = h;
			var g:Graphics = shape.graphics;
			g.clear();
			g.beginFill(CSS.topBarColor);
			g.drawRect(0, 0, w, h);
			g.endFill();
			fixLayout();
		}
	
		protected function fixLayout():void {
			var buttonY:int = 5;
			languageButton.y = buttonY - 1;
	
			// new/more/tips buttons
			const buttonSpace:int = 12;
			var nextX:int = languageButton.x + languageButton.width + 13;
			fileMenu.x = nextX;
			fileMenu.y = buttonY;
			nextX += fileMenu.width + buttonSpace;
	
			editMenu.x = nextX;
			editMenu.y = buttonY;
			nextX += editMenu.width + buttonSpace;
			
	//		examplesMenu.x = nextX;
	//		examplesMenu.y = buttonY;
	//		nextX += examplesMenu.width + buttonSpace;
			
			connectMenu.x = nextX;
			connectMenu.y = buttonY;
			nextX += connectMenu.width + buttonSpace;
	//		if(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS){
	//			bluetoothMenu.x = nextX;
	//			bluetoothMenu.y = buttonY;
	//			nextX += bluetoothMenu.width + buttonSpace;
	//		}
			deviceMenu.x = nextX;
			deviceMenu.y = buttonY;
			nextX += deviceMenu.width + buttonSpace;
			
//			extensionMenu.x = nextX;
//			extensionMenu.y = buttonY;
//			nextX += extensionMenu.width + buttonSpace;
			
			if(ApplicationManager.sharedManager().isCatVersion){
				shareMenu.x = nextX;
				shareMenu.y = buttonY;
				nextX += shareMenu.width + buttonSpace;
				
				faqMenu.x = nextX;
				faqMenu.y = buttonY;
				nextX += faqMenu.width + buttonSpace;
			}
			
			aboutMenu.x = nextX;
			aboutMenu.y = buttonY;
			nextX += aboutMenu.width + buttonSpace;
			// cursor tool buttons
			var space:int = 3;
			copyTool.x = 760+(app.stageIsContracted?ApplicationManager.sharedManager().contractedOffsetX:0);
			cutTool.x = copyTool.right() + space;
			growTool.x = cutTool.right() + space;
			shrinkTool.x = growTool.right() + space;
			//helpTool.x = shrinkTool.right() + space;
			copyTool.y = cutTool.y = shrinkTool.y = growTool.y = 32;//buttonY - 3;
	
			if(mcNotice) {
				mcNotice.x = w - stateNotice.width - 5;
				mcNotice.y = 5;
			}
			stateNotice.defaultTextFormat = stateNoticeFormat;
			stateNotice.selectable = false;
//			stateNotice.visible = false;
		}
	
		public function refresh():void {
			if (app.isOffline) {
				//helpTool.visible = app.isOffline;
			}
			fixLayout();
		}
	
		protected function addTextButtons():void {
			addChild(fileMenu = makeMenuButton('File', app.showFileMenu, true));
			addChild(editMenu = makeMenuButton('Edit', app.showEditMenu, true));
	//		addChild(examplesMenu = makeMenuButton('Examples', app.showExamplesMenu, false));
			addChild(connectMenu = makeMenuButton('Connect',app.showConnectMenu,true));
			if(SerialPortManager.getInstance().port&&SerialPortManager.getInstance().port!=""){
				if(SerialPortManager.getInstance().port.indexOf("COM")>-1||SerialPortManager.getInstance().port.indexOf("/dev/tty.")>-1){
					setConnectedTitle(Translator.map("Serial Port")+" "+Translator.map("Connected"));
				}else if(SerialPortManager.getInstance().port.indexOf("HID")>-1){
					setConnectedTitle(Translator.map("Serial Port")+" "+Translator.map("Connected"));
				}else if(SerialPortManager.getInstance().port.indexOf(" (")>-1){
					setConnectedTitle(Translator.map("Serial Port")+" "+Translator.map("Connected"));
				}
			}
	//		addChild(serialMenu = makeMenuButton(SerialManager.sharedManager().isConnected?(SerialManager.sharedManager().currentPort+" "+Translator.map('Connected')):'Serial Port', app.showSerialMenu, true));
	//		if(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS){
	//			addChild(bluetoothMenu = makeMenuButton(!SerialManager.sharedManager().isBluetoothSupported?"No Bluetooth":(SerialManager.sharedManager().isBluetoothConnected?'Disconnect Bluetooth':'Bluetooth'), app.openBluetooth, false));
	//		}
	//		addChild(socketMenu = makeMenuButton('Network',app.showNetworkMenu,true));
			addChild(deviceMenu = makeMenuButton(Translator.map('Mode')+" ( "+Translator.map(BoardManager0.getInstance().board)+" )",app.showBoardMenu,true));
//			addChild(extensionMenu = makeMenuButton('Extensions',app.showExtensionMenu,true));
			if(ApplicationManager.sharedManager().isCatVersion){
				addChild(shareMenu = makeMenuButton('Share Your Project', app.openShare, false));
				addChild(faqMenu = makeMenuButton('FAQ', app.openFaq, false));
			}
			addChild(aboutMenu = makeMenuButton('Info', app.openAbout, true));
			addChild(mcNotice);
			mcNotice.addChild(stateNotice);
//			mcNotice.addEventListener(MouseEvent.CLICK,onClickLink); 
//			mcNotice.buttonMode = true;
//			mcNotice.useHandCursor = true;
//			mcNotice.mouseChildren = false;
//			mcNotice.mouseEnabled = true;
			stateNotice.visible = true;
			stateNotice.width = 400;
			stateNotice.height = 30;
		}
	
		private function addToolButtons():void {
			function selectTool(b:IconButton):void {
				var newTool:String = '';
				if (b == copyTool) newTool = 'copy';
				if (b == cutTool) newTool = 'cut';
				if (b == growTool) newTool = 'grow';
				if (b == shrinkTool) newTool = 'shrink';
				if (b == helpTool) newTool = 'help';
				if (newTool == toolOnMouseDown) {
					clearToolButtons();
					CursorTool.setTool(null);
				} else {
					clearToolButtonsExcept(b);
					CursorTool.setTool(newTool);
				}
			}
			addChild(copyTool = makeToolButton('copyTool', selectTool));
			addChild(cutTool = makeToolButton('cutTool', selectTool));
			addChild(growTool = makeToolButton('growTool', selectTool));
			addChild(shrinkTool = makeToolButton('shrinkTool', selectTool));
			//addChild(helpTool = makeToolButton('helpTool', selectTool));
	
			SimpleTooltips.add(copyTool, {text: 'Duplicate', direction: 'bottom'});
			SimpleTooltips.add(cutTool, {text: 'Delete', direction: 'bottom'});
			SimpleTooltips.add(growTool, {text: 'Grow', direction: 'bottom'});
			SimpleTooltips.add(shrinkTool, {text: 'Shrink', direction: 'bottom'});
			//SimpleTooltips.add(helpTool, {text: 'Block help', direction: 'bottom'});
		}
	
		public function clearToolButtons():void { clearToolButtonsExcept(null) }
	
		private function clearToolButtonsExcept(activeButton: IconButton):void {
			for each (var b:IconButton in [copyTool, cutTool, growTool, shrinkTool]) {
				if (b != activeButton) b.turnOff();
			}
		}
	
		private function makeToolButton(iconName:String, fcn:Function):IconButton {
			function mouseDown(evt:MouseEvent):void { toolOnMouseDown = CursorTool.tool }
			var onImage:Sprite = toolButtonImage(iconName, 0xcfefff, 1);
			var offImage:Sprite = toolButtonImage(iconName, 0, 0);
			var b:IconButton = new IconButton(fcn, onImage, offImage);
			b.actOnMouseUp();
			b.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown); // capture tool on mouse down to support deselecting
			return b;
		}
	
		private function toolButtonImage(iconName:String, color:int, alpha:Number):Sprite {
			const w:int = 23;
			const h:int = 24;
			var img:Bitmap;
			var result:Sprite = new Sprite();
			var g:Graphics = result.graphics;
			g.clear();
			g.beginFill(color, alpha);
			g.drawRoundRect(0, 0, w, h, 8, 8);
			g.endFill();
			result.addChild(img = Resources.createBmp(iconName));
			img.x = Math.floor((w - img.width) / 2);
			img.y = Math.floor((h - img.height) / 2);
			return result;
		}
	
		protected function makeButtonImg(s:String, c:int, isOn:Boolean):Sprite {
			var result:Sprite = new Sprite();
	
			var label:TextField = makeLabel(Translator.map(s), CSS.topBarButtonFormat, 2, 2);
			label.textColor = CSS.white;
			label.x = 6;
			result.addChild(label); // label disabled for now
	
			var w:int = label.textWidth + 16;
			var h:int = 22;
			var g:Graphics = result.graphics;
			g.clear();
			g.beginFill(c);
			g.drawRoundRect(0, 0, w, h, 8, 8);
			g.endFill();
	
			return result;
		}
		public function setConnectedTitle(title:String):void{
			removeChild(connectMenu);
			addChild(connectMenu = makeMenuButton(title, app.showConnectMenu, true));
//			updateState("Getting Frimware version...");
//			
//			//set time out 3sec
//			var _timeoutTimer:Timer = new Timer(10000,1);
//			_timeoutTimer.addEventListener(TimerEvent.TIMER,function (e:TimerEvent):void {
//				Main.app.topBarPart.updateVersion();
//			});
//			_timeoutTimer.start();
			
			this.fixLayout();
		}
		public function setBoardTitle():void{
			removeChild(deviceMenu);
			addChild(deviceMenu = makeMenuButton(Translator.map('Mode')+" ( "+Translator.map(BoardManager0.getInstance().board)+" )",app.showBoardMenu,true));
			this.fixLayout();
		}
	//	public function setSocketConnectedTitle(title:String):void{
	//		removeChild(socketMenu);
	//		addChild(socketMenu = makeMenuButton(title, app.showNetworkMenu, true));
	//		this.fixLayout();
	//	}
	//	public function setBluetoothTitle(connected:Boolean):void{
	//		if(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS){
	//			removeChild(bluetoothMenu);
	//			addChild(bluetoothMenu = makeMenuButton(!SerialManager.sharedManager().isBluetoothSupported?"No Bluetooth":(connected?"Disconnect Bluetooth":"Bluetooth"), app.openBluetooth, false));
	//		}
	//		this.fixLayout();
	//	}
		public function setDisconnectedTitle():void{
			removeChild(connectMenu);
			addChild(connectMenu = makeMenuButton('Connect', app.showConnectMenu, true));
			updateState("");
			this.fixLayout();
		}
	//	public function setSocketDisconnectedTitle():void{
	//		removeChild(socketMenu);
	//		addChild(socketMenu = makeMenuButton('Network', app.showNetworkMenu, true));
	//		this.fixLayout();
	//	}
	}
}
