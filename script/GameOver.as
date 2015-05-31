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
	import flash.ui.Keyboard;
	import flash.display.Stage;

	public class GameOver extends MovieClip{

		private static var current:GameOver;

		private var buttonList:Array,
					stageRef:Stage;

		public function GameOver(){
			stageRef = Engine.getStage();

			buttonList = new Array(btn_new,btn_load,btn_close);
			x = (Engine.getWidth()-width)/2;
			y = (Engine.getHeight()-height)/2;

			for (var i:int = 0; i < buttonList.length; i++){
				buttonList[i].gotoAndStop(1);
				buttonList[i].addEventListener(MouseEvent.ROLL_OVER,btn_over);
				buttonList[i].addEventListener(MouseEvent.ROLL_OUT,btn_out);
				buttonList[i].addEventListener(MouseEvent.CLICK,btn_click);
			}
			
			current = this;
			stageRef.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			stageRef.addChild(this);
		}

		private function btn_over(e:MouseEvent):void{
			e.currentTarget.gotoAndStop(2);
		}

		private function btn_out(e:MouseEvent):void{
			e.currentTarget.gotoAndStop(1);
		}

		private function btn_click(e:MouseEvent):void{
			var index:int = buttonList.indexOf(e.currentTarget);

			if (index < 2){
				if (index == 0)
					Engine.newGame();
				else if (index == 1)
					new SaveHandler(2);
				removeSelf();
			}
			else
				toggle();
		}

		public static function getCurrent():GameOver{
			return current;
		}

		public function toggle():void{
			visible = !visible;
		}

		private function keyDown(e:KeyboardEvent):void{
			if (e.keyCode == Keyboard.ESCAPE)
				visible = false;
		}

		public function removeSelf():void{
			stageRef.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);

			for (var i:int = 0; i < buttonList.length; i++){
				buttonList[i].removeEventListener(MouseEvent.ROLL_OVER,btn_over);
				buttonList[i].removeEventListener(MouseEvent.ROLL_OUT,btn_out);
				buttonList[i].removeEventListener(MouseEvent.CLICK,btn_click);
			}
			
			current = null;

			if (parent)
				parent.removeChild(this);
		}
	}
}