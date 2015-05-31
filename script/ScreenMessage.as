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
    import flash.filters.GlowFilter;
	import flash.filters.BitmapFilterQuality;
    import flash.utils.Timer;
    import flash.events.TimerEvent;
	import flash.text.Font;
	import flash.text.TextFormat;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.AntiAliasType;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.None;

	public class ScreenMessage extends MovieClip{

		private static var list:Array = new Array();
		private static const MAX_NUM:int = 4;

		private var tween:Tween,
					timer:Timer,
					txtField:TextField = new TextField();

		public function ScreenMessage(str:String,time:Number){
			mouseEnabled = false;
			mouseChildren = false;

			var font:Font = new Font5(),
				format:TextFormat = new TextFormat(),
				glowFilter:GlowFilter = new GlowFilter();

			glowFilter.color = 0x000000;
			glowFilter.quality = BitmapFilterQuality.HIGH;
			glowFilter.blurX = 3;
			glowFilter.blurY = 3;
			glowFilter.alpha = 0.66;
			glowFilter.strength = 12;
			this.filters = [glowFilter];

			format.size = 14;
			format.font = font.fontName;
			txtField.embedFonts = true;
			txtField.textColor = 0xffffff;
			txtField.defaultTextFormat = format;
			txtField.htmlText = str;
			txtField.autoSize = TextFieldAutoSize.LEFT;
			txtField.antiAliasType = AntiAliasType.ADVANCED;
			addChild(txtField);

			x = (Engine.getWidth()-width)/2;
			y = Engine.getHeight()/3-height*2;

			list = new Array(this).concat(list);
			while (list.length > MAX_NUM)
				list[list.length-1].removeSelf();

			for (var i:int = 1; i < list.length; i++)
				list[i].y = list[i-1].y + list[i-1].height;

			if (time < 0){
				time = 1000 + txtField.text.length*50;
				if (time > 3500)
					time = 3500;
			}
			else
				time *= 1000;

			timer = new Timer(time,0);
			timer.addEventListener(TimerEvent.TIMER, pendingRemoval);
			timer.start();
			Interface.getUI().addChild(this);
		}

		private function pendingRemoval(e:TimerEvent):void {
			timer.stop();
			timer.removeEventListener(TimerEvent.TIMER, pendingRemoval);
			tween = new Tween(this,"alpha",None.easeNone,1,0,0.7,true);
			tween.addEventListener(TweenEvent.MOTION_FINISH, removeSelf);
		}

		public function removeSelf(e:TweenEvent=null):void {
			list.splice(list.indexOf(this),1);

			if (tween)
				tween.removeEventListener(TweenEvent.MOTION_FINISH, removeSelf);

			timer.stop();
			timer.removeEventListener(TimerEvent.TIMER, pendingRemoval);

			if (parent)
				parent.removeChild(this);
		}

		public static function clearList():void {
			while(list.length > 0)
				list[0].removeSelf();
		}
	}
}