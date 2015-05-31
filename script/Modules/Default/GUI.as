package script.Modules.Default{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.9.0 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2015 Drakkashi.com
	 */

	import script.*;
	import script.Modules.Listeners.GameListener;
	import script.Modules.Listeners.RoomListener;
	import flash.display.MovieClip;
	import flash.net.SharedObject;
	import flash.events.Event;
	import flash.display.Bitmap;

	public class GUI extends MovieClip implements GameListener, RoomListener{
		
		private static var player:Boolean = true,
						   roomTitle:Boolean = true,
						   roomItems:Boolean = true,
						   chars:Boolean = true,
						   nav:Boolean = true,
						   navCurrent:String,
						   navDefault:String,
						   objList:Array,
						   imageList:Array = new Array(new Array(),new Array(),new Array());
		
		public function GUI(){
			addEventListener(Event.ENTER_FRAME,loop);
		}

		public function _new():void{
			playerVisible(true);
			roomTitleVisible(true);
			roomItemsVisible(true);
			charsVisible(true);
			navVisible(true);
			setNav(navDefault);
			objList = null;
			clearList();
		}

		public function _save(dir:String):void{
			var so:SharedObject = SharedObject.getLocal(dir),
				pointerList:Array = (objList ? new Array(new Array(),new Array()) : null );

			if (pointerList)
				for (var i:int = 0; i < objList[0].length; i++){
					pointerList[0].push(new Pointer(String(objList[0][i])));
					pointerList[1].push( (objList[1][i] ? new Pointer(String(objList[1][i])) : null) );
				}
				
			so.data.gui = new Array(
				new Array(
					player,
					roomTitle,
					roomItems,
					chars,
					nav
				),
				navCurrent,
				pointerList
			)
			so.flush();
			so.close();
		}

		public function _load(dir:String):void{
			var so:SharedObject = SharedObject.getLocal(dir),
				visibility:Array = so.data.gui[0];

			playerVisible(visibility[0]);
			roomTitleVisible(visibility[1]);
			roomItemsVisible(visibility[2]);
			charsVisible(visibility[3]);
			navVisible(visibility[4]);

			setNav(so.data.gui[1]);
			
			var pointerList:Array = so.data.gui[2];

			if (pointerList){
				objList = new Array(new Array(), new Array());

				for (var i:int = 0; i < pointerList[0].length; i++){
					objList[0][i] = _Object.getObject(pointerList[0][i].str);
					objList[1][i] = (pointerList[1][i] ? _Object.getObject(pointerList[1][i].str) : null);
				}
			}
			else
				objList = null;
			clearList();

			_enter(Room.getCurrent());

			so.close();
		}

		public function _start():void{
			navDefault = Interface.getNavSystem();
			navCurrent = navDefault;
		}

		public function _delete(dir:String):void{}

		public static function playerVisible(b:Boolean):void{
			Interface.getUI().player.visible = b;
			player = b;
		}

		public static function roomTitleVisible(b:Boolean):void{
			var ui:Interface = Interface.getUI();
			ui.txt_title.visible = b;
			ui.roomTitle.visible = b;
			roomTitle = b;
		}

		public static function roomItemsVisible(b:Boolean):void{
			Interface.getUI().room.visible = b;
			roomItems = b;
		}

		public static function charsVisible(b:Boolean):void{
			var ui:Interface = Interface.getUI();
			ui.charBar.alpha = ( b ? 1 : 0);
			ui.charBar.mouseEnabled = b;
			ui.charBar.mouseChildren = b;
			ui.charLine.alpha = ( b ? 1 : 0);
			ui.charLine.mouseEnabled = b;
			ui.charLine.mouseChildren = b;

			var charList:Array = Character.getList();
			for (var i:int = 0; i < charList.length; i++){
				charList[i].alpha = ( b ? 1 : 0);
				charList[i].mouseEnabled = b;
				charList[i].mouseChildren = b;
			}

			chars = b;
		}

		public static function setNav(str:String):*{
			str = str.toLowerCase();
			if (str == "compass" || str == "cross"){
				Interface.setNavSystem(str);
				Interface.getUI().updateNav();
				navVisible(nav);
				navCurrent = str;
			}
			else
				return new Output('Invalid navigation system. Expected "cross" or "compass".');
			return;
		}

		public static function navVisible(b:Boolean):void{
			var ui:Interface = Interface.getUI();
				
			if (Interface.getNavSystem() == "cross")
				ui.navCross.visible = b;
			else
				ui.navCompass.visible = b;

			ui.btn_in.visible = b;
			ui.btn_out.visible = b;
			nav = b;
		}
		
		public static function mouseX():Number{
			return Engine.getStage().mouseX;
		}
		public static function mouseY():Number{
			return Engine.getStage().mouseY;
		}

		public static function addObj(obj:_Object,room:Room = null):void{
			if (!objList)
				objList = new Array(new Array(),new Array());
			else{
				var index:int = objList[0].indexOf(obj);
	
				if (index >= 0 && objList[1][index] == room)
					return;
				if (index >= 0)
					removeObj(obj);
				if (!objList)
					objList = new Array(new Array(),new Array());
			}
			
			objList[0].push(obj);
			objList[1].push(room);
			
			if (!room || room == Room.getCurrent()){
				imageList[0].push(obj);
				imageList[1].push(null);
				imageList[2].push(null);
			}
		}

		public static function removeObj(obj:_Object):void{
			if (objList){
				var index:int = objList[0].indexOf(obj);
				if (index >= 0){
					objList[0].splice(index);
					objList[1].splice(index);
					
					if (objList[0].length == 0)
						objList = null;

					index = imageList[0].indexOf(obj);
					if (index >= 0){
						if (imageList[2][index])
							imageList[2][index].removeSelf();

						imageList[0].splice(index);
						imageList[1].splice(index);
						imageList[2].splice(index);
					}
				}
			}
		}

		public static function scale(obj:_Object,num:Number):void{
			scaleX(obj,num);
			scaleY(obj,num);
		}

		private static function getBitmap(obj:_Object):Bitmap{
			var index:int = imageList[0].indexOf(obj);

			if (index >= 0 && imageList[2][index])
				return imageList[2][index].getBitmap();
			else if (obj.getImage())
				return Image.getImage(obj.getImage());
			return null
		}

		public static function scaleX(obj:_Object,num:Number):void{
			var bitmap:Bitmap = getBitmap(obj);
			
			if (bitmap){
				if (num != bitmap.scaleX){
					bitmap.scaleX = num;
					obj.setVar("width",bitmap.width);
					update(obj);
				}
			}
		}

		public static function scaleY(obj:_Object,num:Number):void{
			var bitmap:Bitmap = getBitmap(obj);

			if (bitmap){
				if (num != bitmap.scaleY){
					bitmap.scaleY = num;
					obj.setVar("height",bitmap.height);
					update(obj);
				}
			}
		}

		private static function update(obj:_Object):void{
			if (imageList[0].indexOf(obj) < 0)
				return;
			var bitmapHolder:BitmapHolder = imageList[2][imageList[0].indexOf(obj)];
			if (bitmapHolder){
				var bitmap:Bitmap = bitmapHolder.getBitmap();

//				if (bitmapHolder.parent.getChildIndex(bitmapHolder) < bitmapHolder.parent.numChildren-1)
//					bitmapHolder.parent.setChildIndex(bitmapHolder,bitmapHolder.parent.numChildren-1);

				var _x:Number = Number(obj.getVar("x")),
					_y:Number = Number(obj.getVar("y")),
					_width:* = obj.getVar("width"),
					_height:* = obj.getVar("height");
						
				if (!isNaN(_x))
					bitmapHolder.x = _x;
				if (!isNaN(_y))
					bitmapHolder.y = _y;
				if (_width){
					_width = Number(_width);
					if (!isNaN(_width) && bitmap.width != _width)
						bitmap.width = _width;
				}
				if (_height){
					_height = Number(_height);
					if (!isNaN(_height) && bitmap.height != _height)
						bitmap.height = _height;
				}
			}
		}

		private static function clearList():void{
			while (imageList[0].length > 0){
				if (imageList[2][0])
					imageList[2][0].removeSelf();

				imageList[0].splice(0);
				imageList[1].splice(0);
				imageList[2].splice(0);
			}
		}

		public function _enter(room:Object):void{
			if (objList){
				for (var i:int = 0; i < objList[0].length; i++){
					if ((!objList[1][i] || objList[1][i] == room) && imageList[0].indexOf(objList[0][i]) < 0){
						imageList[0].push(objList[0][i]);
						imageList[1].push(null);
						imageList[2].push(null);
					}
					else if (objList[1][i] && imageList[0].indexOf(objList[0][i]) >= 0){
						var index:int = imageList[0].indexOf(objList[0][i]);

						if (imageList[2][index])
							imageList[2][index].removeSelf();

						imageList[0].splice(index);
						imageList[1].splice(index);
						imageList[2].splice(index);
					}
				}
			}
		}

		public function _leave(room:Object):void{}
		
		private function loop(e:Event):void{
			if (imageList[0].length > 0)
				for (var i:int = 0; i < imageList[0].length; i++){
					var obj:_Object = imageList[0][i],
						bitmapHolder:BitmapHolder;

					if (obj.getImage() != imageList[1][i]){
						imageList[1][i] = obj.getImage();

						if (imageList[2][i])
							imageList[2][i].removeSelf();

						if (imageList[1][i]){
							var bitmap:Bitmap = Image.getImage(imageList[1][i]);
							
							if (bitmap)
								bitmapHolder = new BitmapHolder(bitmap,obj);
							imageList[2][i] = bitmapHolder;
						}
						else
							imageList[2][i] = null;

						if (bitmapHolder){
							if (objList[1][objList[0].indexOf(obj)])
								Interface.getUI().roomImageHolder.addChild(bitmapHolder);
							else
								Interface.getUI().addChild(bitmapHolder);
						}
					}
					else
						bitmapHolder = imageList[2][i];

					update(obj);
				}
		}
	}
}