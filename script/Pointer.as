package script{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.8.0 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2014 Drakkashi.com
	 */

	public class Pointer{

		public var str:String;

		public function Pointer(str:String){
			this.str = str;
		}

		public function toString():String{
			return str;
		}
	}
}