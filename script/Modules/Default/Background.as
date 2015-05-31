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
    import flash.display.Shape;
    import flash.display.Graphics;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Stage;

	public class Background{

		public static function color(str:String):*{
			var color:Number;
			
			if (str.indexOf("0x") == 0)
				color = parseInt(str);
			else if (str.indexOf("#") == 0)
				color = parseInt(str.substr(1),16);
			else
				color = parseInt(str);
			
			if (isNaN(color))
				return new Output("Invalid color");

			if (!Image.getImage(str)){
				var rect:Shape = new Shape(),
					stageWidth:int = Engine.getStage().stageWidth,
					stageHeight:int = Engine.getStage().stageHeight;

				rect.graphics.beginFill(color,1);
				rect.graphics.drawRect(0,0,stageWidth,stageHeight);
				rect.graphics.endFill();

				var bd:BitmapData = new BitmapData(stageWidth, stageHeight);
				bd.draw(rect);
				new Image(str,new Bitmap(bd));
			}
			return str;
		}

		public static function white():String{
			return color("#ffffff");
		}

		public static function black():String{
			return color("#000000");
		}
	}
}