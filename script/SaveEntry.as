package script{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.6.1 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2014 Drakkashi.com
	 */

	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.events.Event;

	public class SaveEntry extends MovieClip{

		public var btnList:Array,
				   str:String,
				   dir:String,
				   layout:int,
				   index:int,
				   roomName:String,
				   roomImage:String,
				   playerDesc:String,
				   playerImage:String,
				   playerGender:String;

		public function SaveEntry(str:String, dir:String, layout:int, index:int = -1, preview:Array = null){
			this.str = str;
			this.dir = dir;
			this.layout = layout;
			this.index = index;

			if (preview){
				roomName = preview[0];
				roomImage = preview[1];
				playerDesc = preview[2];
				playerImage = preview[3];
				playerGender = preview[4];
			}
			else{
				var room:Room = Room.getCurrent();
				roomName = room.getName();
				roomImage = room.getImage();
				
				var player:Player = Player.getPlayer();
				playerDesc = player.getName()+"\n\n"+player.getDesc();
				playerImage = player.getImage();
				playerGender = player.getGender();
			}
			
			txt_entry.text = str;
			background.stop();
			y = 4 + height*index;

			if (layout == 2)
				btn_act.htmlText = "<b>Load</b>";

			btnList = new Array(btn_act,btn_delete);
			for (var i:int = 0; i < btnList.length;i++){
				btnList[i].addEventListener(MouseEvent.ROLL_OVER,btn_over);
				btnList[i].addEventListener(MouseEvent.ROLL_OUT,btn_out);
				btnList[i].addEventListener(MouseEvent.CLICK,btn_click);
			}
		}

		public function getName():String{
			return str;
		}

		public function getDir():String{
			return dir;
		}

		public function getIndex():int{
			return index;
		}

		public function getRoomName():String{
			return roomName;
		}

		public function getRoomImage():String{
			return roomImage;
		}

		public function getPlayerDesc():String{
			return playerDesc;
		}

		public function getPlayerImage():String{
			return playerImage;
		}

		public function getPlayerGender():String{
			return playerGender;
		}

		public function getPreview():Array{
			return new Array(roomName,roomImage,playerDesc,playerImage,playerGender);
		}

		private function btn_over(e:MouseEvent):void{
			e.currentTarget.htmlText = "<font color='#FFFFFF'><b>" + e.currentTarget.text + "</b></font>";
		}

		private function btn_out(e:MouseEvent):void{
			e.currentTarget.htmlText = "<font color='#CCCCCC'><b>" + e.currentTarget.text + "</b></font>";
		}

		private function btn_click(e:MouseEvent):void{
			var index:int = btnList.indexOf(e.currentTarget);

			if (index == 0)
				dispatchEvent(new Event((layout == 2 ? "load" : "save")));
			else
				dispatchEvent(new Event("delete"));
		}

		public function removeSelf():void{
			for (var i:int = 0; i < btnList.length;i++){
				btnList[i].removeEventListener(MouseEvent.ROLL_OVER,btn_over);
				btnList[i].removeEventListener(MouseEvent.ROLL_OUT,btn_out);
				btnList[i].removeEventListener(MouseEvent.CLICK,btn_click);
			}

			if (parent)
				parent.removeChild(this);
		}
	}
}