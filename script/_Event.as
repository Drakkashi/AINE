package script{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.9.0 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2015 Drakkashi.com
	 */

	import flash.utils.getQualifiedClassName;
	import flash.utils.getDefinitionByName;
	import script.Modules.Module;

	public class _Event{
		
		private static var eventList:Array = new Array(),
						   defaultList:Array = new Array(
									new Array("Mouse_Click","Mouse_Over","Mouse_Out","Nav_Click","Nav_Over","Nav_Out"),
									new Array(defaultMouseClick,defaultMouseOver,defaultMouseOut,defaultNavClick,defaultNavOver,defaultNavOut)
								),
						   leavingEvent:_Event,
						   leavingRoom:Room,
						   enterRoom:Room;

		private var evt:*,
					defaultFunc:Function,
					dataList:Array = new Array(),
					evtEnabled:Boolean,
					overriding:Boolean,
					object:_Object,
					implementor:Implementor;

		public function _Event(evt:*, scriptList:Array, evtEnabled:Boolean, overriding:Boolean, object:_Object){
			this.evt = evt;
			this.evtEnabled = evtEnabled;
			this.overriding = overriding;

			if (!overriding && toClass(evt) == EventListener && defaultList[0].indexOf(String(evt)) >= 0)
				defaultFunc = defaultList[1][defaultList[0].indexOf(String(evt))];

			this.object = object;
			addScript(scriptList);
		}
		
		public function getEvent():*{
			return evt;
		}
		
		public function getScript():Array{
			var clone:Array = new Array()
			
			for each (var arr:Array in dataList)
				clone.push(arr.concat());
			return clone;
		}
		
		public function getObject():_Object{
			return object;
		}
		
		public function isEnabled():Boolean{
			return evtEnabled;
		}
		
		public function getOverride():Boolean{
			return overriding;
		}
		
		public function setOverride(b:Boolean):void{
			overriding = b;
		}
		
		public function addScript(scriptList:Array):void{
			dataList.push(scriptList);
		}
		
		public function setScript(dataList:Array):void{
			this.dataList = dataList;
		}

		public function toggle():void{
			evtEnabled = !evtEnabled;
		}
		
		public function toString():String{
			return getEvent();
		}
		
		public function enable():void{
			evtEnabled = true
		}

		public function disable():void{
			evtEnabled = false;
		}

		public static function resume():void{
			var timer:ScriptTimer = ScriptTimer.getCurrent();

			if (!timer)
				timer = new ScriptTimer(eventList.length);

			while(eventList.length > 0 && eventList[0].trigger()){
				if (timer.getTime() > 1000){
					timer.showProcess(eventList.length);
					return;
				}
			};
			timer.removeSelf();
		}

		public function insert():void{
			eventList.unshift(clone());
		}

		public function trigger():Boolean{
			if (eventList.length > 0 && eventList.indexOf(this) < 0)
				eventList.push(this);
			else if (eventList.length == 0){
				eventList.push(this);
				resume();
			}
			else{
				if (implementor)
					implementor.resume();
				else
					implementor = new Implementor(getScript(),getObject());

				if (implementor){
					if (implementor.error())
						clearList();
					else if (!implementor.paused()){
						implementor = null;
						eventList.shift();
		
						if (this == leavingEvent && enterRoom){
							Room.setCurrent(enterRoom);
							_Event.eventEnterRoom();
						}
						else if (defaultFunc != null)
							defaultFunc(getObject());
		
						if (eventList.length > 0)
							return true;
						else
							leavingRoom = null;
					}
					else if (eventList.indexOf(this) > 0 || implementor.pending())
						return true;
				}
			}
			return false;
		}

		public static function addGameStart(obj:_Object):void{
			if (eventList.indexOf(obj) < 0)
				eventList.push(obj);
		}

		public static function eventGameStart():void{
			var i:int = 0;
			while (i < eventList.length){
				var evt:_Event = (eventList[i] as _Object).getEvent(new EventListener("Game_Start"));
				
				if (!evt || !evt.isEnabled())
					eventList.splice(i,1);
				else{
					eventList[i] = evt;
					i++;
				}
			}
			resume();
		}

		private static function triggerList(room:Room,i:int):void{

			var list:Array = new Array(),
				objList:Array = room.allObjects();

			for (var j:int = 0; j < objList.length; j++){
				var evt:_Event = objList[j].getEvent(new EventListener((i == 0 ? "Enter" : "Leave" )+"_Room_First"));

				if (!evt || !evt.isEnabled())
					evt = objList[j].getEvent(new EventListener((i == 0 ? "Enter" : "Leave" )+"_Room"));
				else
					evt.disable();

				if (evt)
					list.push(evt);
			}

			if (list.length > 0){

				if (eventList.length == 0){
					if (i == 1)
						leavingEvent = list[list.length-1];
					eventList = list;
					resume();
				}
				else{
					for (j = list.length -1; j >= 0; j--)
						list[j].insert();
					if (i == 1)
						leavingEvent = eventList[list.length-1];
				}
			}
			else if (i == 1 && enterRoom){
				Room.setCurrent(enterRoom);
				_Event.eventEnterRoom();
			}
		}

		public static function eventEnterRoom():void{
			clearEnterRoom();
			var room:Room = Room.getCurrent();
	
			for each (var module:* in Module.getRoomListeners())
				module._enter(room);

			triggerList(room,0);
		}

		public static function eventLeaveRoom(room:Room):void{
			enterRoom = room;
			if (!leavingRoom || leavingRoom != Room.getCurrent()){
				leavingRoom = Room.getCurrent();
	
				for each (var module:* in Module.getRoomListeners())
					module._leave(leavingRoom);

				triggerList(leavingRoom,1);
			}
		}

		public static function eventInterface(obj:_Object, str:String):void{
			var evt:_Event = obj.getEvent(new EventListener(str));

			if (evt){
				if (evt.isEnabled()){
					eventList.push(evt);
					resume();
				}
			}
			else
				defaultList[1][defaultList[0].indexOf(str)](obj);
		}

		private static function defaultNavClick(obj:_Object):void{
			(obj as Room).enterRoom();
		}

		private static function defaultNavOver(obj:_Object):void{
			Interface.getUI().setTooltipString(obj.getTooltip(),true);
		}

		private static function defaultNavOut(obj:_Object):void{
			Interface.getUI().hideTooltip();
		}

		private static function defaultMouseClick(obj:_Object):void{
			Interface.getUI().showEvents(obj);
		}

		private static function defaultMouseOver(obj:_Object):void{
			Interface.getUI().setTooltipString(obj.getTooltip(),true);
		}

		private static function defaultMouseOut(obj:_Object):void{
			Interface.getUI().hideTooltip();
		}

		public static function clearEnterRoom():void{
			enterRoom = null;
		}

		public function reset():void{
			if (implementor)
				implementor = null;
		}

		public static function clearList():void{
			for (var i:int = 0; i < eventList.length; i++)
				eventList[i].reset();
			eventList = new Array();
		}

		private static function toClass(instance:*):Class{
			if (!instance)
				return null;
			return Class(getDefinitionByName(getQualifiedClassName(instance)));
		}

		public function clone(obj:_Object = null):_Event{
			var newEvt:_Event = new _Event(getEvent(),null,isEnabled(),getOverride(),(obj ? obj : getObject()));
			newEvt.setScript(getScript());
			return newEvt;
		}
	}
}