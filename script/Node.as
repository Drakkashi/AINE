package script{

	/*
	 * AINE - Accelerated Interactive Narrator Engine
	 * @version 0.6.1 BETA
	 * @author Daniel Svejstrup Christensen
	 * @see http://www.drakkashi.com/aine/ for updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * Copyright © 2014 Drakkashi.com
	 */
	
	public class Node{
			
		private var len:int,
					val:*,
					err:Output,
					list:Array,
					b:Boolean,
					isWait:Boolean = false;

		public function Node(len:int,err:Output = null,val:* = null,b:Boolean = false){
			this.len = len;
			this.isWait = isWait;
			setError(err);
			setValue(val);
		}

		public function wait():Boolean{
			return isWait;
		}

		public function length():int{
			return len;
		}
	
		public function setValue(val:*):void{
			this.val = val;
			b = Boolean(val);
		}
	
		public function getValue():*{
			return val;
		}
	
		public function getBool():Boolean{
			return b;
		}
	
		private function setError(err:Output):void{
			this.err = err;
		}
	
		public function getError():Output{
			return err;
		}
	
		public function setList(list:Array):void{
			this.list = list;
			isWait = true;
		}
	
		public function getList():Array{
			return list;
		}
	}

}