package script.Modules.Listeners{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.8.0 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2014 Drakkashi.com
	 */

	public interface MouseListener{
		function _mouseClick(obj:Object):void;
		function _mouseOver(obj:Object):void;
		function _mouseOut(obj:Object):void;
	}
}