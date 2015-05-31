package script{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.9.0 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2015 Drakkashi.com
	 */

	import flash.utils.getTimer;
	import flash.events.Event;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.events.MouseEvent;
	import flash.errors.ScriptTimeoutError;

	public class ScriptTimer extends MovieClip{
		
		private static var current:ScriptTimer;
			
		private var timeStamp:Number,
					processTotal:int,
					prevProcess:int,
					rect:Shape,
					prompt:Prompt;

		public function ScriptTimer(processTotal:int=0){
			this.processTotal = processTotal;
			timeStamp = getTimer();
			current = this;
		}

		public function scriptTimeout(err:ScriptTimeoutError):void{
			_Event.clearList();
			Output.print(err.message);

			if (parent){
				parent.removeChild(this);
				removeEventListener(Event.ENTER_FRAME,loop);
			}

			prompt = new Prompt("ScriptTimeoutError",err.message);
			prompt.btn_yes.visible = false;
			prompt.btn_no.visible = false;
			Engine.getStage().addEventListener(MouseEvent.CLICK,removePrompt);
		}

		private function removePrompt(e:MouseEvent):void{
			e.currentTarget.removeEventListener(MouseEvent.CLICK,removePrompt);
			prompt.removeSelf();
			removeSelf();
		}

		public function showProcess(process:int=0):void{
			if (!parent){
				prevProcess = processTotal;
				x = (Engine.getWidth()-width)/2;
				y = (Engine.getHeight()-height)/2;
				bar.width = 0;
				Engine.getStage().addChild(this);

				var rect = new Shape();
				rect.graphics.beginFill(0xFFFFFF,0);
				rect.graphics.drawRect(0,0,Engine.getWidth(),Engine.getHeight());
				rect.graphics.endFill();
				rect.x -= x;
				rect.y -= y;
				addChild(rect);

				addEventListener(Event.ENTER_FRAME,init);
			}
			
			if (process < prevProcess)
				bar.width = (process == 0 ? tube.width : (tube.width/processTotal)*(processTotal-process) );

			prevProcess = process;
			timeStamp = getTimer();
		}

		public static function getCurrent():ScriptTimer{
			return current;
		}

		private function init(e:Event):void{
			removeEventListener(Event.ENTER_FRAME,init);
			addEventListener(Event.ENTER_FRAME,loop);
		}

		private function loop(e:Event):void{
			if (parent)
				parent.setChildIndex(this,parent.numChildren-1);
			_Event.resume();
		}

		public function removeSelf():void{
			if (parent)
				parent.removeChild(this);
			removeEventListener(Event.ENTER_FRAME,init);
			removeEventListener(Event.ENTER_FRAME,loop);
			current = null;
		}

		public function getTime():Number{
			return getTimer()-timeStamp;
		}
	}
}