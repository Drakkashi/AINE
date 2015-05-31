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
	import flash.utils.getQualifiedClassName;
	import flash.utils.getDefinitionByName;
	import flash.events.Event;

	public class _Object extends MovieClip{

		protected var instance:String,
					  displayName:String,
					  image:String,
					  desc:String,
					  tooltip:String,
					  varList:Array = new Array(new Array(), new Array()),
					  eventList:Array = new Array(),
					  customList:Array = new Array();

		protected function getInstance():String{
			return instance;
		}

		public function setName(str:String):void{
			if(!empty(str))
				displayName = str;
		}

		public function getName():String{
			return displayName;
		}

		public function setImage(str:String):void{
			if (Image.getImage(str))
				image = str;
			else{
				if (!empty(str))
					Output.warn('Image "'+str+'" not found.');
				image = null;
			}
		}

		public function getImage():String{
			return image;
		}

		public function setDesc(str:String):void{
			desc = str;
		}

		public function getDesc():String{
			return desc;
		}

		public function setTooltip(str:String):void{
			tooltip = str;
		}

		public function getTooltip():String{
			if (!empty(tooltip))
				return tooltip;
			if (!empty(getDesc()))
				return getDesc();
			return getName();
		}

		public function getEventLists():Array{
			return new Array(cloneArray(eventList),cloneArray(customList));
		}

		public function extendsObject(obj:_Object):void{
			var evtList:Array = obj.getEventLists(),
				evtHolder:_Event;
			
			for (var i:int = 0; i < evtList[0].length; i++)
				if (evtList[0][i] && (!eventList[i] || !eventList[i].getOverride())){
					evtHolder = eventList[i];
					eventList[i] = evtList[0][i].clone(this);

					if (evtHolder){
						eventList[i].addScript(evtHolder.getScript());
						if (eventList[i].isEnabled() != evtHolder.isEnabled())
							eventList[i].toggle();
					}
					
					if (String(evtList[0][i].getEvent()) == "Game_Start")
						_Event.addGameStart(this);
				}
			
			for (i = 0; i < evtList[1].length; i++){
				evtHolder = getEvent(evtList[1][i].getEvent());
				
				if (!evtHolder)
					addEvent(evtList[1][i].clone(this))
				else if (!evtHolder.getOverride()){
					customList[customList.index(evtHolder)] = evtList[1][i].clone(this);
					addEvent(evtHolder);
				}
			}
		}

		public function setVar(id:String,val:*, ... args):String{
			var str:String = (toClass(val) == Array ? listToStr(val) : null);

			if (id == "name"){
				if (val == null)
					setName(null);
				else
					setName((str ? str : String(val)));
			}
			else if (id == "image"){
				if (val == null)
					setImage(null);
				else
					setImage((str ? str : String(val)));
			}
			else if (id == "desc"){
				if (val == null)
					setDesc(null);
				else
					setDesc((str ? str : String(val)));
			}
			else if (id == "tooltip"){
				if (val == null)
					setTooltip(null);
				else
					setTooltip((str ? str : String(val)));
			}
			else{
				var index:int = varList[0].indexOf(trim(id));

				if (index < 0){
					varList[0].push(id);
					varList[1].push(val);
				}
				else
					varList[1][index] = val;
			}
			return null;
		}

		public function hasVar(str:String):Boolean{
			return new Array("name","image","desc","tooltip").concat(varList[0]).indexOf(str) >= 0;
		}

		public function getVar(str:String):*{
			if (str == "name")
				return getName();
			if (str == "image")
				return getImage();
			if (str == "desc")
				return getDesc();
			if (str == "tooltip")
				return getTooltip();

			var index:int = varList[0].indexOf(str);
			if (index < 0)
				return null;
			else
				return varList[1][index];
		}

		override public function toString():String{
			return getInstance();
		}

		public function getCustomList():Array{
			var list:Array = new Array();

			for (var i:int = 0; i < customList.length; i++)
				if (customList[i].isEnabled())
					list.push(customList[i]);
					
			return list;
		}

		public function showEvents():void{
			Interface.getUI().showEvents(this);
		}

		public function getEvent(evt:*):_Event{
			var list:Array = (toClass(evt) == EventListener ? eventList : customList);
			for (var i:int = 0; i < list.length; i++)
				if (list[i] && list[i].getEvent() == String(evt))
					return list[i];
			return null;
		}

		public function isEnabled(val:*):Boolean{
			var evt:_Event = getEvent((toClass(val) == Array ? val[0] : val));
			if (!evt){
				Output.warn("Unable to check state of undefined Event.");
				return false;
			}
			return evt.isEnabled();
		}

		public function trigger(val:*):void{
			var evt:_Event = getEvent((toClass(val) == Array ? val[0] : val));
			evt.insert();
		}

		public function enableEvent(val:*):void{
			var evt:_Event = getEvent((toClass(val) == Array ? val[0] : val));

			if (evt)
				evt.enable();
		}

		public function disableEvent(val:*):void{
			var evt:_Event = getEvent((toClass(val) == Array ? val[0] : val));
			
			if (evt)
				evt.disable();
		}

		public function addEvent(newEvt:_Event):void{
			var evt:_Event = getEvent(newEvt.getEvent());

			if (evt && newEvt.getOverride()){
				if (eventList.indexOf(evt) >= 0)
					eventList[eventList.indexOf(evt)] = newEvt;
				else
					customList[customList.indexOf(evt)] = newEvt;
			}
			else if (evt){
				evt.addScript(newEvt.getScript());
				if (evt.isEnabled() != newEvt.isEnabled())
					evt.toggle();
			}
			else{
				if (toClass(newEvt.getEvent()) == EventListener)
					eventList[getListeners().indexOf(String(newEvt.getEvent()))] = newEvt;
				else
					customList.push(newEvt);
			}
			
			if (toClass(newEvt.getEvent()) == EventListener && String(newEvt.getEvent()) == "Game_Start")
				_Event.addGameStart(this);
		}

		public function getListeners():Array{
			return new Array(
						"Enter_Room_First","Leave_Room_First","Enter_Room","Leave_Room",
						"Mouse_Over","Mouse_Out","Mouse_Click","Game_Start"
					);
		}

		public function getMethods():Array{
			return new Array("setName","getName","setImage","getImage","setDesc","getDesc","setTooltip","getTooltip","enableEvent","disableEvent","trigger","isEnabled",'showEvents');
		}

		public function getClass():Class{
			return Class(getDefinitionByName(getQualifiedClassName(this)));
		}

		protected static function toClass(instance:*):Class{
			if (!instance)
				return null;
			return Class(getDefinitionByName(getQualifiedClassName(instance)));
		}

		protected static function empty(str:String):Boolean{
			return !str || trim(str).length == 0;
		}

		protected function listToStr(list:Array):String{
			var str:String = "";
	
			for(var i:int = 0; i < list.length; i++)
				str += String(list[i]);

			return str;
		}

		protected static function trim(str:String):String{
			return (str ? str.replace(/^\s+|\s+$/g, "") : "");
		}

		protected static function cloneArray(array:Object):Array {
			return array.concat();
		}

		public static function getObject(str:String):_Object{
			if (!str)
				return null;

			var obj:_Object = Player.getPlayer(str);

			if (!obj)
				obj = Item.getItem(str);
			
			if (!obj)
				obj = Room.getRoom(str);

			if (!obj)
				obj = Character.getCharacter(str);
				
			if (!obj)
				obj = GenericObject.getObject(str);

			return obj;
		}

		protected static function toRef(input:*):*{
			if (!input)	
				return input;
			if (toClass(input) == Array){
				var arr:Array = new Array();
				for (var i:int = 0; i < input.length; i++)
					arr[i] = toRef(input[i]);
				return arr;
			}
			if (toClass(input) == Object)
				return getObject(input.str);
			return input;
		}

		protected static function toPointer(input:*):*{
			if (!input)	
				return input;
			if (toClass(input) == Array){
				var arr:Array = new Array();
				for (var i:int = 0; i < input.length; i++)
					arr[i] = toPointer(input[i]);
				return arr;
			}
			if (Implementor.isObject(input))
				return new Pointer(String(input));
			return input;
		}

		public function loadDataArray(arr:Array):void{
			setName(arr[1]);
			setImage(arr[2]);
			setDesc(arr[3]);
			setTooltip(arr[4]);
			
			for each (var varEntry:Array in arr[5])
				setVar(varEntry[0],toRef(varEntry[1]));
			
			for (var i:int = 0; i < eventList.length; i++)
				if (arr[6][i] && eventList[i])
					eventList[i].enable();

			for (i = 0; i < arr[7].length; i++){
				var evt:_Event = getEvent(arr[7][i]);

				if (evt)
					evt.enable();
			}
		}

		public function getDataArray():Array{
			var arr:Array = new Array(
						instance,
						getName(),
						getImage(),
						getDesc(),
						getTooltip()
					);

			var vars:Array = new Array();
			for (var i:int = 0; i < varList[0].length; i++)
				vars.push(new Array(varList[0][i],toPointer(varList[1][i])));
			arr.push(vars);

			var events = new Array();
			for (i = 0; i < eventList.length; i++)
				if (eventList[i] && eventList[i].isEnabled())
					events[i] = true;
			arr.push(events);

			var customEvents = new Array();
			for (i = 0; i < customList.length; i++)
				if (customList[i].isEnabled())
					customEvents.push(String(customList[i]));
			arr.push(customEvents);

			return arr;
		}

		public function reset():void{
			displayName = instance;
			image = null;
			desc = null;
			tooltip = null;
			varList = new Array(new Array(), new Array());

			for (var i:int = 0; i < eventList.length; i++)
				if (eventList[i])
					eventList[i].disable();

			for (i = 0; i < customList.length; i++)
				customList[i].disable();
		}

		public function removeSelf():void{
			if (parent)
				parent.removeChild(this);
		}
	}
}