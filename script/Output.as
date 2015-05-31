package script{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.6.1 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2014 Drakkashi.com
	 */

	import flash.events.Event;
	import flash.net.LocalConnection;
	import flash.events.StatusEvent;

	public class Output{
		
		private static var outputList:Array = new Array(),
						   conn:LocalConnection = new LocalConnection();

		private var str:String,
					index:int;
		
		public function Output(str:String,i:int = 0){
			this.str = str;
			index = i;
		}
		
		public function toString():String{
			return str;
		}

		public function getIndex():int{
			return index;
		}

		public function appendIndex(i:int):Output{
			if (i > 0)
				index += i;
			return this;
		}

		public static function initConsole():void{
			conn.addEventListener(StatusEvent.STATUS,function():void {});
			conn.send("consoleStream", "reset");
		}

		public static function print(str:String):void{
			trace(str);
			conn.send("consoleStream", "update", str);
		}

		public static function warn(str:String, dir:String = null, line:int = -1):void{
			if (str){
				if (dir){
					trace("[" + dir + (line >= 0 ? ", Line " + line : "") + "] Warning: " + str);
					conn.send("consoleStream", "update", "Warning: " + str, dir + (line >= 0 ? ", Line " + line : ""));
				}
				else
					print("Warning: " + str);
			}
		}

		public static function err(str:String, dir:String = null, line:int = -1):void{
			if (str){
				if (dir){
					trace("[" + dir + (line >= 0 ? ", Line " + line : "") + "] Error: " + str);
					conn.send("consoleStream", "update", "Error: " + str, dir + (line >= 0 ? ", Line " + line : ""));
				}
				else
					print("Error: " + str);
			}
		}
	}
}