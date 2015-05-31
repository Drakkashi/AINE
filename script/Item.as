package script{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.8.0 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2014 Drakkashi.com
	 */

	public class Item extends _Object{

		private static var list:Array = new Array();

		private var container:Container;

		public function Item(instance:String){
			this.instance = instance;
			setName(instance);
			x = 7.75;
			list.push(this);
		}

		public function moveTo(val:*):void{
			var obj:Container = (toClass(val) == Array ? val[0] : val);

			if (obj)
				obj.giveItem(this);
		}

		public static function count():int{
			return list.length;
		}

		override public function setName(str:String):void{
			super.setName(str);
			if (Interface.getUI()){
				if (container == Player.getPlayer())
					Interface.getUI().updatePlayerItems();
				else if (container == Room.getCurrent())
					Interface.getUI().updateRoomItems();
			}
		}

		public function setContainer(container:Container):void{
			remove();
			this.container = container;
		}

		public function remove():void{
			if (container)
				container.takeItem(this);
			container = null;
		}

		public function currentRoom():Container{
			if (container){
				if (container.getClass() == Room)
					return container;
				if (container.getClass() == Player)
					return Room.getCurrent();
				else
					return (container as Character).currentRoom();
			}
			return null;
		}

		public static function getItem(str:String):Item{
			for (var i:int = 0; i < list.length; i++)
				if (list[i].instance == str)
					return list[i];
			return null;
		}

		override public function getMethods():Array{
			return super.getMethods().concat(new Array("currentRoom","moveTo","remove"));
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
			remove();
		}

		public static function resetItems():void{
			for (var i:int = 0; i < list.length; i++)
				list[i].reset();
		}

		public static function clearList():void{
			for (var i:int = 0; i < list.length; i++)
				list[i].removeSelf();
			list = new Array();
		}
	}
}