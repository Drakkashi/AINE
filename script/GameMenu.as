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
	import flash.events.MouseEvent;
	import flash.events.Event;

	public class GameMenu extends MovieClip{

		private var buttonList:Array;

		public function GameMenu(){
			if (Engine.getTitle())
				buttonList = new Array(btn_new,btn_save,btn_load);
			else{
				buttonList = new Array(btn_new);
				btn_save.visible = false;
				btn_load.visible = false;
			}

			for (var i:int = 0; i < buttonList.length; i++){
				buttonList[i].stop();
				buttonList[i].addEventListener(MouseEvent.ROLL_OVER,btn_over);
				buttonList[i].addEventListener(MouseEvent.ROLL_OUT,btn_out);
				buttonList[i].addEventListener(MouseEvent.CLICK,btn_click);
			}
		}

		private function btn_over(e:MouseEvent):void{
			e.currentTarget.gotoAndStop(2);
		}

		private function btn_out(e:MouseEvent):void{
			e.currentTarget.gotoAndStop(1);
		}

		private function btn_click(e:MouseEvent):void{
			var index:int = buttonList.indexOf(e.currentTarget);

			if (index == 0){
				var prompt:Prompt = new Prompt("New Game","Would you want to start a new game?");
				prompt.addEventListener("yes", promptYes);
				prompt.addEventListener(Event.REMOVED_FROM_STAGE, promptClose);
			}
			else
				new SaveHandler(index);
		}

		private function promptYes(e:Event):void{
			Engine.newGame();
		}

		private function promptClose(e:Event):void{
			e.currentTarget.removeEventListener("yes", promptYes);
			e.currentTarget.removeEventListener(Event.REMOVED_FROM_STAGE, promptClose);
		}

		private function removeSelf():void{
			for (var i:int = 0; i < buttonList.length; i++){
				buttonList[i].removeEventListener(MouseEvent.ROLL_OVER,btn_over);
				buttonList[i].removeEventListener(MouseEvent.ROLL_OUT,btn_out);
				buttonList[i].removeEventListener(MouseEvent.CLICK,btn_click);
			}
		}
	}
}