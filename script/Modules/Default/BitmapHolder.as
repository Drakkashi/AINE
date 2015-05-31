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
	import script.Modules.Module;
	import flash.display.MovieClip;
	import flash.display.Bitmap;
	import flash.events.MouseEvent;

	public class BitmapHolder extends MovieClip{
		
		private var bitmap:Bitmap,
					obj:_Object;
		
		public function BitmapHolder(bitmap:Bitmap,obj:_Object){
			this.bitmap = bitmap;
			this.obj = obj;
			addChild(bitmap);
			addEventListener(MouseEvent.CLICK,eventMouseClick);
			addEventListener(MouseEvent.ROLL_OVER,eventMouseOver);
			addEventListener(MouseEvent.ROLL_OUT,eventMouseOut);
		}
		
		public function getBitmap():Bitmap{
			return bitmap;
		}

		private function eventMouseClick(e:MouseEvent):void{
			for each (var module:* in Module.getMouseListeners())
				module._mouseClick(obj);
			_Event.eventInterface(obj,"Mouse_Click");
		}

		private function eventMouseOver(e:MouseEvent):void{
			for each (var module:* in Module.getMouseListeners())
				module._mouseOver(obj);

			_Event.eventInterface(obj,"Mouse_Over");
		}

		private function eventMouseOut(e:MouseEvent):void{
			for each (var module:* in Module.getMouseListeners())
				module._mouseOut(obj);

			_Event.eventInterface(obj,"Mouse_Out");
		}

		public function removeSelf():void{
			if (parent)
				parent.removeChild(this);

			removeEventListener(MouseEvent.CLICK,eventMouseClick);
			removeEventListener(MouseEvent.CLICK,eventMouseOver);
			removeEventListener(MouseEvent.CLICK,eventMouseOut);
		}
	}
}