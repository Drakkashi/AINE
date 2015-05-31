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
    import flash.display.Shape;
    import flash.utils.Timer;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getDefinitionByName;
	import flash.events.MouseEvent;
	import flash.events.Event;
    import flash.events.TimerEvent;
	import flash.text.TextFieldAutoSize;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import flash.display.Stage;
	import flash.text.TextField;
	import script.Modules.Module;

	public class Interface extends MovieClip{
		
		private static var ui:Interface,
						   navSystem:String = "compass";

		private var stageRef:Stage = Engine.getStage(),
					stageWidth:Number = Engine.getWidth(),
					stageHeight:Number = Engine.getHeight(),
					navButtons:Array,
					gameOver:GameOver,
					gameMenu:GameMenu = new GameMenu(),
					playerImage:Bitmap,
					playerItems:Array = new Array(),
					roomImage:Bitmap,
					roomItems:Array = new Array(),
					charList:Array = new Array(),
					charScroll:int = 0,
					charMaxScroll:int,
					prevDisplaySize:int = 6,
					initY:int,
					offStage:Boolean,
					isDown:Boolean,
					scrollBar:Object,
					scrollLine:Object,
					prevItem:Item,
					roomListRect:Shape,
					playerListRect:Shape,
					tooltip:MovieClip,
					tooltipStr:String,
					tooltipTimer:Timer = new Timer(1000,0),
					eventList:MovieClip,
					eventListRect:Shape,
					eventListObj:_Object,
					eventListText:Array = new Array(),
					menu:GameMenu = new GameMenu();


		public function Interface(){
			roomImageHolder.whitespace.width = stageWidth;
			roomImageHolder.whitespace.height = stageHeight;

			var sizeModWidth:Number = stageWidth - 800,
				sizeModHeight:Number =  stageHeight - 480;

			navCompass.y += sizeModHeight;
			navCross.y += sizeModHeight;
			btn_in.y += sizeModHeight;
			btn_out.y += sizeModHeight;
			btn_out.x += sizeModWidth;
			roomTitle.x += sizeModWidth;
			txt_title.x += sizeModWidth;
			charList.x += sizeModWidth;
			charBar.x += sizeModWidth;
			room.x = stageWidth - room.width - 2;
			navCross.x = (stageWidth-navCross.width)/2;

			addNavListeners();

			roomImageHolder.addEventListener(MouseEvent.CLICK,eventMouseClick);
			roomImageHolder.addEventListener(MouseEvent.ROLL_OVER,eventMouseOver);
			roomImageHolder.addEventListener(MouseEvent.ROLL_OUT,eventMouseOut);
			player.imageHolder.addEventListener(MouseEvent.CLICK,eventMouseClick);
			player.imageHolder.addEventListener(MouseEvent.ROLL_OVER,eventMouseOver);
			player.imageHolder.addEventListener(MouseEvent.ROLL_OUT,eventMouseOut);
			tooltipTimer.addEventListener(TimerEvent.TIMER, showTooltip);
			addEventListener(MouseEvent.CLICK,hideTooltip);
			addEventListener(MouseEvent.MOUSE_WHEEL, charListWheel);
			charBar.addEventListener(MouseEvent.MOUSE_DOWN,scrollDown);
			room.bar.addEventListener(MouseEvent.MOUSE_DOWN,scrollDown);
			player.bar.addEventListener(MouseEvent.MOUSE_DOWN,scrollDown);

			charBar.visible = false;
			charLine.visible = false;

			playerListRect = new Shape;
			initItemList(player.txt_items,playerListRect);

			roomListRect = new Shape;
			initItemList(room.txt_items,roomListRect);

			updatePlayerPortrait();
			updatePlayerItems();
			updateRoom();

			ui = this;
			addChild(menu);
			stageRef.addChild(this);
		}

		public function initItemList(txtField:TextField,rect:Shape):void{
			txtField.mouseWheelEnabled = false;
			txtField.addEventListener(MouseEvent.MOUSE_MOVE, itemListMove);
			txtField.addEventListener(MouseEvent.CLICK, itemListClick);
			txtField.addEventListener(MouseEvent.ROLL_OUT, itemListOut);

			var obj:Object = (txtField.parent == player ? player : room );
			obj.addChild(rect);
			obj.addChild(txtField);
			obj.addChild(obj.line);
			obj.addChild(obj.bar);

			rect.graphics.beginFill(0xDFDFDF,1);
			rect.graphics.drawRect(0, 0, txtField.width,txtField.getLineMetrics(0).height);
			rect.graphics.endFill();
			rect.visible = false;
			rect.x = txtField.x;
		}

		public function updateRoom():void{
			charScroll = 0;
			room.txt_items.scrollV = 0;
			charLine.y = room.y + room.height + 5;
			charBar.y = charLine.y;

			updateRoomImage();
			updateRoomName();
			updateRoomItems();
			updateNav();
		}

		private function scrollDown(e:MouseEvent):void{
			offStage = false;
			isDown = true;
			initY = mouseY;
			addEventListener(MouseEvent.MOUSE_UP,scrollUp);
			stageRef.addEventListener(Event.MOUSE_LEAVE,mouseLeave);
			stageRef.addEventListener(MouseEvent.MOUSE_MOVE,mouseMove);
			stageRef.addEventListener(MouseEvent.MOUSE_OUT,mouseOut);
			stageRef.addEventListener(MouseEvent.MOUSE_OVER,mouseOver);
			scrollBar = e.currentTarget;
			
			if (scrollBar == charBar)
				scrollLine = charLine;
			else
				scrollLine = (scrollBar == player.bar ? player.line : room.line);
		}

		private function scrollUp(e:MouseEvent=null):void{
			isDown = false;
			removeEventListener(MouseEvent.MOUSE_UP,scrollUp);
			stageRef.removeEventListener(Event.MOUSE_LEAVE,mouseLeave);
			stageRef.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMove);
			stageRef.removeEventListener(MouseEvent.MOUSE_OUT,mouseOut);
			stageRef.removeEventListener(MouseEvent.MOUSE_OVER,mouseOver);
		}

		private function mouseMove(e:MouseEvent):void{
			scrollBar.y += mouseY - initY;

			if (scrollBar.y < scrollLine.y)
				scrollBar.y = scrollLine.y;
			else if (scrollBar.y + scrollBar.height > scrollLine.y + scrollLine.height)
				scrollBar.y = scrollLine.y + scrollLine.height - scrollBar.height;
			
			if (scrollBar == charBar){
				charScroll = Math.round((scrollBar.y - scrollLine.y)/(scrollLine.height-scrollBar.height)*(charMaxScroll));

				for (var i:int = 0; i < charList.length; i++){
					charList[i].y = room.y + room.height + 5 + (charList[i].height+5) * Math.floor((i+charScroll*-2)/2);
					charList[i].x = room.x + room.width - (charList[i].width+5)*(i%2+1) - 5;

					if (i/2 < charScroll || i - charScroll*2 > 5 || roomItems.length > 4 && i - charScroll*2 > 3)
						charList[i].visible = false;
					else
						charList[i].visible = true;
				}
			}
			else{
				var txtField:TextField;

				if (scrollBar == player.bar)
					txtField = player.txt_items;
				else if (scrollBar == room.bar)
					txtField = room.txt_items;

				txtField.scrollV = Math.round((scrollBar.y - scrollLine.y)/(scrollLine.height-scrollBar.height)*(txtField.maxScrollV -2))+1;
			}
			initY = mouseY;
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

		private function itemListClick(e:MouseEvent):void{
			var index:int = getLineIndex(e.currentTarget),
				item:Item = (e.currentTarget.parent == player ? playerItems[index] : roomItems[index]);

			if (item)
				_Event.eventInterface(item,"Mouse_Click");
		}

		private function itemListOut(e:MouseEvent):void{
			if (e.currentTarget.parent == player)
				playerListRect.visible = false;
			else
				roomListRect.visible = false;

			if (prevItem){
				_Event.eventInterface(prevItem,"Mouse_Out");
				prevItem = null;
			}
		}

		private function itemListMove(e:MouseEvent):void{
			var index:int = getLineIndex(e.currentTarget),
				item:Item = (e.currentTarget.parent == player ? playerItems[index] : roomItems[index]);

			if (prevItem != item){
				if (prevItem)
					_Event.eventInterface(prevItem,"Mouse_Out");
				
				var rect:Shape = (e.currentTarget.parent == player ? playerListRect : roomListRect);
				if (item){
					_Event.eventInterface(item,"Mouse_Over");
					
					var txtField:TextField = (e.currentTarget.parent == player ? player.txt_items : room.txt_items);
					rect.y = txtField.y + txtField.getLineMetrics(index).height*(index-txtField.scrollV+1);
					rect.visible = true;
				}
				else
					rect.visible = false;
					
				prevItem = item;
			}
		}

		private function getLineIndex(obj:Object):int{
			return obj.getLineIndexAtPoint(mouseX-obj.parent.x-obj.x,mouseY-obj.parent.y-obj.y);
		}

		private function overCharList():Boolean{
			var charX:int = int.MAX_VALUE,
				charY:int = int.MAX_VALUE,
				charHeight:int = 0,
				charWidth:int = 0;

			for each(var char:Character in charList){
				if (char.visible){
					if (char.x < charX)
						charX = char.x;
					if (char.y < charY)
						charY = char.y;
					if (char.x + char.width > charWidth)
						charWidth = char.x + char.width;
					if (char.y + char.height > charHeight)
						charHeight = char.y + char.height;
				}
			}
			
			return mouseX >= charX && mouseX < charWidth && mouseY >= charY && mouseY < charHeight;
		}

		private function charListWheel(e:MouseEvent):void{
			if (!isDown && charBar.visible && !(eventListObj && eventListObj.getClass() == Character) && overCharList()){
				charScroll -= (e.delta < 0 ? -1 : 1);

				if (charScroll > charMaxScroll)
					charScroll = charMaxScroll;
	
				if (charScroll < 0)
					charScroll = 0;
	
				for (var i:int = 0; i < charList.length; i++){
					charList[i].y = room.y + room.height + 5 + (charList[i].height+5) * Math.floor((i+charScroll*-2)/2);
					charList[i].x = room.x + room.width - (charList[i].width+5)*(i%2+1) - 5;

					if (i/2 < charScroll || i - charScroll*2 > 5 || roomItems.length > 4 && i - charScroll*2 > 3)
						charList[i].visible = false;
					else
						charList[i].visible = true;
				}

				charBar.y = charLine.y + (charScroll)*(charLine.height-charBar.height)/(charMaxScroll);
	
				if (charBar.y > charLine.y + charLine.height - charBar.height)
					charBar.y = charLine.y + charLine.height - charBar.height;
			}
		}

		private function scrollWheel(e:MouseEvent):void{
			var obj:Object = e.currentTarget.parent;
			if (!isDown && !(eventListObj && (obj == player && playerItems.indexOf(eventListObj) >= 0 || obj == room && roomItems.indexOf(eventListObj) >= 0))){
				e.currentTarget.scrollV -= e.delta;
	
				if (e.currentTarget.scrollV == e.currentTarget.maxScrollV)
					e.currentTarget.scrollV--;
	
				obj.bar.y = obj.line.y + (e.currentTarget.scrollV-1)*(obj.line.height-obj.bar.height)/(e.currentTarget.maxScrollV-2);
				itemListMove(e);
			}
		}

		private function getNavRoom(obj:Object):Room{
			return Room.getCurrent().getNav().getRoom(navButtons.indexOf(obj));
		}

		private function eventNavClick(e:MouseEvent):void{
			if (e.currentTarget.currentFrame == 1){
				var room:Room = getNavRoom(e.currentTarget);
	
				for each (var module:* in Module.getNavListeners())
					module._navClick(room);
	
				_Event.eventInterface(room,"Nav_Click");
			}
		}

		private function eventNavOver(e:MouseEvent):void{
			if (e.currentTarget.currentFrame == 1){
				var room:Room = getNavRoom(e.currentTarget);
	
				for each (var module:* in Module.getNavListeners())
					module._navOver(room);
	
				_Event.eventInterface(room,"Nav_Over");
			}
		}

		private function eventNavOut(e:MouseEvent):void{
			if (e.currentTarget.currentFrame == 1){
				var room:Room = getNavRoom(e.currentTarget);
	
				for each (var module:* in Module.getNavListeners())
					module._navOut(room);
	
				_Event.eventInterface(room,"Nav_Out");
			}
		}

		private function eventMouseClick(e:MouseEvent):void{
			var obj:_Object = getObject(e.currentTarget);

			for each (var module:* in Module.getMouseListeners())
				module._mouseClick(obj);

			_Event.eventInterface(obj,"Mouse_Click");
		}

		private function eventMouseOver(e:MouseEvent):void{
			var obj:_Object = getObject(e.currentTarget);

			if (e.currentTarget != roomImageHolder){
				for each (var module:* in Module.getMouseListeners())
					module._mouseOver(obj);

				_Event.eventInterface(obj,"Mouse_Over");
			}
		}

		private function eventMouseOut(e:MouseEvent):void{
			var obj:_Object = getObject(e.currentTarget);

			if (e.currentTarget != roomImageHolder){
				for each (var module:* in Module.getMouseListeners())
					module._mouseOut(obj);

				_Event.eventInterface(obj,"Mouse_Out");
			}
		}

		private function getObject(obj:Object):_Object{
			if (obj == roomImageHolder)
				return Room.getCurrent();
			if (obj == player.imageHolder)
				return Player.getPlayer();
			if (charList.indexOf(obj) >= 0)
				return charList[charList.indexOf(obj)];
			if (playerItems.indexOf(obj) >= 0)
				return playerItems[playerItems.indexOf(obj)];
			if (roomItems.indexOf(obj) >= 0 )
				return roomItems[roomItems.indexOf(obj)];
			return null;
		}

		public function updatePlayerPortrait():void{
			var image:Bitmap = Image.getImage(Player.getPlayer().getImage());

			if (playerImage)
				player.imageHolder.removeChild(playerImage);

			if (image){
				if (image.width > image.height){
					image.height = image.height/image.width*119.1;
					image.width = 119.1;
				}
				else{
					image.width = image.width/image.height*119.1;
					image.height = 119.1;
				}

				image.x = 6.7 + (119.1-image.width)/2;
				image.y = 6.7 + (119.1-image.height)/2;
				player.imageHolder.gotoAndStop(1);
				player.imageHolder.addChild(image);
				playerImage = image;
			}
			else{
				var gender:String = Player.getPlayer().getGender();

				if (gender && gender.toLowerCase() == "male")
					player.imageHolder.gotoAndStop(2);
				else if (gender && gender.toLowerCase() == "female")
					player.imageHolder.gotoAndStop(3);
				else
					player.imageHolder.gotoAndStop(1);
			}
		}

		public function updateRoomName():void{
			txt_title.text = Room.getCurrent().getName();
		}

		public function updateRoomImage():void{
			var image:Bitmap = Image.getImage(Room.getCurrent().getImage());

			if (image){
				if (roomImage && roomImage.parent)
					roomImageHolder.removeChild(roomImage);

				if (image.width / stageWidth > image.height / stageHeight){
					image.width = image.width/image.height*stageHeight;
					image.height = stageHeight;
				}
				else{
					image.height = image.height/image.width*stageWidth;
					image.width = stageWidth;
				}

				image.x = (stageWidth-image.width)/2;
				image.y = (stageHeight-image.height)/2;
				image = Image.cropImage(image);
				roomImageHolder.addChild(image);
				roomImage = image;
			}
			else if (roomImage){
				if (roomImage.parent)
					roomImageHolder.removeChild(roomImage);
				roomImage = null;
			}
		}

		public function showEvents(obj:_Object):void{
			if (obj != eventListObj){
				var prevX:int = -1,
					prevY:int = -1;

				if (eventList){
					if (mouseX > eventList.x && mouseX < eventList.x + eventList.width &&
						mouseY > eventList.y && mouseY < eventList.y + eventList.height
					){
						prevX = eventList.x;
						prevY = eventList.y;
					}

					hideEvents();
				}

				var customList:Array = obj.getCustomList();

				if (customList.length > 0){
					eventList = new MovieClip;
					eventListRect = new Shape;
					eventListObj = obj;

					var frame:Shape = new Shape,
						rect:Shape = new Shape;
	
					eventList.addChild(frame);
					eventList.addChild(rect);
					eventList.addChild(eventListRect);

					eventListText = new Array();
					for (var i:int = 0; i < customList.length; i++){
						var txt:TextField = new TextField();
						txt.text = customList[i].getEvent();
						txt.autoSize = TextFieldAutoSize.LEFT;
						txt.mouseEnabled = false;
						txt.x = 25;
						txt.y = txt.height*(eventListText.length);
						eventListText.push(txt);
						eventList.addChild(txt);
					}

					rect.graphics.beginFill(0xFFFFFF,1);
					rect.graphics.drawRect(0, 0, eventList.width+50,eventListText[0].height*eventListText.length);
					rect.graphics.endFill();
					frame.graphics.beginFill(0xFFFFFF,0);
					frame.graphics.lineStyle(0.1,0x262626,1);
					frame.graphics.drawRect(0, 0, rect.width,rect.height);
					frame.graphics.endFill();
					eventListRect.graphics.beginFill(0xDFDFDF,1);
					eventListRect.graphics.drawRect(0, 0, rect.width,eventListText[0].height);
					eventListRect.graphics.endFill();
					eventListRect.visible = false;
					eventList.addChild(frame);

					if (prevX >= 0){
						eventList.x = (prevX + eventList.width < stageWidth ? prevX : stageWidth - eventList.width -1);
						eventList.y = (prevY + eventList.height < stageHeight ? prevY : stageHeight - eventList.height -1);
					}
					else{
						eventList.x = (mouseX + eventList.width -10 < stageWidth ? mouseX -10 : stageWidth - eventList.width -1);
						eventList.y = (mouseY + eventList.height -10 < stageHeight ? mouseY -10 : stageHeight - eventList.height -1);
					}

					addEventListener(Event.ENTER_FRAME,enableList);
					addChild(eventList);
				}
			}
			else
				hideEvents();
		}

		private function enableList(e:Event):void{
			removeEventListener(Event.ENTER_FRAME,enableList);
			addEventListener(MouseEvent.CLICK,eventListClick);
			eventList.addEventListener(MouseEvent.ROLL_OVER,eventListOver);
			eventList.addEventListener(MouseEvent.ROLL_OUT,eventListOut);
			eventList.addEventListener(MouseEvent.MOUSE_MOVE,eventListMove);
		}

		private function hideEvents():void{
			if (eventList && eventList.alpha > 0){
				removeEventListener(MouseEvent.CLICK,eventListClick);
				eventList.removeEventListener(MouseEvent.ROLL_OVER,eventListOver);
				eventList.removeEventListener(MouseEvent.ROLL_OUT,eventListOut);
				eventList.removeEventListener(MouseEvent.ROLL_OUT,eventListMove);

				if (eventList.parent)
					removeChild(eventList);
				eventList = null;
				eventListObj = null;
			}
		}

		private function eventListClick(e:MouseEvent):void{
			var prevList:MovieClip = eventList;
			if (mouseX > eventList.x && mouseX < eventList.x + eventList.width &&
				mouseY > eventList.y && mouseY < eventList.y + eventList.height
			)
				eventListObj.getCustomList()[getIndex()].trigger();
			if (prevList == eventList)
				hideEvents();
		}

		private function eventListOver(e:MouseEvent):void{
			eventListMove();
			eventListRect.visible = true;
		}

		private function eventListOut(e:MouseEvent):void{
			eventListRect.visible = false;
		}

		private function eventListMove(e:MouseEvent = null):void{
			eventListRect.y = getIndex()*eventListText[0].height;
		}

		private function getIndex():int{
			return (mouseY - eventList.y-1)/eventListText[0].height;
		}

		public function setTooltipString(str:String, b:Boolean=false):void{
			str = trim(str);
			var txtField:TextField = new TextField()
			txtField.htmlText = str;
			str = txtField.text;

			if (str.length > 50 && str.indexOf(".") >= 0 && str.substring(0,str.indexOf(".")).length < 50)
				tooltipStr = str.substring(0,str.indexOf(".")+1);
			else if (str.length > 50)
				tooltipStr = str.substring(0,47)+"...";
			else
				tooltipStr = str;

			if (b)
				tooltipTimer.start();
		}

		public function showTooltip(... args):void{
			if (tooltip)
				hideTooltip();

			if (toClass(args[0]) == String)
				setTooltipString(args[0]);
			else
				tooltipTimer.stop();

			if (!empty(tooltipStr)){
				var txt:TextField = new TextField();
				txt.text = tooltipStr;
				txt.autoSize = TextFieldAutoSize.LEFT;
		
				var rect:Shape = new Shape;
				rect.graphics.beginFill(0xFFFFFF,1)
				rect.graphics.lineStyle(0.1,0x262626,1);
				rect.graphics.drawRect(0, 0, txt.width,txt.height);
				rect.graphics.endFill();

				tooltip = new MovieClip();
				tooltip.mouseEnabled = false;
				tooltip.mouseChildren = false;
				tooltip.addChild(rect);
				tooltip.addChild(txt);
				tooltip.x = (mouseX+15 + tooltip.width <= 800 ? mouseX+15 : mouseX-5 - tooltip.width);
				tooltip.y = (mouseY+5 + tooltip.height <= 480 ? mouseY+5 : mouseY-5 - tooltip.height);
				new Tween(tooltip,"alpha",None.easeNone,0,1,0.4,true);
				addChild(tooltip);
			}
		}

		public function hideTooltip(e:Event = null):void{
			tooltipTimer.reset();
			if (tooltip && tooltip.alpha > 0){
				if (tooltip.parent)
					removeChild(tooltip);
			}
		}

		private function addEvents(obj:Object):void{
			obj.addEventListener(MouseEvent.ROLL_OVER,eventMouseOver);
			obj.addEventListener(MouseEvent.ROLL_OUT,eventMouseOut);
			obj.addEventListener(MouseEvent.CLICK,eventMouseClick);
		}

		private function clearList(list:Array):void{
			for (var i:int = 0; i < list.length; i++){
				list[i].removeEventListener(MouseEvent.ROLL_OVER,eventMouseOver);
				list[i].removeEventListener(MouseEvent.ROLL_OUT,eventMouseOut);
				list[i].removeEventListener(MouseEvent.CLICK,eventMouseClick);
				if (list[i].parent)
					list[i].parent.removeChild(list[i]);
			}
		}

		public function updateCharList():void{
			var prevY:Number = charLine.y,
				prevVisible:Boolean = charBar.visible;
			clearList(charList);
			charBar.visible = false;
			charLine.visible = false;
			charLine.y = room.y + room.height + 5;
			charBar.y += charLine.y - prevY;

			charList = Room.getCurrent().getChars();
			var margin:Number = 0,
				displaySize:int = (roomItems.length > 4 ? 4 : 6);

			charMaxScroll = Math.ceil((charList.length - displaySize)/2);

			if (charScroll > charMaxScroll)
				charScroll = charMaxScroll;

			if (charMaxScroll < 0)
				charMaxScroll = 0;

			if (charScroll < 0)
				charScroll = 0;

			if (charList.length > displaySize){
				margin = 5;
				charBar.visible = true;
				charLine.visible = true;

				charLine.height = (displaySize/2)*(charList[0].height+5)-5;
				charBar.height = charLine.height*(1-(Math.ceil(charList.length/2)-displaySize/2)/Math.ceil(charList.length/2));

				if (!prevVisible || prevDisplaySize != displaySize)
					charBar.y = charLine.y + (charScroll)*(charLine.height-charBar.height)/(charMaxScroll);
	
				if (charBar.y > charLine.y + charLine.height - charBar.height)
					charBar.y = charLine.y + charLine.height - charBar.height;

				prevDisplaySize = displaySize;
			}

			for (var i:int = 0; i < charList.length; i++){
				charList[i].y = room.y + room.height + 5 + (charList[i].height+5) * (Math.floor((i+charScroll*-2)/2));
				charList[i].x = room.x + room.width - (charList[i].width+5)*(i%2+1) - margin;

				if (i/2 < charScroll || i - charScroll*2 > 5 || roomItems.length > 4 && i - charScroll*2 > 3)
					charList[i].visible = false;
				else
					charList[i].visible = true;

				addEvents(charList[i]);
				addChild(charList[i]);
			}
		}

		public function updatePlayerItems():void{
			clearList(playerItems);
			playerItems = Player.getPlayer().getItems();
			updateItemList(playerItems,player,playerListRect);
			player.background.height = player.frame.height - player.background.y -5;
		}

		public function updateRoomItems():void{
			clearList(roomItems);
			roomItems = Room.getCurrent().getItems();
			updateItemList(roomItems,room,roomListRect);
			updateCharList();
		}

		private function updateItemList(itemList:Array,obj:Object,rect:Shape):void{
			var scrollV:int = obj.txt_items.scrollV;
			obj.txt_items.text = (itemList.length > 0 ? itemList[0].getName() : "");
			for (var i:int = 1; i < itemList.length; i++)
				obj.txt_items.appendText("\n" + itemList[i].getName());

			obj.txt_items.scrollV = scrollV;
			if (itemList.length > 8){
				obj.bar.visible = true;
				obj.line.visible = true;
				obj.txt_items.width = (obj == player ? 107.1 : 149.6);
				obj.txt_items.height = 124.8;
				obj.txt_items.addEventListener(MouseEvent.MOUSE_WHEEL, scrollWheel);
				obj.line.height = obj.txt_items.height;
				obj.bar.height = obj.line.height*(1-(itemList.length-8)/itemList.length);
			}
			else{
				obj.txt_items.height = obj.txt_items.textHeight;
				obj.bar.visible = false;
				obj.line.visible = false;
				obj.line.height = 4;
				obj.bar.height = 4;
				obj.txt_items.height = obj.txt_items.getLineMetrics(0).height*(obj.txt_items.numLines)+2;
				obj.txt_items.width = (obj == player ? 111.1 : 153.6);
				obj.txt_items.removeEventListener(MouseEvent.MOUSE_WHEEL, scrollWheel);
			}

			obj.bar.y = obj.line.y + (obj.txt_items.scrollV-1)*(obj.line.height-obj.bar.height)/(obj.txt_items.maxScrollV-2);
			if (obj.bar.y > obj.line.y + obj.line.height - obj.bar.height){
				obj.bar.y = obj.line.y + obj.line.height - obj.bar.height;
				obj.txt_items.scrollV--;
			}
			
			obj.frame.height = obj.txt_items.y + (obj.txt_items.height < 63.4 ? 63.4 : obj.txt_items.height) + 10.7;
			rect.width = obj.txt_items.width - 4;
		}

		public function updateNav():void{
			var nav:Nav = Room.getCurrent().getNav();

			for (var i:int = 0; i < navButtons.length; i++)
				if (navButtons[i]){
					if (nav.getRoom(i))
						navButtons[i].gotoAndStop(1);
					else
						navButtons[i].gotoAndStop(2);
				}
		}
		
		public function hideMenu():void{
			menu.visible = false;
		}
		
		public function resetMenu():void{
			menu.visible = true;
		}

		private static function toClass(... args):Class{
			return Class(getDefinitionByName(getQualifiedClassName(args[0])));
		}

		private static function empty(str:String):Boolean{
			return !str || trim(str).length == 0;
		}

		private static function trim(str:String):String{
			return (str ? str.replace(/^\s+|\s+$/g, "") : "");
		}

		public static function setNavSystem(nav:String):void{
			if (nav && nav.length > 0){
				nav = nav.toLowerCase();
				if (nav != navSystem && (nav == "compass" || nav == "cross")){
					navSystem = nav;
					if (ui){
						ui.removeNavListeners();
						ui.addNavListeners();
					}
				}
			}
		}

		public static function getNavSystem():String{
			return navSystem;
		}

		private function addNavListeners():void{
			if (navSystem == "compass"){
				navCross.visible = false;
				btn_in.x = navCompass.x + navCompass.width + 10;
				navButtons = new Array(navCompass.btn_north,navCompass.btn_northEast,navCompass.btn_east,navCompass.btn_southEast,
											  navCompass.btn_south,navCompass.btn_southWest,navCompass.btn_west,navCompass.btn_northWest,
											  navCompass.btn_up,navCompass.btn_down,btn_in,btn_out
					);
			}
			else{
				navCross.visible = true;
				btn_in.x = navCross.x + navCross.width + 10;
				navButtons = new Array(navCross.btn_forward,null,navCross.btn_right,null,navCross.btn_back,null,
											  navCross.btn_left,null,navCross.btn_up,navCross.btn_down,btn_in,btn_out
					);
			}
			navCompass.visible = !navCross.visible;

			for (var i:int = 0; i < navButtons.length; i++){
				if (navButtons[i]){
					navButtons[i].addEventListener(MouseEvent.CLICK,eventNavClick);				
					navButtons[i].addEventListener(MouseEvent.ROLL_OVER,eventNavOver);				
					navButtons[i].addEventListener(MouseEvent.ROLL_OUT,eventNavOut);				
				}
			}
		}

		private function removeNavListeners():void{
			for (var i:int = 0; i < navButtons.length; i++){
				if (navButtons[i]){
					navButtons[i].removeEventListener(MouseEvent.CLICK,eventNavClick);				
					navButtons[i].removeEventListener(MouseEvent.ROLL_OVER,eventNavOver);				
					navButtons[i].removeEventListener(MouseEvent.ROLL_OUT,eventNavOut);				
				}
			}
		}

		public static function getUI():Interface{
			return ui;
		}

		public function removeSelf():void{
			removeNavListeners();

			roomImageHolder.removeEventListener(MouseEvent.CLICK,eventMouseClick);
			roomImageHolder.removeEventListener(MouseEvent.ROLL_OVER,eventMouseOver);
			roomImageHolder.removeEventListener(MouseEvent.ROLL_OUT,eventMouseOut);
			player.imageHolder.removeEventListener(MouseEvent.CLICK,eventMouseClick);
			player.imageHolder.removeEventListener(MouseEvent.ROLL_OVER,eventMouseOver);
			player.imageHolder.removeEventListener(MouseEvent.ROLL_OUT,eventMouseOut);
			tooltipTimer.removeEventListener(TimerEvent.TIMER, showTooltip);
			removeEventListener(MouseEvent.CLICK,hideTooltip);
			removeEventListener(MouseEvent.MOUSE_WHEEL, charListWheel);

			charBar.removeEventListener(MouseEvent.MOUSE_DOWN,scrollDown);
			room.bar.removeEventListener(MouseEvent.MOUSE_DOWN,scrollDown);
			player.bar.removeEventListener(MouseEvent.MOUSE_DOWN,scrollDown);
			player.txt_items.removeEventListener(MouseEvent.MOUSE_WHEEL, scrollWheel);
			room.txt_items.removeEventListener(MouseEvent.MOUSE_WHEEL, scrollWheel);

			player.txt_items.removeEventListener(MouseEvent.MOUSE_MOVE, itemListMove);
			player.txt_items.removeEventListener(MouseEvent.CLICK, itemListClick);
			player.txt_items.removeEventListener(MouseEvent.ROLL_OUT, itemListOut);

			room.txt_items.removeEventListener(MouseEvent.MOUSE_MOVE, itemListMove);
			room.txt_items.removeEventListener(MouseEvent.CLICK, itemListClick);
			room.txt_items.removeEventListener(MouseEvent.ROLL_OUT, itemListOut);
			
			clearList(charList);
			clearList(playerItems);
			clearList(roomItems);

			ui = null;

			if (parent)
				parent.removeChild(this);
		}
	}
}