package script.Modules.Listeners{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.8.0 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2014 Drakkashi.com
	 */

	public interface GameListener{
		function _start():void;
		function _new():void;
		function _save(dir:String):void;
		function _load(dir:String):void;
		function _delete(dir:String):void;
	}
}