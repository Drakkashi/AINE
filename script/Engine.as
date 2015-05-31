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
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import script.Modules.Module;
	
	public class Engine extends MovieClip{

		private static var gameTitle:String,
						   stageRef:Stage,
						   _width:Number,
						   _height:Number;

		public function Engine(){
			stage.scaleMode = StageScaleMode.SHOW_ALL;
			stage.quality = StageQuality.BEST;
			gotoAndStop(0);
			_width = stage.stageWidth;
			_height = stage.stageHeight;
			stageRef = stage;
			Output.initConsole();
			var preloader:Preloader = new Preloader(this.loaderInfo);
			preloader.addEventListener("importAssets", loadAssets);
			preloader.addEventListener(Event.REMOVED_FROM_STAGE, preloaderComplete);
			stageRef.addChild(preloader);
		}

		private function loadAssets(e:Event):void {
			e.currentTarget.removeEventListener("importAssets", loadAssets);
			gotoAndPlay(2);
		}

		private static function preloaderComplete(e:Event):void {
			e.currentTarget.removeEventListener(Event.REMOVED_FROM_STAGE, preloaderComplete);

			var ui:Interface = Interface.getUI();
			if (!ui)
				new Interface();
			else
				ui.updateRoom();

			for each (var module:* in Module.getGameListeners())
				module._start();

			_Event.eventGameStart();
		}

		public static function endGame():void {
			var prompt:GameOver = GameOver.getCurrent();
			
			if (!prompt){
				new GameOver();
				Interface.getUI().hideMenu();				
			}
			else
				prompt.toggle();
		}

		public static function newGame():void {
			for each (var module:* in Module.getGameListeners())
				module._new();

			Player.getPlayer().removeSelf();
			Item.clearList();
			Character.clearList();
			Room.clearList();
			Nav.clearList();
			Image.clearList();
			GenericObject.clearList();
			ScreenMessage.clearList();

			if (Display.getCurrent())
				Display.getCurrent().removeSelf();
				
			Interface.getUI().removeSelf();

			var preloader:Preloader = new Preloader();
			preloader.addEventListener(Event.REMOVED_FROM_STAGE, preloaderComplete);
			stageRef.addChild(preloader);
		}

		public static function setTitle(str:String):void {
			if (!gameTitle){
				str = getValidTitle(str);
				
				if (str.length > 0){
					gameTitle = str;
					SaveHandler.setSaveDir(gameTitle);
				}
			}
		}

		public static function getWidth():Number {
			return _width;
		}

		public static function getHeight():Number {
			return _height;
		}

		public static function getTitle():String {
			return gameTitle;
		}

		public static function getValidTitle(str:String):String{
			return str.replace(/[\s~%&;:"',<>?#]/g, "");
		}

		public static function getStage():Stage {
			return stageRef;
		}
	}
}