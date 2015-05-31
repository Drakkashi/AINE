package script{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.7.1 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2014 Drakkashi.com
	 */

	public class Nav{
		
		private static var list:Array = new Array();

		private var room:Room,
					paths:Array = new Array();
		
		public function Nav(room:Room){
			this.room = room;
			list.push(this);
		}

		public function toString():String{
			return String(room);
		}

		public function getPaths():Array{
			var list:Array = new Array();
			
			for (var i:int = 0; i < paths.length; i++)
				list[i] = (paths[i] ? paths[i].getRoom() : null);

			return list;
		}

		public function getPath(i:int):Nav{
			return paths[i];
		}

		public function getRoom(i:int = -1):Room{
			if (i < 0)
				return room;
			else{
				var path:Nav = getPath(i);
				if (path)
					return path.getRoom();
				return null;
			}
		}

		public function setPath(id:*,val:String,b:Boolean = false):void{
			var index:Number = (isNaN(id) ? pathIndex(id) : id),
				nav:Nav = (val ? getNav(trim(val)) : null);

			if (index >= 0){
				if (!nav && paths[index] && b)
					paths[index].setPath(reversedIndex(index),null);

				paths[index] = nav;

				if (nav && b)
					nav.setPath(reversedIndex(index),String(room));
			}
		}

		private static function reversedIndex(i:int):int{
			return (i > 7 ? (i > 9 ? 10 : 8)+(i+1)%2 : (i+4)%8);
		}

		public static function pathIndex(str:String):int{
			var index:int = -1;
			if (str){
				str = trim(str).toLowerCase();
				var paths:Array = new Array(
										new Array("north","northeast","east","southeast","south","southwest","west","northwest","up","down","in","out"),
										new Array("n","ne","e","se","s","sw","w","nw"),
										new Array("forward",null,"right",null,"back",null,"left"),
										new Array("forth")
									);
					
				for (var i:int = 0; i < paths.length && index < 0; i++)
					index = paths[i].indexOf(str);
			}
			return index;
		}

		public static function getNav(room:*):Nav{
			if (!empty(String(room))){
				for each(var nav:Nav in list)
					if (String(nav) == String(room))
						return nav;
			}
			return null;
		}

		public function getDataArray():Array{
			var arr:Array = cloneArray(paths);
			for (var i:int = 0; i < arr.length; i++)
				if (arr[i])
					arr[i] = String(arr[i]);

			return arr;
		}

		private static function cloneArray(array:Object):Array {
			return array.concat();
		}

		private static function empty(str:String):Boolean{
			return !str || str.length == 0;
		}

		private static function trim(str:String):String{
			return str.replace(/^\s+|\s+$/g, "");
		}
		
		public static function clearList():void{
			list = new Array();
		}
	}
}