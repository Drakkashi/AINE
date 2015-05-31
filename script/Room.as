package script{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.8.0 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2014 Drakkashi.com
	 */

	public class Room extends Container{

		private static var current:Room,
						   starting:Room,
						   list:Array = new Array();

		private var nav:Nav,
					charList:Array = new Array();

		public function Room(instance:String = null){
			if (instance)
				this.instance = instance;
			else{
				var i:int = 0;
				do{
					this.instance = "room"+i++;
				}
				while(_Object.getObject(this.instance));
			}

			setName(this.instance);
			nav = new Nav(this);
			list.push(this);
		}

		public function hasCharacter(char:Character):Boolean{
			return charList.indexOf(char) >= 0;
		}

		override public function setName(str:String):void{
			super.setName(str);
			if (this == getCurrent() && Interface.getUI())
				Interface.getUI().updateRoomName();
		}

		override public function setImage(str:String):void{
			super.setImage(str);
			if (this == getCurrent() && Interface.getUI())
				Interface.getUI().updateRoomImage();
		}

		public function allObjects():Array{
			var list:Array = new Array(),
				player = (getCurrent() == this ? Player.getPlayer() : null);

			if (player)
				list.push(player);

			list.push(this);
			list = list.concat(getChars());
			
			if (player)
				list = list.concat(player.getItems());

			list = list.concat(getItems());

			for (var i:int = 0; i < charList.length; i++)
				list = list.concat(charList[i].getItems());

			return list;
		}

		public function enterRoom():void{
			_Event.eventLeaveRoom(this);
		}

		public function setPath(args:Array):void{
			var room:Room = (args.length > 1 ? args[1] : null);
			nav.setPath(args[0],String(room),(args.length > 2 ? args[2] : false));

			if (this == current || room == current)
				Interface.getUI().updateNav();
		}

		public function getPaths():Array{
			return nav.getPaths();
		}

		public function getPath(index:int):Room{
			return nav.getRoom(index);
		}

		public function getNav():Nav{
			return nav;
		}

		public static function setCurrent(room:Room):void{
			if (room && room != current){
				current = room;

				if (Interface.getUI())
					Interface.getUI().updateRoom();
			}
		}
		
		public static function getCurrent():Room{
			return current;
		}
		
		public static function setStartingRoom(room:Room = null):void{
			if (room)
				starting = room;
			else
				starting = list[0];
			setCurrent(starting);
		}
		
		public static function getStartingRoom():Room{
			return starting;
		}

		public static function count():int{
			return list.length;
		}

		public static function getRoom(str:String):Room{
			for (var i:int = 0; i < list.length; i++)
				if (list[i].instance == str)
					return list[i];
			return null;
		}

		override public function setVar(id:String,val:*, ... args):String{
			if (id == "chars"){
				if (toClass(val) == Character || toClass(val) == Array){

					if (toClass(val) == Array){
						var list:Array = val;
						for (var i:int = 0; i < list.length; i++){
							if (list[i] != null && toClass(list[i]) != Character){
								return 'Invalid entry in list. All entries has to be a Character object.';
								break;
							}
						}
						
						for (i = 0; i < list.length; i++)
							if (list[i])
								giveCharacter(list[i]);
					}
					else
						giveCharacter(val);
				}
				else if (val)
					return 'Room property "chars" has to be a Character object or a List.';
			}
			else if (Nav.pathIndex(id) >= 0){
				if (toClass(val) == Room)
					nav.setPath(id,val,args[0]);
				else
					return 'Navigation path can only point towards a ' + (toClass(val) == Array ? "single " : "") + 'Room object';
			}
			else
				return super.setVar(id,val);
			return null;
		}

		override public function hasVar(str:String):Boolean{
			return super.hasVar(str) || str == "chars" || Nav.pathIndex(str) >= 0;
		}

		override public function getVar(str:String):*{
			if (str == "chars")
				return getChars();
			var i:int = Nav.pathIndex(str);
			if (i >= 0)
				return getNav().getRoom(i);
			return super.getVar(str);
		}

		override public function giveItem(val:*):void{
			super.giveItem(val);
			if (this == getCurrent() && Interface.getUI())
				Interface.getUI().updateRoomItems();
		}

		override public function takeItem(item:Item):void{
			super.takeItem(item);
			if (this == getCurrent() && Interface.getUI())
				Interface.getUI().updateRoomItems();
		}

		public function giveCharacter(char:Character):void{
			if (charList.indexOf(char) < 0){
				char.setCurrent(this);
				charList.push(char);

				if (this == getCurrent() && Interface.getUI())
					Interface.getUI().updateCharList();
			}
		}

		public function removeCharacter(char:Character):void{
			if (char && hasCharacter(char)){
				charList.splice(charList.indexOf(char),1);

				if (this == getCurrent() && Interface.getUI())
					Interface.getUI().updateCharList();
			}
		}

		public function setChars(args:Array):void{
			var list:Array = args[0];
			while(charList.length > 0)
				charList[0].remove();

			for (var i:int = 0; i < list.length; i++)
				giveCharacter(list[i]);
		}

		public function getChars():Array{
			return cloneArray(charList);
		}

		override public function getDataArray():Array{
			var arr:Array = super.getDataArray();
			arr.push(toPointer(getChars()));
			arr.push(nav.getDataArray());
			return arr;
		}

		override public function loadDataArray(arr:Array):void{
			super.loadDataArray(arr);
			setChars(new Array(toRef(arr[9])));
			for (var i:int = 0; i < arr[10].length; i++)
				if (arr[10][i])
					nav.setPath(i,arr[10][i]);
		}

		override public function getMethods():Array{
			return super.getMethods().concat(new Array("setPath","getPath","getPaths","getChars",'enterRoom','allObjects','setChars'));
		}

		override public function getListeners():Array{
			return super.getListeners().concat(new Array("Nav_Over","Nav_Out","Nav_Click"));
		}

		public static function getIds():Array{
			var idList:Array = new Array();

			for (var i:int = 0; i < list.length; i++)
				idList.push(list[i].getInstance());
			return idList;
		}

		public static function getList():Array{
			return cloneArray(list);
		}

		override public function reset():void{
			super.reset();
			/*
			 *	RESET NAV
			 */
		}

		public static function resetRooms():void{
			for (var i:int = 0; i < list.length; i++)
				list[i].reset();
		}

		public static function clearList():void{
			for (var i:int = 0; i < list.length; i++)
				list[i].removeSelf();

			list = new Array();
			current = null;
			starting = null;
		}
	}
}