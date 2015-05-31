package script{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.8.0 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2014 Drakkashi.com
	 */

	public class Player extends Person{

		private static var player:Player,
						   alias:Array = new Array("player");

		public function Player(instance:String = "player"){
			if (alias.indexOf(instance) < 0)
				alias.push(instance);

			if (!player){
				this.instance = instance;
				setName(instance);
				player = this;
			}
		}

		override public function setGender(str:String):void{
			super.setGender(str);
			if (!image && Interface.getUI())
				Interface.getUI().updatePlayerPortrait();
		}

		override public function setImage(str:String):void{
			super.setImage(str);

			if (Interface.getUI())
				Interface.getUI().updatePlayerPortrait();
		}

		public static function getPlayer(str:String = null):Player{
			if (!str || alias.indexOf(str) >= 0)
				return player;
			return null;
		}

		override public function giveItem(val:*):void{
			super.giveItem(val);
			if (Interface.getUI())
				Interface.getUI().updatePlayerItems();
		}

		override public function takeItem(item:Item):void{
			super.takeItem(item);
			if (Interface.getUI())
				Interface.getUI().updatePlayerItems();
		}

		override public function setVar(id:String,val:*, ... args):String{
			if (id == "start" && toClass(val) == Room)
				Room.setStartingRoom(val);
			else if (id == "start")
				return 'Player property "start" has to be a Room object.';
			else
				return super.setVar(id,val);
			return null;
		}

		public function moveTo(val:*):void{
			var room:Room = (toClass(val) == Array ? val[0] : val);

			if (room)
				Room.setCurrent(room);
		}

		override public function currentRoom():Room{
			return Room.getCurrent();
		}

		override public function getDataArray():Array{
			var arr:Array = super.getDataArray();
			arr.push(toPointer(currentRoom()));
			return arr;
		}

		override public function loadDataArray(arr:Array):void{
			super.loadDataArray(arr);
			moveTo(toRef(arr[10]));
		}

		public static function getIds():Array{
			var idList:Array = new Array();

			for (var i:int = 0; i < alias.length; i++)
				idList.push(alias[i]);
			return idList;
		}

		override public function removeSelf():void{
			player = null;
			alias = new Array();
			super.removeSelf();
		}
	}
}