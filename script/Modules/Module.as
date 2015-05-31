package script.Modules{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.8.0 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2014 Drakkashi.com
	 */

	import script.*;
	import script.Modules.Default.*;
	import script.Modules.Customized.*;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getDefinitionByName;
	import flash.utils.describeType;
	import flash.xml.*;

	public class Module{
		
		private static var moduleList:Array = new Array(),
						   gameListeners:Array = new Array(),
						   roomListeners:Array = new Array(),
						   mouseListeners:Array = new Array(),
						   navListeners:Array = new Array();
		
		public static function importModules():Array{
			var classLoadList:Array = new Array(
					Background,
					GUI
				);

			var moduleList:Array = new Array(new Array(),new Array(),new Array());
			for each (var clss:Class in classLoadList){
				moduleList[0].push(getModuleID(clss));
				moduleList[1].push(getModuleFunctions(clss));
				moduleList[2].push(clss);
			}
			
			var types:Array = new Array("String","Boolean","int","Number","Array","*","Object","script::_Object","script::Item","script::Character","script::Room","script::Person","script::Container","script::Player");
			for (var i:int = 0; i < moduleList[0].length; i++){
				for each (var funcXML:XML in moduleList[1][i]){
					var paraList:Array = new Array();
					funcXML.parameter.(paraList.push(@type));
					
					for (var l:int = 0; l < paraList.length; l++){
						if (types.indexOf(String(paraList[l])) < 0){
							Output.err('Unsupported data type "' + paraList[l] + '" on parameter '+(l+1)+' of module function "' + moduleList[0][i] + "." + funcXML.@name + '". Unable to implement function.');
							moduleList[1][i].splice(moduleList[1][i].indexOf(funcXML),1);
							break;
						}
					}
				}
			}
			return moduleList;
		}

		public static function getModuleID(clss:Class):String{
			return getQualifiedClassName(clss).split("::")[1];
		}

		public static function getModuleFunctions(clss:Class):Array{
			var xml:XML = describeType(clss),
				b:Boolean = false,
				funcList:Array = new Array(),
				interfaceList:Array = new Array();

			for (var i:int = 0; i < xml.method.length(); i++){
				try{
					if (clss[xml.method[i].@name] != null)
						funcList.push(xml.method[i]);
				}
				catch(e:Error){}
			}

			if (xml.factory.length() > 0)
				xml.factory.implementsInterface.(interfaceList.push(@type.split("::")[1]));

			if (xml.factory.constructor.length() > 0 || interfaceList.indexOf("GameListener") >= 0 || interfaceList.indexOf("RoomListener") >= 0 || interfaceList.indexOf("MouseListener") >= 0 || interfaceList.indexOf("NavListener") >= 0){
				if (xml.factory.constructor.length() > 0 && xml.factory.constructor.parameter.(@optional=="false").length() > 0){
					Output.warn("Unable to construct module which have required parameters.");
					return funcList;
				}

				var module:* = new clss();
				moduleList.push(module);
				if (interfaceList.indexOf("GameListener") >= 0)
					gameListeners.push(module);
				if (interfaceList.indexOf("RoomListener") >= 0)
					roomListeners.push(module);
				if (interfaceList.indexOf("MouseListener") >= 0)
					mouseListeners.push(module);
				if (interfaceList.indexOf("NavListener") >= 0)
					navListeners.push(module);
			}

			return funcList;
		}

		public static function getGameListeners():Array{
			return gameListeners;
		}

		public static function getRoomListeners():Array{
			return roomListeners;
		}

		public static function getMouseListeners():Array{
			return mouseListeners;
		}

		public static function getNavListeners():Array{
			return navListeners;
		}
	}
}