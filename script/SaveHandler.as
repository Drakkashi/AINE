package script{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.9.0 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2015 Drakkashi.com
	 */

	import flash.display.MovieClip;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.net.SharedObject;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	import flash.display.Stage;
	import script.Modules.Module;
	import flash.display.Shape;

	public class SaveHandler extends MovieClip{

		private static var saveDir:String;

		private var mainFile:SharedObject = SharedObject.getLocal(saveDir),
					stageRef:Stage = Engine.getStage(),
					prompt:Prompt,
					targetEntry:SaveEntry,
					current:SaveEntry,
					isDefault:Boolean = true,
					isFocus:Boolean = false,
					defaultInput:String,
					layout:int,
					roomImage:Bitmap,
					playerImage:Bitmap,
					list:Array = new Array(),
					initY:int,
					offStage:Boolean,
					rect:MovieClip,
					isDown:Boolean;

		public function SaveHandler(layout:int){
			defaultInput = newSave.txt_input.text;
			player_imageHolder.gotoAndStop(1);
			this.layout = layout;
			
			if (!mainFile.data.saveList)
				mainFile.data.saveList = new Array();

			if (!mainFile.data.previewList)
				mainFile.data.previewList = new Array();

			if (layout == 2){
				txt_title.text = "Load Game";
				newSave.visible = false;
			}
			else{
				newSave.btn_save.addEventListener(MouseEvent.ROLL_OVER,btnSave_over);
				newSave.btn_save.addEventListener(MouseEvent.ROLL_OUT,btnSave_out);
				newSave.btn_save.addEventListener(MouseEvent.CLICK,btnSave_click);
				newSave.txt_input.addEventListener(FocusEvent.FOCUS_IN,txt_focus);
				newSave.txt_input.addEventListener(FocusEvent.FOCUS_OUT,txt_unfocus);
				newSave.txt_input.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
			}
			
			btn_cancel.stop();
			btn_cancel.addEventListener(MouseEvent.ROLL_OVER,btnCancel_over);
			btn_cancel.addEventListener(MouseEvent.ROLL_OUT,btnCancel_out);
			btn_cancel.addEventListener(MouseEvent.CLICK,btnCancel_click);

			updateList();

			if (width < Engine.getWidth() || height < Engine.getHeight()){
				var rect:Shape = new Shape();
				rect.graphics.beginFill(0xFFFFFF,0);
				rect.graphics.drawRect(0,0,Engine.getWidth(),Engine.getHeight());
				rect.graphics.endFill();
				rect.x -= x;
				rect.y -= y;
				
				this.rect = new MovieClip();
				this.rect.addChild(rect);
				stageRef.addChild(this.rect);

				if (width < Engine.getWidth())
					x = (Engine.getWidth()-width)/2;
				if (height < Engine.getHeight())
					y = (Engine.getHeight()-height)/2;
			}
				

			stageRef.addChild(this);
			bar.addEventListener(MouseEvent.MOUSE_DOWN,scrollDown);
			stageRef.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			stageRef.addEventListener(MouseEvent.MOUSE_MOVE,mouseMove);
			stageRef.focus = stageRef;
		}

		private function scrollDown(e:MouseEvent):void{
			if (!prompt){
				offStage = false;
				isDown = true;
				initY = mouseY;
				addEventListener(MouseEvent.MOUSE_UP,scrollUp);
				stageRef.addEventListener(Event.MOUSE_LEAVE,mouseLeave);
				stageRef.addEventListener(MouseEvent.MOUSE_OUT,mouseOut);
				stageRef.addEventListener(MouseEvent.MOUSE_OVER,mouseOver);
				removeEventListener(MouseEvent.MOUSE_WHEEL, scrollWheel);
			}
		}

		private function scrollUp(e:MouseEvent=null):void{
			isDown = false;
			removeEventListener(MouseEvent.MOUSE_UP,scrollUp);
			stageRef.removeEventListener(Event.MOUSE_LEAVE,mouseLeave);
			stageRef.removeEventListener(MouseEvent.MOUSE_OUT,mouseOut);
			stageRef.removeEventListener(MouseEvent.MOUSE_OVER,mouseOver);
			addEventListener(MouseEvent.MOUSE_WHEEL, scrollWheel);
			stageRef.focus = stageRef;
		}

		private function listScroll():void{
			var maxScroll:int = list.length - 14,
				scrollV:Number;

			if (bar.y < line.y)
				bar.y = line.y;
			else if (bar.y > line.y + line.height - bar.height)
				bar.y = line.y + line.height - bar.height;

			scrollV = (bar.y - line.y)/(line.height-bar.height)*maxScroll*list[0].height;

			for (var i:int = 0; i < list.length; i++){
				list[i].y = list[i].height*i-scrollV;
				if (list[i].y > line.height || list[i].y < -list[i].height)
					list[i].visible = false;
				else
					list[i].visible = true;
			}
		}

		private function mouseMove(e:MouseEvent):void{
			if (isDown){
				bar.y += mouseY - initY;
				listScroll();
				initY = mouseY;
			}
			saveHolder.mouseChildren = true;
		}

		private function scrollWheel(e:MouseEvent):void{
			if (!prompt){
				var index:int = current.getIndex();
				
				bar.y -= (line.height - bar.height)/(list.length -14)*e.delta;
				listScroll();
			}
		}

		private function keyDown(e:KeyboardEvent):void{
			if (!prompt && !isDown){
				if (e.keyCode == Keyboard.DOWN || e.keyCode == Keyboard.UP){
					var index:int = current.getIndex();
					saveHolder.mouseChildren = false;

					if (e.keyCode == Keyboard.DOWN){
						if (index+1 < list.length)
							showEntry(list[index+1]);
					}
					else{
						if (index-1 >= 0)
							showEntry(list[index-1]);
					}

					if (current.y < 0){
						bar.y = line.y + (line.height - bar.height)/(list.length -14)*current.getIndex();
						listScroll();
					}
					else if (current.y > current.height*13){
						bar.y = line.y + (line.height - bar.height)/(list.length -14)*(current.getIndex()-13);
						listScroll();
					}
				}
				else if (e.keyCode == Keyboard.ESCAPE)
					removeSelf();
			}
		}

		private function mouseLeave(e:Event):void{
			if (offStage)
				scrollUp();
		}
		
		private function mouseOver(e:MouseEvent):void{
			offStage = false;
		}
		
		private function mouseOut(e:MouseEvent):void{
			offStage = true;
		}

		public function updateList():void {
			for each (var entry:SaveEntry in list)
				entry.removeSelf();
			list = new Array();

			for (var i:int = 0; i < mainFile.data.previewList.length; i++){
				var arr:Array = mainFile.data.previewList[i],
					str:String = mainFile.data.saveList[i];

				list[i] = new SaveEntry(str,toDir(str),layout,i,arr);
				list[i].addEventListener(Event.REMOVED_FROM_STAGE, removeEntry);
				list[i].addEventListener(MouseEvent.ROLL_OVER,entry_over);
				list[i].addEventListener("save", promptSave_show);
				list[i].addEventListener("load", promptLoad_show);
				list[i].addEventListener("delete", promptDelete_show);
				saveHolder.addChild(list[i]);
				if (list[i].y > line.height || list[i].y < -list[i].height)
					list[i].visible = false;
			}

			if (list.length > 0)
				showEntry(list[0]);
			else{
				txt_roomTitle.text = "";
				txt_description.text = "";
				removePlayerImage();
				removeRoomImage();
			}

			if (list.length > 14){
				bar.visible = true;
				line.visible = true;

				bar.height = line.height*(1-(list.length-14)/list.length);

				if (bar.height < 10)
					bar.height = 10;
		
				bar.y = line.y;
				stageRef.addEventListener(MouseEvent.MOUSE_WHEEL, scrollWheel);
			}
			else{
				bar.visible = false;
				line.visible = false;
				stageRef.removeEventListener(MouseEvent.MOUSE_WHEEL, scrollWheel);
			}
		}

		private function txt_focus(e:FocusEvent):void{
			if (isDefault && e.currentTarget.text.replace(/\r/g, "") == defaultInput.replace(/\r/g, "")){
				e.currentTarget.text = "";
				isDefault = false;
			}
			isFocus = true;
		}

		private function txt_unfocus(e:FocusEvent):void{
			if (e.currentTarget.text.length == 0){
				e.currentTarget.htmlText = "<i>" + defaultInput + "</i>";
				isDefault = true;
			}
			isFocus = false;
		}

		private function btnSave_click(e:MouseEvent):void{
			if (!isDefault)
				processNewSave();
		}

		private function keyPressed(e:KeyboardEvent):void{
			if (isFocus && e.keyCode == Keyboard.ENTER && !prompt)
				processNewSave();
		}

		private static function toDir(str:String):String{
			return saveDir+"."+str.replace(" ","%20").toLowerCase();
		}

		private function processNewSave():void{
			var str:String = trim(Engine.getValidTitle(newSave.txt_input.text));

			if (str.length > 0){
				var entry:SaveEntry = getSave(str);

				if (entry){
					newSave.txt_input.text = str;

					targetEntry = new SaveEntry(str,toDir(str),layout,entry.getIndex());
					promptSave_show();
				}
				else{
					saveGame(new SaveEntry(str,toDir(str),layout));
				}
			}
		}

		private function getSave(str:String):SaveEntry{
			str = toDir(str);
			for (var i:int = 0; i < list.length; i++)
				if (list[i].getDir() == str)
					return list[i];
			return null;
		}

		private function promptSave_show(e:Event=null):void{
			if (e){
				var entry:SaveEntry = list[list.indexOf(e.currentTarget)];
				targetEntry = new SaveEntry(entry.getName(),entry.getDir(),layout,entry.getIndex());
			}

			mouseEnabled = false;
			mouseChildren = false;
			showEntry(list[entry.getIndex()]);
			prompt = new Prompt("Save","Do you want to overwrite this saved game?");
			prompt.addEventListener("yes", promptSave_yes);
			prompt.addEventListener(Event.REMOVED_FROM_STAGE, promptClose);
		}

		private function promptLoad_show(e:Event):void{
			targetEntry = list[list.indexOf(e.currentTarget)];

			mouseEnabled = false;
			mouseChildren = false;
			prompt = new Prompt("Load","Loading a game will cause unsaved progress to be lost.<br /><br />Do you want to load this game?");
			prompt.addEventListener("yes", promptLoad_yes);
			prompt.addEventListener(Event.REMOVED_FROM_STAGE, promptClose);
		}

		private function promptDelete_show(e:Event=null):void{
			targetEntry = list[list.indexOf(e.currentTarget)];

			mouseEnabled = false;
			mouseChildren = false;
			prompt = new Prompt("Delete","Do you want to delete this saved game?");
			prompt.addEventListener("yes", promptDelete_yes);
			prompt.addEventListener(Event.REMOVED_FROM_STAGE, promptClose);
		}

		private function promptSave_yes(e:Event=null):void{
			saveGame(targetEntry);
		}

		private function promptLoad_yes(e:Event=null):void{
			loadGame(targetEntry);
		}

		private function promptDelete_yes(e:Event=null):void{
			deleteGame(targetEntry);
		}

		private function promptClose(e:Event):void{
			if (targetEntry.getIndex() < 0)
				targetEntry.removeSelf();

			mouseEnabled = true;
			mouseChildren = true;
			prompt.addEventListener("yes", promptSave_yes);
			prompt.addEventListener("yes", promptLoad_yes);
			prompt.addEventListener("yes", promptDelete_yes);
			prompt.removeEventListener(Event.REMOVED_FROM_STAGE, promptClose);
			prompt = null;
		}

		public function saveGame(entry:SaveEntry):void{
			var index:int = entry.getIndex(),
				saveFile:SharedObject = SharedObject.getLocal(entry.getDir());

			// INTERFACE
			saveFile.data.gameNav = Interface.getNavSystem();

			// PLAYER
			saveFile.data.player = Player.getPlayer().getDataArray();

			// CHARACTERS
			saveFile.data.charList = new Array();
			var charList:Array = Character.getList();
			for each (var char:Character in charList)
				saveFile.data.charList.push(char.getDataArray());

			// ITEMS
			saveFile.data.itemList = new Array();
			var itemList:Array = Item.getList();
			for each (var item:Item in itemList)
				saveFile.data.itemList.push(item.getDataArray());

			// ROOMS
			saveFile.data.roomList = new Array();
			var roomList:Array = Room.getList();
			for each (var room:Room in roomList)
				saveFile.data.roomList.push(room.getDataArray());

			// OBJECTS
			saveFile.data.objList = new Array();
			var objList:Array = GenericObject.getList();
			for each (var object:GenericObject in objList)
				saveFile.data.objList.push(object.getDataArray());

			saveFile.flush();
			saveFile.close();

			if (index >= 0){
				mainFile.data.saveList.splice(index,1);
				mainFile.data.previewList.splice(index,1);
			}

			mainFile.data.saveList = new Array(entry.getName()).concat(mainFile.data.saveList);
			mainFile.data.previewList = new Array(entry.getPreview()).concat(mainFile.data.previewList);
			mainFile.flush();

			for each (var module:* in Module.getGameListeners())
				module._save(entry.getDir());

			if (isFocus){
				newSave.txt_input.text = "";
				isDefault = false;
			}
			else{
				newSave.txt_input.htmlText = "<i>" + defaultInput + "</i>";
				isDefault = true;
			}

			updateList();
		}

		public function loadGame(entry:SaveEntry):void {
			Player.getPlayer().reset();
			Item.resetItems();
			Character.resetChars();
			Room.resetRooms();
			GenericObject.resetObjects();
			ScreenMessage.clearList();

			if (Display.getCurrent())
				Display.getCurrent().removeSelf();
			
			Interface.getUI().resetMenu();

			var saveFile:SharedObject = SharedObject.getLocal(entry.getDir());

			// INTERFACE
			Interface.setNavSystem(saveFile.data.gameNav);
				
			// PLAYER
			Player.getPlayer().loadDataArray(saveFile.data.player);

			// CHARACTERS
			var charList:Array = saveFile.data.charList;
			for each (var charArr:Array in charList){
				var char:Character = Character.getCharacter(charArr[0]);
				
				if (char)
					char.loadDataArray(charArr);
			}

			// ITEMS
			var itemList:Array = saveFile.data.itemList;
			for each (var itemArr:Array in itemList){
				var item:Item = Item.getItem(itemArr[0]);
				
				if (item)
					item.loadDataArray(itemArr);
			}

			// ROOMS
			var roomList:Array = saveFile.data.roomList;
			for each (var roomArr:Array in roomList){
				var room:Room = Room.getRoom(roomArr[0]);

				if (room)
					room.loadDataArray(roomArr);
			}

			// OBJECTS
			var objList:Array = saveFile.data.objList;
			if (objList)
				for each (var objArr:Array in objList){
					var object:GenericObject = GenericObject.getObject(objArr[0]);

					if (object)
						object.loadDataArray(objArr);
				}
				
			saveFile.close();

			for each (var module:* in Module.getGameListeners())
				module._load(entry.getDir());

			Interface.getUI().updateRoom();
			removeSelf();
		}

		public function deleteGame(entry:SaveEntry):void {
			for each (var module:* in Module.getGameListeners())
				module._delete(entry.getDir());

			var index:int = entry.getIndex();

			mainFile.data.saveList.splice(index,1);
			mainFile.data.previewList.splice(index,1);
			mainFile.flush();

			var saveFile:SharedObject = SharedObject.getLocal(entry.getDir());
			saveFile.clear();
			updateList();
		}

		public function setPlayerImage(image:Bitmap,gender:String):void{
			if (playerImage && playerImage.parent)
				player_imageHolder.removeChild(playerImage);

			if (image){
				playerImage = image;

				if (playerImage.width > playerImage.height){
					playerImage.height = playerImage.height/playerImage.width*119.1;
					playerImage.width = 119.1;
				}
				else{
					playerImage.width = playerImage.width/playerImage.height*119.1;
					playerImage.height = 119.1;
				}

				playerImage.x = (119.1-playerImage.width)/2;
				playerImage.y = (119.1-playerImage.height)/2;
				player_imageHolder.gotoAndStop(1);
				player_imageHolder.addChild(playerImage);
			}
			else{
				if (gender && gender.toLowerCase() == "male")
					player_imageHolder.gotoAndStop(2);
				else if (gender && gender.toLowerCase() == "female")
					player_imageHolder.gotoAndStop(3);
				else
					player_imageHolder.gotoAndStop(1);
			}
		}

		public function removePlayerImage():void{
			if (playerImage)
				player_imageHolder.removeChild(playerImage);
			player_imageHolder.gotoAndStop(1);
		}

		public function setRoomImage(image:Bitmap):void{
			if (roomImage && roomImage.parent)
				room_imageHolder.removeChild(roomImage);

			if (image){
				roomImage = image;

				if (image.width / 800 > image.height / 495){
					image.width = image.width/image.height*495;
					image.height = 495;
				}
				else{
					image.height = image.height/image.width*800;
					image.width = 800;
				}

				image.x = (800-image.width)/2;
				image.y = (495-image.height)/2;
				image = Image.cropImage(image);
				room_imageHolder.addChild(image);
				roomImage = image;
			}
		}

		public function removeRoomImage():void{
			if (roomImage)
				room_imageHolder.removeChild(roomImage);
		}

		public static function setSaveDir(str:String):void{
			saveDir = "com.drakkashi.AINE."+Engine.getValidTitle(str.replace(/\s/g,"%20")).toLowerCase();
		}

		private function btnCancel_over(e:MouseEvent):void{
			e.currentTarget.gotoAndStop(2);
		}

		private function btnCancel_out(e:MouseEvent):void{
			e.currentTarget.gotoAndStop(1);
		}

		private function btnCancel_click(e:MouseEvent):void{
			removeSelf();
		}

		private function btnSave_over(e:MouseEvent):void{
			e.currentTarget.htmlText = "<font color='#FFFFFF'><b>" + e.currentTarget.text + "</b></font>";
		}

		private function btnSave_out(e:MouseEvent):void{
			e.currentTarget.htmlText = "<font color='#CCCCCC'><b>" + e.currentTarget.text + "</b></font>";
		}

		private function showEntry(entry:SaveEntry):void{
			current = entry;
			txt_roomTitle.text = entry.getRoomName();
			txt_description.htmlText = entry.getPlayerDesc();
			setPlayerImage(Image.getImage(entry.getPlayerImage()),entry.getPlayerGender());
			setRoomImage(Image.getImage(entry.getRoomImage()));
			entry.background.gotoAndStop(2);
				
			for (var i:int = 0; i < list.length; i++)
				if (i != entry.getIndex())
					list[i].background.gotoAndStop(1);
		}

		private function entry_over(e:MouseEvent):void{
			if (!prompt)
				showEntry(e.currentTarget as SaveEntry);
		}

		public function getLayout():int{
			return layout;
		}

		private static function cloneArray(array:Object):Array {
			return array.concat();
		}

		private function removeEntry(e:Event):void{
			e.currentTarget.removeEventListener(Event.REMOVED_FROM_STAGE, removeEntry);
			e.currentTarget.removeEventListener(MouseEvent.ROLL_OVER,entry_over);
			e.currentTarget.removeEventListener("save", promptSave_show);
			e.currentTarget.removeEventListener("load", promptLoad_show);
			e.currentTarget.removeEventListener("delete", promptDelete_show);
		}

		private static function trim(str:String):String{
			return (str ? str.replace(/^\s+|\s+$/g, "") : "");
		}

		public function removeSelf():void {
			newSave.btn_save.removeEventListener(MouseEvent.ROLL_OVER,btnSave_over);
			newSave.btn_save.removeEventListener(MouseEvent.ROLL_OUT,btnSave_out);
			newSave.btn_save.removeEventListener(MouseEvent.CLICK,btnSave_click);
			newSave.txt_input.removeEventListener(FocusEvent.FOCUS_IN,txt_focus);
			newSave.txt_input.removeEventListener(FocusEvent.FOCUS_OUT,txt_unfocus);
			newSave.txt_input.removeEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
			btn_cancel.removeEventListener(MouseEvent.ROLL_OVER,btnCancel_over);
			btn_cancel.removeEventListener(MouseEvent.ROLL_OUT,btnCancel_out);
			btn_cancel.removeEventListener(MouseEvent.CLICK,btnCancel_click);
			bar.removeEventListener(MouseEvent.MOUSE_DOWN,scrollDown);
			stageRef.removeEventListener(MouseEvent.MOUSE_WHEEL, scrollWheel);
			stageRef.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			stageRef.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMove);

			for each (var entry:SaveEntry in list)
				entry.removeSelf();
				
			mainFile.close();

			if (rect && rect.parent)
				rect.parent.removeChild(rect);

			if (parent)
				parent.removeChild(this);
		}
	}
}