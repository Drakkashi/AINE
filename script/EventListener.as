package script{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.6.1 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2014 Drakkashi.com
	 */

	public class EventListener{

		private var str:String;

		public function EventListener(str:String){
			this.str = str;
		}

		public function toString():String{
			return str;
		}
	}
}