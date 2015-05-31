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
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;
	import flash.display.Bitmap;

	public class Preloader extends MovieClip{

		private static var dir:String;

		private var loadInfo:LoaderInfo,
					imageInfoList:Array = new Array(),
					imageList:Array = new Array(),
					loadList:Array = new Array(),
					dirList:Array = new Array(),
					dataList:Array = new Array(),
					configFile:XML,
					assetsComplete:Boolean,
					dataComplete:Boolean,
					imagesComplete:Boolean;

		public function Preloader(loadInfo:LoaderInfo = null){
			if (!loadInfo)
				assetsComplete = true;
			else
				this.loadInfo = loadInfo;

			x = (Engine.getWidth()-width)/2;
			y = (Engine.getHeight()-height)/2;

			if (!dir)
				dir = "config.xml";

			var xmlLoader = new URLLoader();
			xmlLoader.addEventListener(Event.COMPLETE, processConfig);
			xmlLoader.addEventListener(IOErrorEvent.IO_ERROR, configError);
			xmlLoader.load(new URLRequest(dir));

			addEventListener(Event.ENTER_FRAME, loop);
		}

		private function processConfig(e:Event):void {
			e.currentTarget.removeEventListener(Event.COMPLETE, processConfig);
			e.currentTarget.removeEventListener(IOErrorEvent.IO_ERROR, configError);
			configFile = new XML(e.target.data);
			
			if (configFile.Game.@title.length() > 0){
				Engine.setTitle(configFile.Game.@title);
				Interface.setNavSystem(configFile.Game.@nav);
			}

			for (var i:int = 0; i < configFile.Load.length(); i++){
				loadList.push(new URLLoader());
				loadList[i].addEventListener(Event.COMPLETE, processData);
				loadList[i].addEventListener(IOErrorEvent.IO_ERROR, dataError);
				loadList[i].load(new URLRequest(configFile.Load[i].@dir));
				dirList.push(configFile.Load[i].@dir);
			}

			txt_dataStatus.text = "loading:";

			for (i = 0; i < configFile.Image.length(); i++){
				var imageFile:String = configFile.Image[i].@dir,
					imageName:String = (configFile.Image[i].@name.length() > 0 ? configFile.Image[i].@name : imageFile.split("/")[imageFile.split("/").length-1].split(".")[0]);

				if (imageList.indexOf(imageName) < 0 && imageFile.length > 0){
					var imageLoader:Loader = new Loader();
					imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, processImage);
					imageLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, imageError);
					imageLoader.load(new URLRequest(imageFile));
					imageInfoList.push(imageLoader.contentLoaderInfo);
					imageList.push(imageName);
				}
				else if (imageFile.length > 0)
					Output.err('Instances of Image with the same name "' + imageName + '".');
				else
					Output.err("Image has to have a directory dir.");
			}

			if (imageList.length == 0){
				txt_imagesProcess.text = "100%";
				txt_imagesStatus.text = "complete:";
				imagesComplete = true;
			}
			else
				txt_imagesStatus.text = "loading:";
		}

		private function processImage(e:Event):void {
			var imageName:String = imageList[imageInfoList.indexOf(e.currentTarget)];
			new Image(imageName,new Bitmap(e.currentTarget.content.bitmapData));
			e.currentTarget.removeEventListener(Event.COMPLETE, processImage);
			e.currentTarget.removeEventListener(IOErrorEvent.IO_ERROR, imageError);
		}

		private function processData(e:Event):void {
			e.currentTarget.removeEventListener(Event.COMPLETE, processData);
			e.currentTarget.removeEventListener(IOErrorEvent.IO_ERROR, dataError);

			var index:int = loadList.indexOf(e.currentTarget);
			dataList[index] = String(e.target.data);
			loadList[index] = null;
		}

		private function loop(e:Event=null):void{
			var str:String;

			if (!assetsComplete){
				var loadProcess:Number = (loadInfo.bytesTotal != 0 ? loadInfo.bytesLoaded / loadInfo.bytesTotal : 1);

				str = String(Math.floor(loadProcess*100));
				if (str != "NaN")
					txt_interfaceProcess.text = str + "%";

				if (loadProcess == 1){
					txt_interfaceStatus.text = "complete:";
					assetsComplete = true;
					dispatchEvent(new Event("importAssets"));
				}
			}
			else{
				txt_interfaceProcess.text = "100%";
				txt_interfaceStatus.text = "complete:";
			}

			if (!dataComplete && configFile){
				var count:int = 0;
				loadProcess = 0;
				for (var i:int = 0; i < loadList.length; i++)
					if (loadList[i]){
						count++;
						loadProcess += loadList[i].bytesLoaded / loadList[i].bytesTotal;
					}

				str = String(Math.floor(loadProcess / count*100));
				if (str != "NaN")
					txt_dataProcess.text = str + "%";

				if (count == 0){
					txt_dataStatus.text = "complete:";
					dataComplete = true;
				}
			}
			else if (configFile)
				txt_dataProcess.text = "100%";

			if (!imagesComplete && configFile){
				loadProcess = 0;
				for (i = 0; i < imageInfoList.length; i++)
					loadProcess += imageInfoList[i].bytesLoaded / imageInfoList[i].bytesTotal;

				str = String(Math.floor((loadProcess / imageInfoList.length)*100));
				if (str != "NaN")
					txt_imagesProcess.text = str + "%";

				if (loadProcess / imageInfoList.length == 1 || imageInfoList.length == 0){
					txt_imagesStatus.text = "complete:";
					imagesComplete = true;
				}
			}
			else if (assetsComplete && dataComplete && imagesComplete && parent){
				removeEventListener(Event.ENTER_FRAME, loop);
				Implementor.importObjects(dataList,dirList);
				parent.removeChild(this);
			}
		}

		private function configError(e:IOErrorEvent):void {
			Output.err("Unable to load config file.");
			txt_dataStatus.text = "aborted:";
		}

		private function dataError(e:IOErrorEvent):void {
			Output.err('Unable to load data file: ' + dirList[loadList.indexOf(e.currentTarget)]);
			txt_dataStatus.text = "aborted:";
		}

		private function imageError(e:IOErrorEvent):void {
			var index:int = imageInfoList.indexOf(e.currentTarget);
			Output.err('Unable to load image file: ' + imageList[index]);
			imageList.splice(index,1);
			imageInfoList.splice(index,1);
		}

		public static function setConfig(str:String):void{
			if (!dir)
				dir = str;
		}
	}
}