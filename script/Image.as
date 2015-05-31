package script{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.8.0 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2014 Drakkashi.com
	 */

	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;

	public class Image{

		private static var list:Array = new Array();
		
		private var str:String,
					img:Bitmap;

		public function Image(str:String, img:Bitmap){
			this.str = str;
			this.img = img;
			list.push(this);
		}

		public function toString():String{
			return str;
		}

		public function cloneImage():Bitmap{
			var image:Bitmap = new Bitmap(img.bitmapData);
			image.smoothing = true;
			return image;
		}

		public static function getImage(str:String):Bitmap{
			for each (var image:Image in list)
				if (String(image) == str)
					return image.cloneImage();
			return null;
		}

		public static function cropImage(image:Bitmap):Bitmap{
			var scale_x:Number = image.scaleX,
				scale_y:Number = image.scaleY;
			image.scaleX = 1;
			image.scaleY = 1;
			image.x = image.x*1/scale_x;
			image.y = image.y*1/scale_y;

			var sourceBitmapContainer:Sprite = new Sprite();
			sourceBitmapContainer.addChild(image);

			var finalBitmapData:BitmapData = new BitmapData(image.width+image.x*2, image.height+image.y*2, true, 0x00ffffff);
			finalBitmapData.draw(sourceBitmapContainer);

			image = new Bitmap(finalBitmapData);
			image.smoothing = true;
			image.scaleX = scale_x;
			image.scaleY = scale_y;
			return image;
		}

		public static function clearList():void{
			list = new Array();
		}
	}
}