// arduino.js

(function(ext) {
	var idDict = [];
	var genNextID = function(realId, args){
		var nextID = (((args[0] << 4) | args[1]) % 0xff);
		idDict[nextID] = realId;
		return nextID;
	}
    var device = null;
    var _rxBuf = [];

    // Sensor states:
    var ports = {
        Port1: 1,
        Port2: 2,
        Port3: 3,
        Port4: 4,
        Port5: 5,
        Port6: 6,
        Port7: 7,
        Port8: 8,
		M1:9,
		M2:10
    };
    
	var pins = {
		"LEFT_MOTOR_SPEED_PIN":19,
		"LEFT_MOTOR_DIR1_PIN":21,
		"LEFT_MOTOR_DIR2_PIN":20,
		"RIGHT_MOTOR_SPEED_PIN":24,
		"RIGHT_MOTOR_DIR1_PIN":22,
		"RIGHT_MOTOR_DIR2_PIN":23,
		"IR_LEFT1_PIN":16,
		"IR_LEFT2_PIN":26,
		"IR_CENTER_PIN":5,
		"IR_RIGHT2_PIN":17,
		"IR_RIGHT1_PIN":4,
		"IR_SENSOR_ON":3,
		"RGB_RED_PIN":11,
		"RGB_GREEN_PIN":27,
		"RGB_BLUE_PIN":6,
		"UTRASONIC_TRIG_PIN":10,
		"UTRASONIC_ECHO_PIN":12,
		"SERVO_MOTOR_PIN":7,
		"BUZZER_PIN":13,
		"BATTERY_PIN":"A0"
	};
	
	var slots = {
		Slot1:1,
		Slot2:2
	};
	var switchStatus = {
		On:1,
		Off:0
	};
	var levels = {
		HIGH:1,
		LOW:0
	};
	var shutterStatus = {
		Press:0,
		Release:1,
		'Focus On':2,
		'Focus Off':3,
	};
	var axis = {
		'X-Axis':1,
		'Y-Axis':2,
		'Z-Axis':3
	}
	var tones ={"B0":31,"C1":33,"D1":37,"E1":41,"F1":44,"G1":49,"A1":55,"B1":62,
			"C2":65,"D2":73,"E2":82,"F2":87,"G2":98,"A2":110,"B2":123,
			"C3":131,"D3":147,"E3":165,"F3":175,"G3":196,"A3":220,"B3":247,
			"C4":262,"D4":294,"E4":330,"F4":349,"G4":392,"A4":440,"B4":494,
			"C5":523,"D5":587,"E5":659,"F5":698,"G5":784,"A5":880,"B5":988,
			"C6":1047,"D6":1175,"E6":1319,"F6":1397,"G6":1568,"A6":1760,"B6":1976,
			"C7":2093,"D7":2349,"E7":2637,"F7":2794,"G7":3136,"A7":3520,"B7":3951,
	"C8":4186,"D8":4699};
	var beats = {"Half":500,"Quater":250,"Eighth":125,"Whole":1000,"Double":2000,"Zero":0};
	var IR = {
				"No.1":pins["IR_LEFT1_PIN"],
				"No.2":pins["IR_LEFT2_PIN"],
				"No.3":pins["IR_CENTER_PIN"],
				"No.4":pins["IR_RIGHT2_PIN"],
				"No.5":pins["IR_RIGHT1_PIN"]};
	var colors = {"Red":4,
	"Pink":5,
	"Blue":1,
	"Green":2,
	"Sky Blue":3,
	"Yellow":6};
	var direction = {
		"forward":0,
		"backward":1
	}
	var values = {};
	var indexs = [];
	
	var startTimer = 0;
	var versionIndex = 0xFA;
    ext.resetAll = function(){
    	device.send([0xff, 0x55, 2, 0, 4]);
    };
	
	ext.runArduino = function(){
	};
	
	ext.runMoveForward = function(speed){
		runPackage(90,speed);
	};
	
	ext.runMoveForwardBalanced = function(speed1,speed2){
		runPackage(96,speed1,speed2);
	};
	
	ext.runMoveLeft = function(speed){
		runPackage(91,speed);
	};
	
	ext.runMoveRight = function(speed){
		runPackage(92,speed);
	};
	
	ext.runMoveBackward = function(speed){
		runPackage(93,speed);
	};
	
	ext.runMoveBackwardBalanced = function(speed1,speed2){
		runPackage(97,speed1,speed2);
	};
	
	ext.runStop = function(){
		runPackage(94);
	};
	
	ext.runRotateLeftMoter = function(dir, speed){
		runPackage(98, direction[dir], speed);
	};
	
	ext.runRotateRightMoter = function(dir, speed){
		runPackage(99, direction[dir], speed);
	};
	//
    //runRotateLeftMoter
	ext.setRGbLed = function(rgb){
		if (typeof rgb != "string") rgb = 0;
		else rgb = colors[rgb];
		runPackage(95,rgb);
	};
	
	ext.runServo = function(angle){
		//2016/12/23 이승훈
		runPackage(33,pins["SERVO_MOTOR_PIN"],180-angle);
	};
	
	ext.runTone = function(tone,beat){
		runPackage(34,pins["BUZZER_PIN"],short2array(typeof tone=="number"?tone:tones[tone]),short2array(typeof beat=="number"?beat:beats[beat]));
	};
	
	ext.getBattery = function(nextID){
		var deviceId = 31;
		nextID = genNextID(nextID, [pins["BATTERY_PIN"]]);
		getPackage(nextID,deviceId,pins["BATTERY_PIN"]);
	};
	
	ext.getUltraSonic = function(nextID){
		var deviceId = 1;
		nextID = genNextID(nextID, [pins["UTRASONIC_TRIG_PIN"],pins["UTRASONIC_ECHO_PIN"]]);
		getPackage(nextID,deviceId,pins["UTRASONIC_TRIG_PIN"],pins["UTRASONIC_ECHO_PIN"]);
	};
	
	ext.getIR = function(nextID,pin){
		var deviceId = 13;
		nextID = genNextID(nextID, [pin]);
		getPackage(nextID,deviceId,pin);
	};
	
	function runPackage(){
		var bytes = [];
		bytes.push(0xff);
		bytes.push(0x55);
		bytes.push(0);
		bytes.push(0);
		bytes.push(2);
		for(var i=0;i<arguments.length;i++){
			if(arguments[i].constructor == "[class Array]"){
				bytes = bytes.concat(arguments[i]);
			}else{
				bytes.push(arguments[i]);
			}
		}
		bytes[2] = bytes.length-3;
		device.send(bytes);
	}
	
	var getPackDict = [];
	function resetPackDict(nextID){
		getPackDict[nextID] = false;
	}
	function getPackage(){
		var nextID = arguments[0];
		if(getPackDict[nextID]){
			return;
		}
		getPackDict[nextID] = true;
		setTimeout(resetPackDict, 0, nextID);

		var bytes = [0xff, 0x55];
		bytes.push(arguments.length+1);
		bytes.push(nextID);
		bytes.push(1);
		for(var i=1;i<arguments.length;i++){
			bytes.push(arguments[i]);
		}
		device.send(bytes);
	}

    var inputArray = [];
	var _isParseStart = false;
	var _isParseStartIndex = 0;
    function processData(bytes) {
		var len = bytes.length;
		if(_rxBuf.length>30){
			_rxBuf = [];
		}
		for(var index=0;index<bytes.length;index++){
			var c = bytes[index];
			_rxBuf.push(c);
			if(_rxBuf.length>=2){
				if(_rxBuf[_rxBuf.length-1]==0x55 && _rxBuf[_rxBuf.length-2]==0xff){
					_isParseStart = true;
					_isParseStartIndex = _rxBuf.length-2;
				}
				if(_rxBuf[_rxBuf.length-1]==0xa && _rxBuf[_rxBuf.length-2]==0xd&&_isParseStart){
					_isParseStart = false;
					
					var position = _isParseStartIndex+2;
					var extId = _rxBuf[position];
					position++;
					var type = _rxBuf[position];
					position++;
					//1 byte 2 float 3 short 4 len+string 5 double
					var value;
					switch(type){
						case 1:{
							value = _rxBuf[position];
							position++;
						}
							break;
						case 2:{
							value = readFloat(_rxBuf,position);
							position+=4;
							if(value<-255||value>1023){
								value = 0;
							}
						}
							break;
						case 3:{
							value = readShort(_rxBuf,position);
							position+=2;
						}
							break;
						case 4:{
							var l = _rxBuf[position];
							position++;
							value = readString(_rxBuf,position,l);
						}
							break;
						case 5:{
							value = readDouble(_rxBuf,position);
							position+=4;
						}
							break;
					}
					if(type<=5){
						extId = idDict[extId];
						if(values[extId]!=undefined){
							responseValue(extId,values[extId](value));
						}else{
							responseValue(extId,value);
						}
						values[extId] = null;
					}
					_rxBuf = [];
				}
			} 
		}
    }
	function readFloat(arr,position){
		var f= [arr[position],arr[position+1],arr[position+2],arr[position+3]];
		return parseFloat(f);
	}
	function readShort(arr,position){
		var s= [arr[position],arr[position+1]];
		return parseShort(s);
	}
	function readDouble(arr,position){
		return readFloat(arr,position);
	}
	function readString(arr,position,len){
		var value = "";
		for(var ii=0;ii<len;ii++){
			value += String.fromCharCode(_rxBuf[ii+position]);
		}
		return value;
	}
    function appendBuffer( buffer1, buffer2 ) {
        return buffer1.concat( buffer2 );
    }

    // Extension API interactions
    var potentialDevices = [];
    ext._deviceConnected = function(dev) {
        potentialDevices.push(dev);

        if (!device) {
            tryNextDevice();
        }
    }

    function tryNextDevice() {
        // If potentialDevices is empty, device will be undefined.
        // That will get us back here next time a device is connected.
        device = potentialDevices.shift();
        if (device) {
            device.open({ stopBits: 0, bitRate: 57600, ctsFlowControl: 0 }, deviceOpened);
        }
    }

    var watchdog = null;
    function deviceOpened(dev) {
        if (!dev) {
            // Opening the port failed.
            tryNextDevice();
            return;
        }
        device.set_receive_handler('kamibot',processData);
    };

    ext._deviceRemoved = function(dev) {
        if(device != dev) return;
        device = null;
    };

    ext._shutdown = function() {
        if(device) device.close();
        device = null;
    };

    ext._getStatus = function() {
        if(!device) return {status: 1, msg: 'KamiBot disconnected'};
        if(watchdog) return {status: 1, msg: 'Probing for KamiBot'};
        return {status: 2, msg: 'KamiBot connected'};
    }

    var descriptor = {};
	ScratchExtensions.register('kamibot', descriptor, ext, {type: 'serial'});
})({});
