package script{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.8.0 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2014 Drakkashi.com
	 */

	public class Container extends _Object{

		protected var itemList:Array = new Array();

		public function giveItem(val:*):void{
			var item:Item = (toClass(val) == Array ? val[0] : val);

			if (item && itemList.indexOf(item) < 0){
				item.setContainer(this);
				itemList.push(item);
			}
		}

		public function takeItem(item:Item):void{
			if (item && hasItem(item))
				itemList.splice(itemList.indexOf(item),1);
		}

		public function hasItem(val:*):Boolean{
			var item:Item = (toClass(val) == Array ? val[0] : val);
			return item && itemList.indexOf(item) >= 0;
		}

		public function setItems(args:Array):void{
			var list:Array = args[0];
			while(itemList.length > 0)
				itemList[0].remove();

			for (var i:int = 0; i < list.length; i++)
				giveItem(list[i]);
		}

		public function getItems():Array{
			return cloneArray(itemList);
		}

		override public function setVar(id:String,val:*, ... args):String{
			if (id == "items"){
				if (toClass(val) == Item || toClass(val) == Array){

					if (toClass(val) == Array){
						var list:Array = val;
						for (var i:int = 0; i < list.length; i++){
							if (list[i] != null && toClass(list[i]) != Item){
								return 'Invalid entry in list. All entries has to be an Item object.';
								break;
							}
						}
						
						for (i = 0; i < list.length; i++)
							if (list[i])
								giveItem(list[i]);
					}
					else
						giveItem(val);
				}
				else if (val)
					return String(this.getClass()).toUpperCase()+' property "items" has to be an Item object or a List.';
			}
			else
				return super.setVar(id,val);
			return null;
		}

		override public function loadDataArray(arr:Array):void{
			super.loadDataArray(arr);
			setItems(new Array(toRef(arr[8])));
		}

		override public function getDataArray():Array{
			var arr:Array = super.getDataArray();
			arr.push(toPointer(getItems()));
			return arr;
		}

		override public function hasVar(str:String):Boolean{
			return super.hasVar(str) || str == "items";
		}

		override public function getVar(str:String):*{
			if (str == "items")
				return getItems();
			return super.getVar(str);
		}

		override public function getMethods():Array{
			return super.getMethods().concat(new Array("giveItem","hasItem",'getItems','setItems'));
		}
	}
}