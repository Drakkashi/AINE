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
    import flash.display.Shape;
    import flash.display.Graphics;
	import flash.display.Bitmap;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.utils.getTimer;

	public class Display extends MovieClip{

		private static var current:Display;

		private var tweenList:Array = new Array(),
					textList:Array,
					textHolder:TextField = new TextField(),
					image:Bitmap,
					portrait:Bitmap,
					scrollComplete:Boolean = true,
					scrollEnabled:Boolean = false,
					endGame:Boolean,
					speech:Boolean,
					asBackground:Boolean,
					strLen:int = 0,
					counter:int = 0,
					initTime:int,
					rect:Shape;

		public function Display(textList:Array,image:Bitmap=null,endGame:Boolean=false,speech:Boolean=false,portrait:*=null,str:String=null,asBackground:Boolean=true){
			current = this;

			this.textList = (textList ? textList : new Array());

			if (endGame)
				_Event.clearList();

			this.endGame = endGame;
			this.speech = speech;
			this.asBackground = (image ? asBackground : true);

			imageHolder.gotoAndStop(1);
			imageHolder.visible = false;
			txt_display.visible = false;
			txt_display.selectable = false;
			btn_toggle.visible = false;

			var obj:_Object = (portrait && Implementor.isObject(portrait) ? portrait : null),
				tmp:Number = window.x;
	
			window.x = (Engine.getWidth()-window.width)/2;
			imageHolder.x += window.x - tmp;
			txt_display.x += window.x - tmp;
				
			rect = new Shape();
			rect.graphics.beginFill(0xFFFFFF,(image ? 1 : 0));
			rect.graphics.drawRect(0,0,Engine.getWidth(),Engine.getHeight());
			rect.graphics.endFill();
			addChild(rect);
			
			if (image){
				this.image = image;

				displayImage(image,Engine.getWidth(),(asBackground ? Engine.getHeight() : Engine.getHeight()-window.height),this);

				setChildIndex(btn_toggle,numChildren-1);
				setChildIndex(window,numChildren-1);
				setChildIndex(imageHolder,numChildren-1);
				setChildIndex(txt_display,numChildren-1);
			}

			if (portrait){
				this.portrait = Image.getImage((obj ? obj.getImage() : portrait));

				if (this.portrait)
					displayImage(this.portrait,imageHolder.width,imageHolder.height,imageHolder);	
			}

			if (this.textList.length > 0){
				if (!str && obj)
					str = obj.getName();

				if (str){
					str += ":\n\n";
					
					textHolder.htmlText = str;
					strLen = textHolder.text.length;

					for (var i:int = 0; i < this.textList.length; i++)
						this.textList[i] = str + this.textList[i];
				}

				if (obj && !this.portrait && (obj.getClass() == Player || obj.getClass() == Character)){
					var gender:String = (obj as Person).getGender();
	
					if (gender && gender.toLowerCase() == "male")
						imageHolder.gotoAndStop(2);
					else if (gender && gender.toLowerCase() == "female")
						imageHolder.gotoAndStop(3);
							
					if (imageHolder.currentFrame > 1 && obj.getClass() == Character){
						imageHolder.scaleX = -1;
						imageHolder.x += imageHolder.width;
					}
				}

				if (this.portrait || imageHolder.currentFrame > 1){
					if (imageHolder.scaleX < 0){
						txt_display.width -= imageHolder.x;
						txt_display.x += imageHolder.x;
					}
					else{
						txt_display.width -= imageHolder.width + imageHolder.x;
						txt_display.x += imageHolder.width + imageHolder.x;
					}
				}

				updateText();
				tweenList[0] = new Tween(window,"x",Strong.easeOut,window.x+80,window.x,0.4,true);
				tweenList[1] = new Tween(window,"y",Strong.easeOut,window.y+16.5,window.y,0.4,true);
				tweenList[2] = new Tween(window,"width",Strong.easeOut,window.width-160,window.width,0.4,true);
				tweenList[3] = new Tween(window,"height",Strong.easeOut,window.height-16.5,window.height,0.4,true);
				tweenList[4] = new Tween(window,"alpha",Strong.easeOut,0,1,0.4,true);
				tweenList[0].addEventListener(TweenEvent.MOTION_FINISH, displayText);
			}
			else{
				addEventListener(MouseEvent.CLICK,mouseClick);
				window.visible = false;
			}

			Engine.getStage().addChild(this);

			if (!textList && !image && endGame)
				Engine.endGame();
		}

		public static function getCurrent():Display{
			return current;
		}

		private function updateText():void{
			txt_display.htmlText = textList[counter];
			txt_display.height = txt_display.textHeight+4;

			if (txt_display.height < 145)
				txt_display.height = 145;
			else if (!asBackground && txt_display.height > 145){
				txt_display.height = 145;
				scrollEnabled = true;
			}
			else if (txt_display.height > Engine.getHeight() - 20){
				txt_display.height = Engine.getHeight() - 20;
				scrollEnabled = true;
			}

			txt_display.y = Engine.getHeight() - 10 - txt_display.height;
			window.height = txt_display.height + 20;
			window.y = txt_display.y - 10;

			if (speech){
				imageHolder.y = height - imageHolder.height - 25;
				txt_display.text = "";
				initTime = getTimer();
				scrollComplete = false;
				addEventListener(Event.ENTER_FRAME,loop);
			}
			else{
				btn_toggle.y = window.y - btn_toggle.height;
				btn_toggle.x = window.x + window.width - btn_toggle.width;
			}
		}

		private function scrollText():void{
			txt_display.scrollV += txt_display.numLines - txt_display.maxScrollV;
		}

		private function mouseClick(e:MouseEvent):void{
			if (btn_toggle.visible && (
					btn_toggle.currentFrame == 2 && !endGame ||
					mouseX >= btn_toggle.x && mouseX < btn_toggle.x + btn_toggle.width &&
					mouseY >= btn_toggle.y && mouseY < btn_toggle.y + btn_toggle.height
				)){

				if (btn_toggle.currentFrame == 1){
					btn_toggle.gotoAndStop(2);
					btn_toggle.y = Engine.getHeight() - btn_toggle.height;
				}
				else{
					btn_toggle.gotoAndStop(1);
					btn_toggle.y = window.y - btn_toggle.height;
				}

				window.visible = !window.visible;
				if (portrait || imageHolder.currentFrame > 1)
					imageHolder.visible = !imageHolder.visible;
				txt_display.visible = !txt_display.visible;
			}
			else if (counter+1 < textList.length || scrollEnabled && txt_display.scrollV < txt_display.maxScrollV || speech && !scrollComplete){
				if (scrollEnabled && txt_display.scrollV < txt_display.maxScrollV)
					scrollText();
				else if (!scrollComplete){
					txt_display.htmlText = textList[counter];

					if (scrollEnabled)
						txt_display.scrollV = txt_display.maxScrollV;
	
					removeEventListener(Event.ENTER_FRAME,loop);
					scrollComplete = true;
				}
				else{
					counter++;
					updateText();
				}
			}
			else if (endGame)
				Engine.endGame();
			else if (window.visible)
				pendingRemoval();
			else
				removeSelf();
		}

		private function displayText(e:Event):void {
			e.currentTarget.removeEventListener(TweenEvent.MOTION_FINISH, displayText);
			txt_display.visible = true;
			addEventListener(MouseEvent.CLICK,mouseClick);
			
			if (asBackground && image && textList){
				btn_toggle.gotoAndStop(1);
				btn_toggle.visible = true;
			}
			
			if (speech){
				txt_display.text = "";
				initTime = getTimer();
				scrollComplete = false;
				addEventListener(Event.ENTER_FRAME,loop);
			}

			if (portrait || imageHolder.currentFrame > 1)
				imageHolder.visible = true;
		}

		private function loop(e:Event):void{
			var char:String,
				charIndex:int = ((getTimer()-initTime)/1000)*48+strLen;

			txt_display.htmlText = textList[counter];

			if (charIndex >= txt_display.length){
				removeEventListener(Event.ENTER_FRAME,loop);
				scrollComplete = true;
			}
			else
				txt_display.replaceText(charIndex,txt_display.text.length,"");
			txt_display.scrollV = txt_display.maxScrollV;
		}

		private function displayImage(image:Bitmap,objWidth:int,objHeight:int,obj:Object):void{
			if (image.height > objHeight || image.width > objWidth){
				if (image.width / objWidth > image.height / objHeight){
					image.height = image.height/image.width*objWidth;
					image.width = objWidth;
				}
				else{
					image.width = image.width/image.height*objHeight;
					image.height = objHeight;
				}
			}
	
			image.x = (objWidth-image.width)/2;
			image.y = (objHeight-image.height)/2;
			obj.addChild(image);
		}

		private function pendingRemoval():void {
			removeEventListener(MouseEvent.CLICK,mouseClick);
			imageHolder.visible = false;
			txt_display.visible = false;
			btn_toggle.visible = false;
			tweenList[0] = new Tween(window,"x",Strong.easeOut,window.x,window.x+80,0.4,true);
			tweenList[1] = new Tween(window,"y",Strong.easeOut,window.y,window.y+16.5,0.4,true);
			tweenList[2] = new Tween(window,"width",Strong.easeOut,window.width,window.width-160,0.4,true);
			tweenList[3] = new Tween(window,"height",Strong.easeOut,window.height,window.height-16.5,0.4,true);
			tweenList[4] = new Tween(window,"alpha",Strong.easeOut,window.alpha,0,0.4,true);
			tweenList[0].addEventListener(TweenEvent.MOTION_FINISH, removeSelf);
		}

		public function removeSelf(e:Event=null):void {
			if (tweenList[0])
				tweenList[0].removeEventListener(TweenEvent.MOTION_FINISH, removeSelf);

			removeEventListener(Event.ENTER_FRAME,loop);
			removeEventListener(MouseEvent.CLICK,mouseClick);
			current = null;

			if (parent)
				parent.removeChild(this);

			if (!endGame)
				_Event.resume();
		}
	}
}