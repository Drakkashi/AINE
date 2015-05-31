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
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.KeyboardEvent;
	import flash.text.TextFieldAutoSize;
	import flash.ui.Keyboard;
	import flash.display.Stage;

	public class Prompt extends MovieClip{

		private var buttonList:Array,
					stageRef:Stage,
					ui:Interface;

		public function Prompt(strTitle:String,strMessage:String){
			stageRef = Engine.getStage();
			
			buttonList = new Array(btn_yes,btn_no);
			txt_title.text = strTitle;
			txt_message.htmlText = strMessage;
			txt_message.autoSize = TextFieldAutoSize.LEFT;

			ui = Interface.getUI();
			ui.mouseEnabled = false;
			ui.mouseChildren = false;

			for (var i:int = 0; i < buttonList.length; i++){
				buttonList[i].y = txt_message.y + txt_message.height +10;
				buttonList[i].stop();
				buttonList[i].addEventListener(MouseEvent.ROLL_OVER,btn_over);
				buttonList[i].addEventListener(MouseEvent.ROLL_OUT,btn_out);
				buttonList[i].addEventListener(MouseEvent.CLICK,btn_click);
			}

			background.height = buttonList[0].y + buttonList[0].height +10;
			x = (Engine.getWidth() - width)/2;
			y = (Engine.getHeight() - height)/2;
			
			stageRef.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			stageRef.addChild(this);
			stageRef.focus = stageRef;
		}
		
		public function getTitle():String{
			return txt_title.text;
		}

		private function btn_over(e:MouseEvent):void{
			e.currentTarget.gotoAndStop(2);
		}

		private function btn_out(e:MouseEvent):void{
			e.currentTarget.gotoAndStop(1);
		}

		private function btn_click(e:MouseEvent):void{
			var index:int = buttonList.indexOf(e.currentTarget);

			if (index == 0)
				dispatchEvent(new Event("yes"));
			else
				dispatchEvent(new Event("no"));

			removeSelf();
		}

		private function keyDown(e:KeyboardEvent):void{
			if (e.keyCode == Keyboard.ESCAPE)
				removeSelf();
		}

		public function removeSelf():void {
			stageRef.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);

			for (var i:int = 0; i < buttonList.length; i++){
				buttonList[i].removeEventListener(MouseEvent.ROLL_OVER,btn_over);
				buttonList[i].removeEventListener(MouseEvent.ROLL_OUT,btn_out);
				buttonList[i].removeEventListener(MouseEvent.CLICK,btn_click);
			}

			if (ui){
				ui.mouseEnabled = true;
				ui.mouseChildren = true;
			}

			if (parent)
				parent.removeChild(this);
		}
	}
}