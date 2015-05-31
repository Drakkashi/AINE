package script{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.8.0 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2014 Drakkashi.com
	 */

	import flash.display.Bitmap;
	import flash.events.Event;

	public class Character extends Person{

		private static var list:Array = new Array();

		private var bitmap:Bitmap;

		public function Character(instance:String){
			this.instance = instance;
			setName(instance);
			addEventListener(Event.ADDED_TO_STAGE, showImage);
			addEventListener(Event.REMOVED_FROM_STAGE, hideImage);
			imageHolder.gotoAndStop(1);
			list.push(this);
		}

		override public function setGender(str:String):void{
			super.setGender(str);
			if (!image && parent)
				showImage();
		}

		override public function setImage(str:String):void{
			super.setImage(str);
			if (parent)
				showImage();
		}

		public function showImage(e:Event = null):void{
			hideImage();
			bitmap = Image.getImage(image);
			if (bitmap){
				if (bitmap.width / 72.6 > bitmap.height / 92.6){
					bitmap.height = bitmap.height/bitmap.width*72.6;
					bitmap.width = 72.6;
				}
				else{
					bitmap.width = bitmap.width/bitmap.height*92.6;
					bitmap.height = 92.6;
				}

				bitmap.x = 3.7 + (72.6-bitmap.width)/2;
				bitmap.y = 3.7 + (92.6-bitmap.height)/2;
				imageHolder.gotoAndStop(1);
				imageHolder.addChild(bitmap);
			}
			else {
				if (gender && gender.toLowerCase() == "male")
					imageHolder.gotoAndStop(2);
				else if (gender && gender.toLowerCase() == "female")
					imageHolder.gotoAndStop(3);
				else
					imageHolder.gotoAndStop(1);
			}
		}

		public function hideImage(e:Event = null):void{
			if (bitmap && bitmap.parent)
				bitmap.parent.removeChild(bitmap);
			bitmap = null;
			imageHolder.gotoAndStop(1);
		}

		public function setCurrent(room:Room):void{
			remove();
			current = room;
		}

		public function remove():void{
			if (current)
				current.removeCharacter(this);
			current = null;
		}

		public function moveTo(val:*):void{
			var room:Room = (toClass(val) == Array ? val[0] : val);

			if (room)
				room.giveCharacter(this);
		}

		override public function getMethods():Array{
			return super.getMethods().concat(new Array("remove"));
		}

		public static function getCharacter(str:String):Character{
			for (var i:int = 0; i < list.length; i++)
				if (list[i].instance == str)
					return list[i];
			return null;
		}

		public static function count():int{
			return list.length;
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

		public static function resetChars():void{
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