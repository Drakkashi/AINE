package script{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.8.0 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2014 Drakkashi.com
	 */

	public class GenericObject extends _Object{

		private static var list:Array = new Array();

		public function GenericObject(instance:String){
			this.instance = instance;
			setName(instance);
			list.push(this);
		}

		public static function getIds():Array{
			var idList:Array = new Array();

			for (var i:int = 0; i < list.length; i++)
				idList.push(list[i].getInstance());
			return idList;
		}

		public static function getObject(str:String):GenericObject{
			for (var i:int = 0; i < list.length; i++)
				if (list[i].instance == str)
					return list[i];
			return null;
		}

		public static function resetObjects():void{
			for (var i:int = 0; i < list.length; i++)
				list[i].reset();
		}

		public static function getList():Array{
			return cloneArray(list);
		}

		public static function clearList():void{
			for (var i:int = 0; i < list.length; i++)
				list[i].removeSelf();
			list = new Array();
		}
	}
}