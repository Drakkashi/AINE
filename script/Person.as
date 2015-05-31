package script{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.8.0 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2014 Drakkashi.com
	 */

	public class Person extends Container{

		protected var current:Room,
					  gender:String;

		public function setGender(str:String):void{
			gender = str;
		}

		public function getGender():String{
			return gender;
		}

		public function currentRoom():Room{
			return current;
		}

		override public function hasVar(str:String):Boolean{
			return super.hasVar(str) || str == "gender";
		}

		override public function getVar(str:String):*{
			if (str == "gender")
				return getGender();
			return super.getVar(str);
		}

		override public function setVar(id:String,val:*, ... args):String{
			var str:String = (toClass(val) == Array ? listToStr(val) : null);

			if (id == "gender"){
				if (val == null)
					setGender(null);
				else
					setGender((str ? str : String(val)));
			}
			else
				return super.setVar(id,val);
			return null;
		}

		public function dropItems():void{
			var room:Room = this.currentRoom();

			if (room){
				while(itemList.length > 0)
					room.giveItem(itemList[0]);
			}
			else{
				while(itemList.length > 0)
					itemList[0].remove();
			}
		}

		public function dropItem(val:* = null):void{
			var item:Item = (toClass(val) == Array ? val[0] : val),
				room:Room = this.currentRoom();

			if (item){
				if (itemList.indexOf(item) >= 0 && room)
					room.giveItem(item);
				else if (itemList.indexOf(item) >= 0)
					item.remove();
			}
		}

		override public function reset():void{
			super.reset();
			gender = null;
		}

		override public function loadDataArray(arr:Array):void{
			super.loadDataArray(arr);
			setGender(arr[9]);
		}

		override public function getDataArray():Array{
			var arr:Array = super.getDataArray();
			arr.push(gender);
			return arr;
		}

		override public function getMethods():Array{
			return super.getMethods().concat(new Array("setGender","getGender","dropItem","dropItems","moveTo","currentRoom"));
		}
	}
}