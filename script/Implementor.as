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
	import script.Modules.*;
	import flash.utils.Endian;
	import flash.utils.getTimer;
	import flash.errors.ScriptTimeoutError;

	public class Implementor{

		private static var modules:Array,
						   reservedList:Array = new Array(
								"Object","Item","Player","Character","Room","Event","if","else","null","this",'while','do','for','foreach','switch','break','continue','return','case',
								"ceil","floor","round","pow","rand","abs","sqrt",
								"display","displayImage",'displaySpeech','screenMessage',"endGame","print","showTooltip","hideTooltip",
								"setName","getName","setDesc","getDesc","setTooltip","getTooltip","setGender","getGender","setImage","getImage","currentRoom",
								"remove","moveTo","giveItem","hasItem","dropItem","enableEvent","disableEvent","setPath","getPath",'isEnabled','trigger',
								'getPaths','getItems','getChars','dropItems','showEvents','enterRoom','setChars','setItems'
							),
							listenerList:Array = new Array(
								"Enter_Room_First","Leave_Room_First","Enter_Room","Leave_Room",
								"Mouse_Over","Mouse_Out","Mouse_Click","Game_Start",
								"Nav_Over","Nav_Out","Nav_Click"
							),
							arrMethods:Array = new Array("indexOf","join"),
							strMethods:Array = new Array("indexOf","charAt","substr","substring","split","replace","toLowerCase","toUpperCase"),
							mathIds:Array = new Array("ceil","floor","round","pow","rand","abs","sqrt"),
							gameIds:Array = new Array("display","displayImage",'displaySpeech',"screenMessage","endGame","print","showTooltip","hideTooltip"),
							opSigns:Array = new Array("==","!=","<=","<",">=",">","&&","||","+=","-=","*=","/=","=","+","-","*","/","%","?",":"),
							regex:RegExp = new RegExp("(\'(.*?)\'|" + '\"(.*?)\"' +"|[a-zA-Z_0-9.\$]+)","g"),
							objIds:Array;

		private var dataList:Array,
					parentObj:_Object,
					dir:String,
					line:int,
					err:Boolean = false,
					broken:Boolean = false,
					isPaused:Boolean,
					isPending:Boolean,
					isLoop:Boolean,
					loopVal:Array,
					loopStr:Array,
					loopList:Array,
					loopIndex:int,
					loopID:String,
					loopStatement:String,
					resumeIndex:int = 0,
					resumeBeg:int = 0,
					resumeLen:int,
					resumeList:Array,
					timeStamp:Number;

		public function Implementor(dataList:Array,parentObj:_Object,isLoop:Boolean=false,loopVal:Array=null,loopStr:Array=null){
			this.dataList = dataList;
			this.parentObj = parentObj;
			this.isLoop = isLoop;
			this.loopVal = loopVal;
			this.loopStr = loopStr;
			resume();
		}

		public function paused():Boolean{
			return isPaused;
		}

		public function pending():Boolean{
			return isPending;
		}

		public function loopBroken():Boolean{
			return broken;
		}

		public function error():Boolean{
			return err;
		}

		public function resume():void{
			timeStamp = getTimer();
			isPaused = false;
			isPending = false;

			for (var i:int = resumeIndex; i < dataList.length; i++){
				dir = dataList[i][1];
				line = dataList[i][2];
				
				try {
					var returnVal:* = masterScript(dataList[i]);
				} catch (e:ScriptTimeoutError) {
					ScriptTimer.getCurrent().scriptTimeout(e);
					err = true;
					return;
				}

				if (returnVal){
					if (!error())
						Output.err(String(returnVal),dir,line+countLines(dataList[i][0].substr(0,(returnVal as Output).getIndex())));
					err = true;
					return;
				}
				if (getTimer() - timeStamp > 10000)
					isPending = true;
				if (isPaused || isPending){
					isPaused = true;
					resumeIndex = i;
					return;
				}
			}
		}
		
		private function masterScript(strHolder:Array):Output{
			var match:String,
				id:String,
				beg:int,
				index:int,
				scopeEnd:*,
				val:*,
				object:_Object,
				node:Node,
				implementor:Implementor;

			if (resumeList){
				node = computeNode(strHolder[0].substr(resumeBeg),false,true,false);
				beg = resumeBeg+node.length();
				resumeList = null;
			}
			else
				beg = resumeBeg;

			while(firstChar(strHolder[0].substr(beg)) == ";")
				beg = strHolder[0].indexOf(";",beg)+1;

			while((val = getMatch(strHolder[0].substr(beg)))){

				if (toClass(val) == Output)
					return val.appendIndex(strHolder[0].indexOf(firstChar(strHolder[0].substr(beg)),beg));					
				else
					match = val;

				var subStr:String = strHolder[0].substr(beg),
					end:int = subStr.indexOf(match)+match.length;

				if (match == "if" || match == "while" || match == "for" || match == "foreach"){

					if (firstChar(subStr.substr(end)) != "(")
						return new Output('Expected leftparent after "'+match+'".',end);

					index = subStr.indexOf("(",end);
					end = endOfSegment(subStr.substr(index),"(",")")+index++;

					if (end < index)
						return new Output("Expected rightparent before end of script.",beg+index);

					if (match != "for" && match != "foreach"){
						node = computeNode(subStr.substring(index,end),true);
	
						if (node.getError())
							return node.getError().appendIndex(beg+index);
	
						val = node.getBool();
					}
					else {
						var matchList:Array;

						if (match == "for"){
							matchList = subStr.substring(index,end).split(";");
							
							if (matchList.length != 3)
								return new Output('Expected 2 colons in for loop statement',beg+index);

							if (!loopStatement){
								node = computeNode(trim(matchList[0]),true,true);

								if (node.getError())
									return node.getError().appendIndex(beg+index);

								loopStatement = trim(matchList[2]);
							}

							node = computeNode(trim(matchList[1]),true);

							if (node.getError())
								return node.getError().appendIndex(beg+index);

							val = node.getBool();
						}
						else if (!loopList){
							match = subStr.substring(index,end);
							var indexOfIn:int = -1,
								indexOfAs:int,
								clss:Class;
							
							matchList = match.match(/[\s]in[\s]/g);
							
							if (matchList.length > 1)
								return new Output('Expected no more than 1 "in" in foreach statement.',beg+index);
							if (matchList.length == 1)
								indexOfIn = match.indexOf(matchList[0]);
		
							matchList = subStr.substring(index,end).match(/[\s]as[\s]/g);
		
							if (matchList.length != 1)
								return new Output('Expected 1 "as" in foreach statement.',beg+index);
							indexOfAs = match.indexOf(matchList[0]);
							
							if (indexOfIn >= 0 && indexOfIn > indexOfAs)
								return new Output('Expected "in" before "as" in foreach statement.',beg+index);
		
							if (indexOfIn >= 0){
								switch (trim(match.substr(0,indexOfIn))){
									case "Item":
										clss = Item;
										break;
									case "Character":
										clss = Character;
										break;
									case "Room":
										clss = Room;
										break;
									case "Player":
										clss = Player;
										break;
									case "Object":
										clss = _Object;
										break;
									default:
										return new Output('Invalid Object identifier before "in" in foreach statement.',beg+index);
								}
								
								node = computeNode(trim(match.substring(indexOfIn+3,indexOfAs)),true);
							}
							else
								node = computeNode(trim(match.substr(0,indexOfAs)),true);
								
							if (node.getError())
								return node.getError().appendIndex(beg+index);
							if (toClass(node.getValue()) != Array)
								return new Output('Expected a List before "as" in foreach statement.',beg+index);
	
							loopList = node.getValue().concat();
							loopIndex = 0;
							loopID = trim(match.substr(indexOfAs+3));
	
							if (loopID.length != loopID.replace(/\s+/g, "").length)
								return new Output('Instance name must be one word.',beg+index);
							if (loopID.length != loopID.replace(/[^a-zA-Z_0-9\$]/g, "").length)
								return new Output('Instance name may only contain letters a-z, the signs _$ and numbers',beg+index);
							if (!isNaN(Number(loopID.charAt())))
								return new Output('Instance name may not begin with a number.',beg+index);
							if (isReserved(loopID))
								return new Output('"' + loopID + '" is a reserved and may not be used as instance name.',beg+index);
	
							if (clss)
								for (var i:int = 0; i < loopList.length; i++)
									if (clss == _Object && !isObject(loopList[i]) || clss != _Object && toClass(loopList[i]) != clss)
										loopList.splice(i--,1);
							match = "foreach";
						}
					}
					
					if (firstChar(subStr.substr(end+1)) == "{"){
						index = subStr.indexOf("{",end+1);
						scopeEnd = index;
					}
					else{
						index = end;

						scopeEnd = endOfScope(subStr.substr(end+1));

						if (toClass(scopeEnd) == Output)
							return scopeEnd.appendIndex(beg+end);

						scopeEnd += end +1;
					}

					if (firstChar(subStr.substr(scopeEnd)) == "{"){
						scopeEnd = subStr.indexOf("{",scopeEnd);
						end = endOfSegment(subStr.substr(scopeEnd))+scopeEnd;

						if (end < scopeEnd)
							return new Output("Expected rightbrace before end of script.",beg+scopeEnd);
					}
					else{
						node = computeNode(subStr.substr(scopeEnd),false,false,true);

						if (node.getError())
							return node.getError().appendIndex(beg+scopeEnd);

						end = scopeEnd + node.length();
					}

					if (match != "if"){
						if (match == "foreach" && loopIndex < loopList.length ||
							(match == "while" || match == "for") && val
						){
							if (match == "foreach")
								implementor = new Implementor(new Array(new Array(subStr.substring(index+1,end+1),dir,line+countLines(subStr.substr(0,index))+1)),parentObj,true,(loopVal ? new Array(loopList[loopIndex++]).concat(loopVal)  : new Array(loopList[loopIndex++])),(loopStr ? new Array(loopID).concat(loopStr) : new Array(loopID)));
							else
								implementor = new Implementor(new Array(new Array(subStr.substring(index+1,end+1),dir,line+countLines(subStr.substr(0,index))+1)),parentObj,true);
								
							if (match == "for"){
								node = computeNode(loopStatement,false,true);
		
								if (node.getError())
									return node.getError().appendIndex(beg+scopeEnd);
							}

							if (implementor.paused()){
								isPaused = true;
								resumeBeg = beg;
								return null;
							}
							else if (implementor.error()){
								err = true;
								return null;
							}
						}

						if (match == "foreach" && (loopIndex >= loopList.length || implementor.loopBroken()) ||
							(match == "while" || match == "for") && (!val || implementor.loopBroken())
						){
							if (strHolder[0].charAt(beg+end) == "}")
								end++
							loopList = null;
							loopStatement = null;
						}
						else
							end = 0;
					}
					else if (val){
						// IF STATEMENT IS TRUE
						beg += index+1;
						end -= index+1;

						if (subStr.charAt(index) == "{")
							strHolder[0] = removeAt(strHolder[0],beg+end--);
						else if (strHolder[0].charAt(beg+end) == "}")
							end++;

						while(( subStr = strHolder[0].substr(beg+end) ) && getMatch(subStr) as String == "else"){
							var removeEnd:int = subStr.indexOf("else")+4;
							scopeEnd = endOfScope(subStr.substr(removeEnd));

							if (toClass(scopeEnd) == Output)
								return scopeEnd.appendIndex(beg+removeEnd);
							removeEnd += scopeEnd;

							match = firstChar(subStr.substr(removeEnd));
							if (match == "{"){
								index = subStr.indexOf("{",removeEnd);
								removeEnd = endOfSegment(subStr.substr(index))+index;

								if (removeEnd < index)
									return new Output("Expected rightbrace before end of script.",beg+index);
								removeEnd++;
							}
							else{
								node = computeNode(subStr.substr(removeEnd+1),false,false,true);

								if (node.getError())
									return node.getError().appendIndex(beg+removeEnd+1);

								removeEnd += node.length()+1;
							}

							var lines:int = countLines(strHolder[0].substring(beg+end,beg+end+removeEnd)),
								linesHolder:String = "";

							while(lines-- > 0)
								linesHolder += "\n";

							strHolder[0] = strHolder[0].substr(0,beg+end)+ linesHolder + strHolder[0].substr(beg+end+removeEnd);
						}
						end = 0;
					}
					else if (getMatch(subStr.substr((subStr.charAt(end) == "}" ? ++end : end ))) as String == "else"){
						// IF STATEMENT IS FALSE
						end = subStr.indexOf("else",end)+4;
						if (firstChar(subStr.substr(end)) == "{"){
							end = subStr.indexOf("{",end);
							index = endOfSegment(subStr.substr(end))+end;

							if (index < end)
								return new Output("Expected rightbrace before end of script.",beg+end);
							strHolder[0] = removeAt(strHolder[0],beg+index);
							end++;
						}
					}
				}
				else if (match == "else")
					return new Output("Else was unexpected.",end-1);
				else if (isLoop && match == "break"){
					broken = true;
					return null;
				}
				else{
					node = computeNode(subStr,false,true);

					if (node.getError())
						return node.getError().appendIndex(strHolder[0].indexOf(firstChar(strHolder[0].substr(beg)),beg));
					if (isPaused){
						resumeBeg = beg;
						return null;
					}
					if (!ScriptTimer.getCurrent().parent && getTimer() - timeStamp > 1000){
						isPending = true;
						resumeBeg = beg;
						return null;
					}

					end = node.length();
				}

				beg += end;

				while(firstChar(strHolder[0].substr(beg)) == ";")
					beg = strHolder[0].indexOf(";",beg)+1;
			}
			return null;
		}

		private function computeNode(str:String,isStatement:Boolean,isStart:Boolean = false,skip:Boolean = false):Node{
			var beg:int = 0,
				end:int = 0,
				i:int,
				index:int,
				len:int,
				subStr:String,
				match:String,
				val:*,
				node:Node,
				clss:Class,
				assign:Boolean = false,
				list:Array = new Array();

			if (!resumeList){

				while(beg < str.length){
					subStr = str.substr(beg);
					var char:String = firstChar(subStr);
					if (char == "(" || startsWith(trim(subStr),"!(")){
						beg = str.indexOf("(",beg);
						end = endOfSegment(str.substr(beg),"(",")")+beg;
						
						if (end < beg)
							return new Node(0,new Output("Expected rightparent before end of script."));

						if (skip)
							end++;
						else{
							node = computeNode(str.substring(beg+1,end++),true);
	
							if (node.getError())
								return node;
								
							if (str.charAt(beg-1) == "!")
								node.setValue(!node.getBool());
		
							list.push(node);
						}
					}
					else if (char == "["){
						beg = str.indexOf("[",beg);
						end = endOfSegment(str.substr(beg),"[","]")+beg;

						if (end < beg)
							return new Node(0,new Output("Expected rightbracket before end of script."));
							
						if (skip)
							end++;
						else{
							var args:Array = strToArgs(str.substring(beg+1,end++));
		
							if (toClass(args[0]) == Output)
								return new Node(len,args[0]);
		
							list.push(args);
						}
					}
					else if (char == "'" || char == '"'){
						beg = str.indexOf(char,beg);
						end = str.indexOf(char,beg+1);
						list.push(str.substring(beg,++end).replace(/\\t/g,"\t").replace(/\\n/g,"\n"));
					}
					else{
						val = getMatch(subStr);
						
						if (toClass(val) == Output)
							return new Node(end,val);
						else
							match = val;

						end = str.indexOf(match,beg)+match.length;
	
						while ((subStr = str.charAt(end)) && (subStr == "." || subStr == "(" || subStr == "[")){
							var prevEnd:int = end;

							if (subStr == "(")
								end += endOfSegment(str.substring(end),"(",")")+1;
							else if (subStr == "[")
								end += endOfSegment(str.substring(end),"[","]")+1;
							else
								end += operandEnd(str.substring(end+1))+1;

							if (end == prevEnd){
								if (subStr == "(" || subStr == "[")
									return new Node(0,new Output("Expected "+(subStr == "(" ? "rightparent" : "rightbracket" )+" before end of script."));
								else
									end = int.MAX_VALUE;
							}
						}
		
						if (startsWith(str.substr(end),"++") || startsWith(str.substr(end),"--"))
							end+=2;
		
						list.push(trim(str.substring(beg,end)));
					}
	
					subStr = firstOp(str.substr(end));
					if (subStr){
						list.push(subStr);
						beg = str.indexOf(subStr,end)+subStr.length;
					}
					else
						beg = int.MAX_VALUE;
				}
	
				len = end;

				if (isStatement && len < trim(str).length)
					return new Node(len,new Output("Syntax error."));
				
				if (skip)
					return new Node(len);
	
				index = str.substr(end).indexOf("\n");
				if (index < 0)
					index = int.MAX_VALUE;
	
				if (trim(str.substr(end,index)).length > 0){
					index = str.substr(end).indexOf(";");

					if (index < 0 || trim(str.substr(end,index)).length > 0)
						return new Node(len,new Output("Syntax error."));
				}
				
				for (i = 1; i < list.length; i+=2){
					index = opSigns.indexOf(list[i]);
					if (index > 7 && index <= 12){
						if (i == 1 && isStart)
							assign = true;
						else
							return new Node(len,new Output("Can only assign to an operand in the beginning of a line."));
					}
				}
				
				i = (assign ? 2 : 0);
			}
			else{
				list = resumeList;
				len = resumeLen;
				i = 2;
			}

			var isBool:Boolean = false;
			while (list.length >= i+1){
				var indexOperand:String,
					opIndex:int = list.indexOf("&&");

				index = list.indexOf("||");
				if (opIndex < 0 || index >= 0 && index < opIndex)
					opIndex = index;

				index = list.indexOf("?");
				if (opIndex < 0 || index >= 0 && index < opIndex)
					opIndex = index;
				else if (!isBool)
					isBool = true;

				if (opIndex < 0)
					opIndex = list.length;

				for (var j:int = i; j < opIndex; j+=2){
					clss = toClass(list[j]);
					if (clss == Node)
						list[j] = list[j].getValue();
					else if (clss == String){
						if (firstChar(list[j]) != "'" && firstChar(list[j]) != '"'){
							var temp:String = list[j];
							list[j] = computeValue(list[j],false,isStart && j == 0);
	
							if (toClass(list[j]) == Output)
								return new Node(len,list[j]);
							if (isPaused){
								resumeList = list;
								resumeLen = len;
								return new Node(len);
							}
						}
						else
							list[j] = list[j].substring(1,list[j].length-1);
					}
				}

				while (( index = list.indexOf("%") ) > 0 && index < opIndex){
					if (isNaN(list[index-1]) || isNaN(list[index+1]))
						return new Node(len,new Output("Cannot compute modulus " + (isNaN(list[index-1]) ? "of" : "by" ) + " a non number value."));
	
					list[index-1] = list[index-1] % list[index+1];
					list.splice(index,2);
					opIndex-=2;
				}

				while (( index = list.indexOf("*") ) > 0 && index < opIndex){
					if (isNaN(list[index-1]) || isNaN(list[index+1]))
						return new Node(len,new Output("Cannot multiply by a non number value."));
	
					list[index-1] = list[index-1] * list[index+1];
					list.splice(index,2);
					opIndex-=2;
				}
	
				while (( index = list.indexOf("/") ) > 0 && index < opIndex){
					if (isNaN(list[index-1]) || isNaN(list[index+1]))
						return new Node(len,new Output("Cannot divide by a non number value."));
	
					list[index-1] = list[index-1] / list[index+1];
					list.splice(index,2);
					opIndex-=2;
				}
	
				while (( index = list.indexOf("+") ) > 0 && index < opIndex){
					if (toClass(list[index-1]) == Array && toClass(list[index+1]) == Array)
						list[index-1] = list[index-1].concat(list[index+1]);
					else if (isNaN(list[index-1]) || isNaN(list[index+1]))
						list[index-1] = String(list[index-1]) + String(list[index+1]);
					else
						list[index-1] = list[index-1] + list[index+1];
					list.splice(index,2);
					opIndex-=2;
				}

				while (( index = list.indexOf("-") ) > 0 && index < opIndex){
					if (isNaN(list[index-1]) || isNaN(list[index+1]))
						return new Node(len,new Output("Cannot subtract by a non number value."));
	
					list[index-1] = list[index-1] - list[index+1];
					list.splice(index,2);
					opIndex-=2;
				}

				j = i+1;
				while (opIndex > j){
					if (list[j] == "==")
						list[j-1] = list[j-1] == list[j+1];
					else if (list[j] == "!=")
						list[j-1] = list[j-1] != list[j+1];
					else {
						if (list[j] == ":")
							return new Node(len,new Output('Expected conditional operand before colon.'));
						if (isNaN(list[j-1]) || isNaN(list[j+1])){
							return new Node(len,new Output('Cannot perform "less than" or "greater than" comparisons with a non number value.'));
						}
	
						if (list[j] == "<")
							list[j-1] = list[j-1] < list[j+1];
						else if (list[j] == "<=")
							list[j-1] = list[j-1] <= list[j+1];
						else if (list[j] == ">")
							list[j-1] = list[j-1] > list[j+1];
						else if (list[j] == ">=")
							list[j-1] = list[j-1] >= list[j+1];
					}
					list.splice(j,2);
					opIndex-=2;
				}

				if (opIndex == list.length){
					val = (isBool ? Boolean(list[i]) : list[i]);
					break;
				}
				else if (list[opIndex] == "?"){
					isBool = false;
					opIndex = list.indexOf(":",i);
					if (opIndex < 0)
						return new Node(len,new Output('Expected colon following conditional operand.'));

					if (list[i]){
						list.splice(i,2);
						list.splice(opIndex-2,int.MAX_VALUE);
					}
					else{
						list.splice(i,opIndex-i+1);
					}
				}
				else if (list[opIndex] == "&&"){
					if (list[i])
						list.splice(i,2);
					else{
						opIndex = list.indexOf("||",opIndex+1);
						if (opIndex < 0){
							val = false;
							opIndex = list.indexOf("?",i+1);
							
							if (opIndex < 0)
								break;
							else{
								isBool = false;
								opIndex = list.indexOf(":",opIndex+1);
								if (opIndex < 0)
									return new Node(len,new Output('Expected colon following conditional operand.'));
								else{
									list.splice(i,opIndex-i+1);
								}
							}
						}
						else
							list.splice(i,opIndex+1-i);
					}
				}
				else{
					if (list[i]){
						val = true;
						break;
					}
					else 
						list.splice(i,2);
				}
			}
			
			if (assign){
				var ref:* = computeValue(list[0],true);
				clss = toClass(ref);

				if (clss == Output)
					return new Node(len,ref);

				if (clss != Array)
					return new Node(len,new Output('Cannot assign to non reference operand.'));

				if (list[1] != "="){
					if (isNaN(val) && list[1] != "+=")
						return new Node(len,new Output('Expected a Number after "'+list[1]+'" operator.'));
					if (isNaN(ref[2]) && list[1] != "+=")
						return new Node(len,new Output('Operand of "'+list[1]+'" operator must be a Number'));

					if (list[1] == "+="){
						if (toClass(val) == Array && toClass(ref[2]) == Array)
							val = ref[2].concat(val);
						else if (!isNaN(Number(val)) && !isNaN(Number(ref[2])))
							val += ref[2];
						else
							val = String(ref[2])+String(val);
					}
					else if (list[1] == "-=")
						val = ref[2]-val;
					else if (list[1] == "*=")
						val *= ref[2];
					else if (list[1] == "/=")
						val = ref[2]/val;
				}

				if (toClass(ref[0]) == Array)
					ref[0][ref[1]] = val;
				else
					subStr = ref[0].setVar(ref[1],val);
					
				if (subStr)
					Output.warn(subStr);
			}

			return new Node(len,null,val);
		}

		private function computeValue(str:String,returnRef:Boolean,isStart:Boolean = false):*{
			var beg:int = 0,
				char:String;

			while ((char = str.charAt(beg)) && ( char == "!" || char == "+" || char == "-"))
				beg++;
			
			var end:int = (isNaN(Number(str.charAt(beg))) ? operandEnd(str.substr(beg)): numberEnd(str.substr(beg)))+beg,
				subStr:String = subStr = str.substring(beg,end),
				ref:Array,
				args:Array,
				val:*;

			if (!isNaN(Number(subStr))){
				if (trim(str.substr(end)).length > 0)
					return new Output('Syntax error.');
				val = (str.charAt() == "-" && beg < 2 ? Number(subStr)*(-1) : Number(subStr));
			}
			else if (subStr == "null")
				val = null;
			else if (subStr == "true" || subStr == "false")
				val = subStr == "true";
			else if (isListener(subStr))
				val = new EventListener(subStr);
			else{
				var isObj:Boolean,
					isStr:Boolean,
					isArr:Boolean,
					isMethod:Boolean;

				if (loopStr && loopStr.indexOf(subStr) >= 0){
					// IS LOCAL SCOPE VARIABLE
					val = loopVal[loopStr.indexOf(subStr)];
					isObj = isObject(val);
				}
				else if (objIds.indexOf(subStr) >= 0 || subStr == "this"){
					// IS OBJECT
					val = (subStr == "this" ? parentObj : _Object.getObject(subStr));
					isObj = true;
				}
				else if (gameIds.indexOf(subStr) >= 0 || mathIds.indexOf(subStr) >= 0){
					// IS FUNCTION
					if (str.charAt(end) != "(")
						return new Output('Expected leftparent after function identifier.');

					beg = end;
					end = endOfSegment(str.substr(beg),"(",")")+beg;
		
					if (end < beg)
						return new Output("Expected rightparent before end of script.",beg);

					val = computeFunc(subStr,strToArgs(str.substring(beg+1,end++)),isStart);

					if (toClass(val) == Output)
						return val;
					isObj = isObject(val);
				}
				else if (getModuleIds().indexOf(subStr) >= 0){
					// IS MODULE
					char = str.charAt(end);
					if (char == "."){
						var moduleIndex:int = getModuleIds().indexOf(subStr);

						beg = end+1;
						end = operandEnd(str.substr(beg))+beg;
						subStr = str.substring(beg,end);

						if (str.charAt(end) != "(")
							return new Output('Expected leftparent after function identifier.');
	
						beg = end;
						end = endOfSegment(str.substr(beg),"(",")")+beg;
			
						if (end < beg)
							return new Output("Expected rightparent before end of script.",beg);

						val = computeModule(moduleIndex,subStr,strToArgs(str.substring(beg+1,end++)));
						if (toClass(val) == Output)
							return val;
						isObj = isObject(val);
					}
					else if (char == "[")
						return new Output('Cannot access value by index in non List operand.');
					else if (trim(str.substr(end)).length > 0)
						return new Output('Syntax error.');
					else
						val = null;
				}
				else if (parentObj.hasVar(subStr)){
					// IS PROPERTY
					val = parentObj.getVar(subStr);
					ref = new Array(parentObj,subStr);
					isObj = isObject(val);
				}
				else if (parentObj.getMethods().indexOf(subStr) >= 0){
					// IS METHOD
					val = parentObj;
					isMethod = true;
				}
				else
					return new Output('Invalid identifier "'+subStr+'".');

				if (toClass(val) == String || toClass(val) == Array){
					isObj = true;
					if (toClass(val) == String)
						isStr = true;
					else
						isArr = true;
				}

				while ((char = str.charAt(end)) && (char == "." || char == "[") || isMethod){
					if (char == "." || isMethod){
						// PROPERTY OR METHOD

						if (!isMethod){
							beg = end+1;
							end = operandEnd(str.substr(beg))+beg;
							subStr = str.substring(beg,end);
							char = str.charAt(end);

							if (!isObj)
								return new Output('Cannot access '+ (char == "(" ? 'method' : 'property') + ' of non Object, -String, and -List operand.');
						}
						else{
							isMethod = false;
							char = str.charAt(end);
							if (char != "(")
								return new Output('Expected leftparent after method.');
						}

						if (char == "("){
							if (isArr && arrMethods.indexOf(subStr) < 0 ||
								isStr && strMethods.indexOf(subStr) < 0 ||
								!isArr && ! isStr && (val as _Object).getMethods().indexOf(subStr) < 0
							)
								return new Output('Invalid method "'+subStr+'".');

							ref = null;
							beg = end;
							end += endOfSegment(str.substring(end),"(",")");
							args = strToArgs(str.substring(beg+1,end++));

							if (toClass(args[0]) == Output)
								return args[0];
								
							if (isArr || isStr){
								if (subStr == "indexOf" || subStr == "split"){
									if (args.length < 1 || args.length > 2)
										return new Output('Incorrect number of arguments send to method "'+subStr+'". Expected no '+(args.length < 1 ? 'less than 1.' : 'more than 2.'));
	
									if (args.length > 1 && isNaN(Number(args[1])))
										return new Output('Argument 2 of method "'+subStr+'" has to be a Number.');

									if (isStr){
										if (subStr == "indexOf")
											val = (val as String).indexOf(args[0],(args.length > 1 ? args[1] : 0));
										else
											val = (val as String).split(args[0],(args.length > 1 ? args[1] : int.MAX_VALUE));
									}
									else
										val = (val as Array).indexOf(args[0],(args.length > 1 ? args[1] : 0));
								}
								else if (subStr == "join"){
									if (args.length != 1)
										return new Output('Incorrect number of arguments send to method "'+subStr+'". Expected 1.');

									val = (val as Array).join(args[0]);
								}
								else if (subStr == "charAt"){
									if (args.length > 1)
										return new Output('Incorrect number of arguments send to method "'+subStr+'". Expected no more than 1.');

									if (args.length > 0 && isNaN(Number(args[0])))
										return new Output('Argument 1 of method "'+subStr+'" has to be a Number.');

									val = (val as String).charAt((args.length > 0 ? args[0] : 0));
								}
								else if (subStr == "substr" || subStr == "substring" || subStr == "replace"){
									if (args.length > 2)
										return new Output('Incorrect number of arguments send to method "'+subStr+'". Expected no more than 2.');
										
									if (subStr != "replace"){
										if (args.length > 0 && isNaN(Number(args[0])))
											return new Output('Argument 1 of method "'+subStr+'" has to be a Number.');
												
										if (args.length > 1 && isNaN(Number(args[1])))
											return new Output('Argument 2 of method "'+subStr+'" has to be a Number.');
									}

									if (subStr == "substr")
										val = (val as String).substr((args.length > 0 ? args[0] : 0),(args.length > 1 ? args[1] : int.MAX_VALUE));
									else if (subStr == "substring")
										val = (val as String).substring((args.length > 0 ? args[0] : 0),(args.length > 1 ? args[1] : int.MAX_VALUE));
									else
										val = (val as String).replace((args.length > 0 ? args[0] : null),(args.length > 1 ? args[1] : null));
								}
								else if (subStr == "toLowerCase" || subStr == "toUpperCase"){
									if (args.length > 0)
										return new Output('Incorrect number of arguments send to method "'+subStr+'". Expected 0.');

									val = (subStr == "toLowerCase" ? (val as String).toLowerCase() : (val as String).toUpperCase() );
								}
							}
							else {
								if (subStr == "setPath"){
									if (args.length < 2 || args.length > 3)
										return new Output('Incorrect number of arguments send to method "'+subStr+'". Expected no '+(args.length < 2 ? 'less than 2.' : 'more than 3.'));
										
									if (Nav.pathIndex(String(args[0])) < 0)
										return new Output('Argument 1 of method "'+subStr+'" has to be a valid navigation path as String.');
									if (toClass(args[1]) != Room && args[1] != null)
										return new Output('Argument 2 of method "'+subStr+'" has to be a Room.');
									if (args.length > 2 && !(!args[2] || args[2] == true))
										return new Output('Argument 3 of method "'+subStr+'" has to be a Boolean value.');
								}
								else if (
									startsWith(subStr,"set") || subStr == "moveTo" || subStr == "giveItem" || subStr == "dropItem" ||
									subStr == "hasItem" || subStr == "getPath" || subStr == "enableEvent" || subStr == "disableEvent" || subStr == "trigger" || subStr == "isEnabled")
								{
									if (args.length > 1 || args.length == 0)
										return new Output('Incorrect number of arguments send to method "'+subStr+'". Expected 1.');
		
									if (subStr == "setItems"  || subStr == "setChars"){
										if (subStr == "setItems" && toClass(args[0]) == Item || subStr == "setChars" && toClass(args[0]) == Character)
											args[0] = new Array(args[0]);
										else{
											if (toClass(args[0]) != Array)
												return new Output('Argument 1 of method "'+subStr+'" has to be '+(subStr == "setItems" ? 'an Item' : "a Character")+' or a List.');
			
											clss = (subStr == "setItems" ? Item : Character);
		
											for each(var objEntry:* in args[0]){
												if (objEntry != null && toClass(objEntry) != clss){
													return new Output('Invalid entry in list. All entries has to be '+(subStr == "setItems" ? 'an Item' : "a Character")+' object.');
													break;
												}
											}
										}
									}
									else if (startsWith(subStr,"set"))
										args[0] = String(args[0]);
									else if (subStr == "moveTo"){
										var isItem:Boolean = toClass(val) == Item;
										if (isItem && !isContainer(args[0]) || !isItem && toClass(args[0]) != Room)
											return new Output('Argument 1 of method "'+subStr+'" has to be a Room'+(isItem ? ', Character, or the Player' : '' )+'.');
									}
									else if (subStr == "giveItem" || subStr == "hasItem" || subStr == "dropItem"){
										if (args.length > 0 && toClass(args[0]) != Item)
											return new Output('Argument 1 of method "'+subStr+'" has to be an Item.');
									}
									else if (subStr == "getPath"){
										args[0] = Nav.pathIndex(String(args[0]));
										if (args[0] < 0)
											return new Output('Argument 1 of method "'+subStr+'" has to be a valid navigation path as String.');
									}
									else{
										var clss:Class = toClass(args[0])
										if (clss != String && clss != EventListener)
											return new Output('Argument 1 of method "'+subStr+'" has to be an EventListener or a String.');
										if (subStr == "trigger"){
											if (!isStart)
												return new Output('Can only execute "'+subStr+'" in the beginning of a line.');
											if (!(val as _Object).getEvent(args[0]))
												return new Output('Unable to trigger undefined Event');
											isPaused = true;
										}
									}
								}
								else if (startsWith(subStr,"get") || subStr == "currentRoom" || subStr == "remove" || subStr == "dropItems" || subStr == "enterRoom"){
									if (args.length > 0)
										return new Output('Incorrect number of arguments send to method "'+subStr+'". Expected 0.');
	
									if (subStr == "enterRoom"){
										if (!isStart)
											return new Output('Can only execute "'+subStr+'" in the beginning of a line.');
										isPaused = true;
									}
								}
	
								if (args.length == 0)
									val = val[subStr]();
								else
									val = val[subStr](args);
							}
						}
						else if (!isStr && !isArr){
							ref = new Array(val,subStr);
							val = (val as _Object).getVar(subStr);
						}
						else if (subStr == "length")
							val = (isStr ? (val as String).length : (val as Array).length);
						else
							return new Output('Invalid property "'+subStr+'" on type ' + (isStr ? "String." : "List." ));
					}
					else{
						// LIST INDEX
						while (str.charAt(end) == "["){
							if (toClass(val) != Array)
								return new Output('Cannot access value by index in non List operand.');

							beg = end+1;
							end += endOfSegment(str.substring(end),"[","]");
							ref = new Array(val);

							val = computeNode(str.substring(beg,end),true);

							if ((val as Node).getError())
								return (val as Node).getError();
							
							var index:Number = Number((val as Node).getValue());
							
							if (isNaN(index))
								return new Output('Expected index to be a number.');

							ref.push(index);
							val = ref[0][ref[1]];
							end++;
						}
					}
					isStr = toClass(val) == String;
					isArr = toClass(val) == Array;
					isObj = isArr || isStr || isObject(val);
				}
				if (str.charAt(end) == "(")
					return new Output('Syntax error.');
			}

			char = str.charAt(str.length-1);
			if (str.charAt() == "!"){
				if (char == "+" || char == "-")
					return new Output('Syntax error.');
				return !Boolean(val);
			}

			if (str.charAt() == "+" || startsWith(str,"--") || char == "+" || char == "-"){
				if (!ref || isNaN(val))
					return new Output('Operand of '+(str.charAt() == "+" || char == "+" ? 'de' : 'in' )+'crement must be a '+(!ref ? 'reference.' : 'number.'));
				
				if (str.charAt() == "+")
					++val;
				else if (str.charAt() == "-")
					--val;

				var n:Number = val;
				if (char == "+"){
					end+=2;
					n++;
				}
				else if (char == "-"){
					end+=2;
					n--;
				}

				if (toClass(ref[0]) == Array)
					ref[0][ref[1]] = n;
				else
					ref[0].setVar(ref[1],n);
			}

			if (returnRef){
				if (!ref)
					return null;
				ref.push(val);
				return ref;
			}
			return val;
		}

		private function computeFunc(funcStr:String, args:Array, isStart:Boolean):*{
			if (toClass(args[0]) == Output)
				return args[0];

			if (mathIds.indexOf(funcStr) >= 0){
				// MATH FUNCTION

				if (funcStr == "rand" || funcStr == "pow"){
					if (args.length < 1 && funcStr == "pow" || args.length > 2)
						return new Output('Incorrect number of arguments send to function "'+funcStr+'". Expected '+(args.length < 1 ? "no less than 1." : "no more than 2." ));

					if (args.length > 1 && isNaN(args[1]) ||
						args.length > 0 && isNaN(args[0])
					)
						return new Output('Argument '+(isNaN(args[0]) ? '1' : '2' )+' of function "'+funcStr+'" has to be a Number.');

					if (funcStr == "rand" && args.length < 1)
						return Math.random();
					if (funcStr == "rand" && args.length < 2)
						return Math.random()*args[0];
					if (funcStr == "rand")
						return args[0]+Math.random()*(args[1]-args[0]);
					if (args.length < 2)
						return Math.pow(args[0],2);
					return Math.pow(args[0],args[1]);
				}
				else if (args.length == 1){
					if (isNaN(args[0]))
						return new Output('Argument 1 of function "'+funcStr+'" has to be a Number.');

					if (funcStr == "abs")
						return Math.abs(args[0]);
					if (funcStr == "ceil")
						return Math.ceil(args[0]);
					if (funcStr == "floor")
						return Math.floor(args[0]);
					if (funcStr == "round")
						return Math.round(args[0]);
					if (funcStr == "sqrt")
						return Math.sqrt(args[0]);
				}
				else
					return new Output('Incorrect number of arguments send to function "'+funcStr+'". Expected 1.');
			}
			else if (gameIds.indexOf(funcStr) >= 0){
				// GAME FUNCTION

				if (funcStr == "print" || funcStr == "showTooltip"){
					if (args.length != 1)
						return new Output('Incorrect number of arguments send to function "'+funcStr+'". Expected 1.');

					if (funcStr == "print")
						Output.print(String(args[0]));
					else
						Interface.getUI().showTooltip(String(args[0]));
				}
				else if (funcStr == "screenMessage"){
					if (args.length < 1 || args.length > 2)
						return new Output('Incorrect number of arguments send to function "'+funcStr+'". Expected no '+(args.length < 1 ? 'less than 1.' : 'more than 2.'));
					if (args.length > 1 && isNaN(args[1]))
						return new Output('Argument 2 of function "'+funcStr+'" has to be a Number.');

					new ScreenMessage(String(args[0]),(args.length > 1 ? args[1] : -1));
				}
				else if (funcStr == "hideTooltip"){
					if (args.length > 0)
						return new Output('Incorrect number of arguments send to function "'+funcStr+'". Expected 0.');

					Interface.getUI().hideTooltip();
				}
				else if (startsWith(funcStr,"display") || funcStr == "endGame"){
					if (!isStart)
						return new Output('Can only execute "'+funcStr+'" in the beginning of a line.');
					if (args.length > 4  ||
						args.length > 3  && funcStr != "displaySpeech" ||
						args.length > 1  && funcStr == "displayImage" ||
						args.length == 0 && funcStr != "endGame"
					){
						return new Output('Incorrect number of arguments send to function "'+funcStr+'". Expected '+(funcStr == "displayImage" ? '1.' : (args.length == 0 ? 'no less than 1.' : 'no more than ' + (funcStr == "displaySpeech" ? '4.' : '3.')) ));
					}

					if (funcStr == "displayImage"){
						args[1] = (isObject(args[0]) ? (args[0] as _Object).getImage() : String(args[0]));
						args[0] = null;
						args[2] = null;
						args[3] = null;
						args[4] = true;
					}
					else{
						if (args.length > 0){
							if (isObject(args[0])){
								if (args.length == 1)
									args[1] = (args[0] as _Object).getImage();
								if ((args[0] as _Object).getDesc())
									args[0] = new Array((args[0] as _Object).getDesc());
								else
									args[0] = null;
							}
							else if (toClass(args[0]) == Array){
								for (var i:int = 0; i < args[0].length; i++)
									args[0][i] = String(args[0][i]);
							}
							else if (args[0] != null)
								args[0] = new Array(String(args[0]));
								
							if (args[0] && trim(args[0]).length == 0)
								args[0] = null;
						}

						if (args.length > 1){
							if (isObject(args[1]))
								args[1] = (args[1] as _Object).getImage();
							else if (args[1] != null)
								args[1] = String(args[1]);
						}
						else
							args[1] = null;

						if (args.length > 2){
							if (funcStr == "displaySpeech"){
								if (args.length > 3){
									if (isObject(args[3]))
										args[3] = args[3].getName();
									else if (args[3] != null)
										args[3] = String(args[3]);
									else
										args[3] = null;
								}
								else if (isObject(args[2]))
									args[3] = args[2].getName();
								else
									args[3] = null;
	
								if (!isObject(args[2]) && args[2] != null)
									args[2] = String(args[2]);
								args[4] = true;
							}
							else if (toClass(args[2]) == Boolean || !args[2] && args[2] != null){
								args[4] = args[2];
								args[2] = null;
								args[3] = null;
							}
							else
								return new Output('Expected argument 3 of function "'+funcStr+'" to be a Boolean.');
						}
						else{
							args[2] = null;
							args[3] = null;
							args[4] = true;
						}
					}

					if (args.length > 0 && (args[0] || args.length > 1 && args[1])){
						new Display(args[0],Image.getImage(args[1]),funcStr == "endGame",funcStr == "displaySpeech",args[2],args[3],args[4]);
						isPaused = true;
					}
					else if (funcStr == "endGame")
						new Display(null,null,true);
				}
			}
			return null;
		}

		private function computeModule(module:int, funcStr:String, args:Array):*{
			var funcXML:XML = getModuleFunc(module,funcStr);
			
			if (!funcXML)
				return new Output('Call to unknown function "' + getModuleIds()[module] + "." + funcStr + '".');
			if (toClass(args[0]) == Output)
				return args[0];

			var min:int = funcXML.parameter.(@optional=="false").length(),
				max:int = funcXML.parameter.length(),
				paraList:Array = new Array();
				
			if (args.length < min)
				return new Output('Incorrect number of arguments send to function "' + getModuleIds()[module] + "." + funcStr + '". Expected '+(max != min ? "no less than " : "" ) + min + '.');
			if (args.length > max)
				return new Output('Incorrect number of arguments send to function "' + getModuleIds()[module] + "." + funcStr + '". Expected '+(max != min ? "no more than " : "" ) + max + '.');

			funcXML.parameter.(paraList.push(@type));
			for (var i:int = 0; i < args.length; i++)
				if (paraList[i] != "*"){
					if (paraList[i] == "String"){
						if (args[i] != null)
							args[i] = String(args[i]);
					}
					else if (paraList[i] == "int" || paraList[i] == "Number"){
						args[i] = Number(args[i]);
						if (isNaN(args[i]))
							return new Output('Argument '+(i+1)+' of function "' + getModuleIds()[module] + "." + funcStr + '" has to be a Number.');
					}
					else if (paraList[i] == "Boolean"){
						if (!(toClass(args[i]) == Boolean || !args[i] && args[i] != null))
							return new Output('Argument '+(i+1)+' of function "' + getModuleIds()[module] + "." + funcStr + '" has to be a Boolean.');
					}
					else if (paraList[i] == "Array"){
						if (toClass(args[i]) != Array)
							return new Output('Argument '+(i+1)+' of function "' + getModuleIds()[module] + "." + funcStr + '" has to be a List.');
					}
					else if (paraList[i] == "Object" || paraList[i] == "script::_Object"){
						if (!isObject(args[i]))
							return new Output('Argument '+(i+1)+' of function "' + getModuleIds()[module] + "." + funcStr + '" has to be an Object.');
					}
					else if (paraList[i] == "script::Item"){
						if (toClass(args[i]) != Item)
							return new Output('Argument '+(i+1)+' of function "' + getModuleIds()[module] + "." + funcStr + '" has to be an Item.');
					}
					else if (paraList[i] == "script::Character"){
						if (toClass(args[i]) != Character)
							return new Output('Argument '+(i+1)+' of function "' + getModuleIds()[module] + "." + funcStr + '" has to be a Character.');
					}
					else if (paraList[i] == "script::Room"){
						if (toClass(args[i]) != Room)
							return new Output('Argument '+(i+1)+' of function "' + getModuleIds()[module] + "." + funcStr + '" has to be a Room.');
					}
					else if (paraList[i] == "script::Person"){
						if (toClass(args[i]) != Character && toClass(args[i]) != Player)
							return new Output('Argument '+(i+1)+' of function "' + getModuleIds()[module] + "." + funcStr + '" has to be a Character of the Player.');
					}
					else if (paraList[i] == "script::Container"){
						if (!isContainer(args[i]))
							return new Output('Argument '+(i+1)+' of function "' + getModuleIds()[module] + "." + funcStr + '" has to be a Character, Room or the Player.');
					}
					else if (paraList[i] == "script::Player"){
						if (toClass(args[i]) != Player)
							return new Output('Argument '+(i+1)+' of function "' + getModuleIds()[module] + "." + funcStr + '" has to be the Player.');
					}
				}

			if (funcXML.@returnType != "void"){
				var val:* = (getModuleClass(module)[funcStr] as Function).apply(this,args);

				if (toClass(val) == Output)
					return val;
				if (val && new Array(int,Number,String,Array,Boolean,GenericObject,Item,Room,Player,Character).indexOf(toClass(val)) < 0)
					return String(val);
				return val;
			}
			(getModuleClass(module)[funcStr] as Function).apply(this,args);
			return null;
		}

		private static function isContainer(obj:*):Boolean{
			var clss:Class = toClass(obj);
			return clss == Player || clss == Room || clss == Character;
		}

		public static function isObject(obj:*):Boolean{
			return isContainer(obj) || toClass(obj) == Item || toClass(obj) == GenericObject;
		}

		private function firstOp(str:String):String{
			str = trim(str);
			for (var i:int = 0; i < opSigns.length; i++)
				if(str.substring(0,opSigns[i].length) == opSigns[i])
					return opSigns[i];
			return null;
		}

		private function strToArgs(str:String):Array{
			var list:Array = new Array(),
				match:Array,
				subStr:String,
				beg:int = 0,
				index:int = 0,
				end:int;

			while(beg < int.MAX_VALUE){
				match = str.substr(beg).match(/(\(|\)|\[|\]|\"|\'|\,)/);

				if (match)
					end = str.indexOf(match[0],beg);
				else
					end = int.MAX_VALUE;

				if (!match || match[0] == ","){
					subStr = trim(str.substring(index,end));

					if (subStr.length > 0){
						var node:Node = computeNode(subStr,true);

						if (node.getError())
							return new Array(node.getError());
	
						list.push(node.getValue());
					}

					index = end+1;
				}
				else if (match[0] == "'" || match[0] == '"'){
					beg = end;
					end = str.indexOf(match[0],beg+1);
					if (end < 0)
						return new Array(new Output("Syntax Error."));
				}
				else if (match[0] == "["){
					beg = end;
					end = endOfSegment(str.substr(beg),"[","]")+beg;
				}
				else if (match[0] == "("){
					beg = end;
					end = endOfSegment(str.substr(beg),"(",")")+beg;
				}
				else
					return new Array(new Output("Expected " + (match[0] == ")" ? "leftparent before rightparent." : "leftbracket before rightbracket.")));

				beg = end+1;
				if (beg <= 0)
					beg = int.MAX_VALUE;
				
			}
			return list;
		}

		public static function importObjects(dataList:Array,dirList:Array = null):void {
			var idList:Array = new Array("Room","Item","Character","Player","Object"),
				objList:Array = new Array(new Array(),new Array(),new Array(),new Array(),new Array()),
				objSeqList:Array = new Array();

			if (!modules){
				modules = Module.importModules();
				if (modules[0].length > 0)
					reservedList = reservedList.concat(modules[0]);
			}

			removeComments(dataList);

			for (var i:int = 0; i < dataList.length; i++){
				var beg:int = 0,
					nameList:Array = new Array();

				while(beg < dataList[i].length){
			
					var match:Array = dataList[i].substr(beg).match(/[\{\}\[\]\"\'\:\n]/),
						line:int = countLines(dataList[i].substr(0,beg))+1,
						id:String = null,
						instance:String = null,
						end:int;

					if (!match){
						match = new Array("");
						end = int.MAX_VALUE;
					}
					else
						end = dataList[i].indexOf(match[0],beg);

					var subStr:String = trim(dataList[i].substring(beg,end));

					if (!(subStr.length == 0 && match[0] == "\n")){
						if (!(match[0] == '"' || match[0] == "'") && subStr.length > 0 && idList.indexOf(subStr) < 0)
							Output.err('Invalid identifier"'+subStr+'".',dirList[i],line);
						else
							id = subStr;
	
						if (match[0] == ":"){
							if (subStr.length == 0)
								Output.err("Expected identifier before colon.",dirList[i],line);
	
							beg = end+1;
							match = dataList[i].substr(beg).match(/[\{\}\[\]\"\'\:\n]/);
	
							if (!match){
								match = new Array("");
								end = int.MAX_VALUE;
							}
							else
								end = dataList[i].indexOf(match[0],beg);
	
							subStr = trim(dataList[i].substring(beg,end));
	
							if (!(match[0] == '"' || match[0] == "'") && subStr.length > 0){
								if (subStr.length != subStr.replace(/\s+/g, "").length)
									Output.err('Instance name must be one word.',dirList[i],line);
								else if (subStr.length != subStr.replace(/[^a-zA-Z_0-9\$]/g, "").length)
									Output.err('Instance name may only contain letters a-z, the signs _$ and numbers',dirList[i],line);
								else if (!isNaN(Number(subStr.charAt())))
									Output.err('Instance name may not begin with a number.',dirList[i],line);
								else if (isReserved(instance))
									Output.err('"' + instance + '" is a reserved and may not be used as instance name.',dirList[i],line);
								else if (subStr == "player" && id != "Player")
									Output.err('"player" is a reserved instance name for the Player object.',dirList[i],line);
								else if (id){
									var b:Boolean = true;
									for (var j:int = 0; j < objList.length; j++)
										for each (var entry:Array in objList[j])
											if (entry[0] == subStr){
												if (j == idList.indexOf(id))
													instance = subStr;
												else
													Output.err('Duplicate instance name of objects of different types.',dirList[i],line);
												b = false;
												break;
											}

									if (b)
										instance = subStr;
								}
								else
									instance = subStr;
							}
							else if (!(match[0] == '"' || match[0] == "'") && subStr.length == 0){
								if (id == "Player")
									instance = "player";
								else if (id)
									Output.err('Instance name of ' + id +  ' object cannot be null.',dirList[i],line);
							}
							
							if (match[0].length == 0 || match[0] == "\n" || match[0] == "{"){
								if (id && instance){
									subStr = null;
									if (firstChar(dataList[i].substr(dataList[i].indexOf(match[0],beg))) == "{"){
										
										match[0] = "{";
										beg = dataList[i].indexOf("{",beg);
										end = endOfSegment(dataList[i].substr(beg));
	
										if (end >= 0)
											subStr = dataList[i].substring(beg+1,beg+end);
									}

									if (nameList.indexOf(instance) >= 0)
										Output.warn("Duplicate instance name.",dirList[i],line);
									else
										nameList.push(instance);
										
									var objData:Array = new Array(instance,subStr,dirList[i],line);
									objList[idList.indexOf(id)].push(objData);
									objSeqList.push(objData);
								}
							}
							else if (match[0] == ":")
								Output.err("Expected identifier before colon.",dirList[i],line);
							else if (match[0] == "[")
								Output.err("Expected leftbrace or nothing after instance name.",dirList[i],line);
							else if (match[0] == '"' || match[0] == "'")
								Output.err("Instance name cannot be or contain a string.",dirList[i],line);
							else if (match[0] == "}")
								Output.err("Expected leftbrace before rightbrace.",dirList[i],line);
							else if (match[0] == "]")
								Output.err("Expected leftbracket before rightbracket.",dirList[i],line);
						}
						else if (match[0].length == 0 || match[0] == "\n"){
							if (subStr.length > 0)
								Output.err("Expected colon after identifier.",dirList[i],line);
						}
						else if (match[0] == "{" || match[0] == "["){
							if(subStr.length == 0)
								Output.err("Expected identifier before " + (match[0] == "{" ? "leftbrace." : "leftbracket."),dirList[i],line);
							else
								Output.err("Expected colon after identifier.",dirList[i],line);
						}
						else if (match[0] == '"' || match[0] == "'")
							Output.err("Identifier cannot be or contain a string.",dirList[i],line);
						else if (match[0] == "}")
							Output.err("Expected leftbrace before rightbrace.",dirList[i],line);
						else if (match[0] == "]")
							Output.err("Expected leftbracket before rightbracket.",dirList[i],line);

						while(match && match.length > 0 && match[0].length > 0 && match[0] != "\n"){
							if (match[0] == "'" || match[0] == '"'){
								beg = dataList[i].indexOf(match[0],beg);
								end = dataList[i].indexOf(match[0],beg+1);
		
								if (end >= 0)
									beg = end+1;
								else
									beg = int.MAX_VALUE;
							}
							else if (match[0] == "["){
								beg = dataList[i].indexOf("[",beg);
								end = endOfSegment(dataList[i].substr(beg),"[","]");
	
								if (end >= 0)
									beg = beg+end+1;
								else{
									Output.err('Expected rightbracket before end of file.',dirList[i],line);
									beg = int.MAX_VALUE;
								}
							}
							else if (match[0] == "{"){
								beg = dataList[i].indexOf("{",beg);
								end = endOfSegment(dataList[i].substr(beg));
	
								if (end >= 0)
									beg = beg+end+1;
								else{
									Output.err('Expected rightbrace before end of file.',dirList[i],line);
									beg = int.MAX_VALUE;
								}
							}
							else
								beg = dataList[i].indexOf(match[0],beg)+1;
	
							match = dataList[i].substr(beg).match(/[\{\}\[\]\"\'\:\n]/);
						}
					}

					if (!match || match[0].length == 0)
						beg = int.MAX_VALUE;
					else if (match[0] == "\n")
						beg = dataList[i].indexOf("\n",beg)+1;
				}
			}

			for each (var player:Array in objList[idList.indexOf("Player")])
				new Player(player[0]);
			for each (var room:Array in objList[idList.indexOf("Room")])
				if (!Room.getRoom(room[0]))
					new Room(room[0]);
			for each (var char:Array in objList[idList.indexOf("Character")])
				if (!Character.getCharacter(char[0]))
					new Character(char[0]);
			for each (var item:Array in objList[idList.indexOf("Item")])
				if (!Item.getItem(item[0]))
					new Item(item[0]);
			for each (var object:Array in objList[idList.indexOf("Object")])
				if (!GenericObject.getObject(object[0]))
					new GenericObject(object[0]);

			if (Room.count() == 0){
				new Room();
				Output.warn("Missing Room object. Creating default Room.");
			}

			if (!Player.getPlayer()){
				new Player();
				Output.warn("Missing Player object. Creating default Player.");
			}

			readObjData(objSeqList);

			if (!Room.getStartingRoom()){
				Room.setStartingRoom();
				Output.warn("Missing starting room. Assigning default starting room.");
			}

			objIds = Player.getIds().concat(Item.getIds()).concat(Character.getIds()).concat(Room.getIds()).concat(GenericObject.getIds())
		}

		private static function readObjData(objList:Array):void {
			var extensions:Array = new Array(new Array(), new Array());

			for each (var obj:Array in objList)
				if (obj[1]){
					var beg:int = 0,
						object:_Object = _Object.getObject(obj[0]);

					while(beg < obj[1].length){
						var match:Array = obj[1].substr(beg).match(/\=\>|[\{\}\[\]\"\'\:\n\=]/),
							line:int = countLines(obj[1].substr(0,beg))+obj[3],
							id:String = null,
							val:String = null,
							end:int,
							index:int;

						if (!match){
							match = new Array("");
							end = int.MAX_VALUE;
						}
						else
							end = obj[1].indexOf(match[0],beg);

						var subStr:String = trim(obj[1].substring(beg,end));

						if (!(subStr.length == 0 && match[0] == "\n")){
							if (!(match[0] == '"' || match[0] == "'") && subStr.length > 0){
								if (subStr.length != subStr.replace(/\s+/g, "").length)
									Output.err('Identifier cannot contain whitespace.',obj[2],line);
								else if (subStr.length != subStr.replace(/[^a-zA-Z_0-9\$]/g, "").length)
									Output.err('Identifier can only contain letters a-z, the signs _$ and numbers',obj[2],line);
								else if (!isNaN(Number(subStr.charAt())))
									Output.err('Identifier cannot begin with a number.',obj[2],line);
								else if (isReserved(id))
									Output.err('"' + id + '" is reserved and may not be used as property identifier.',obj[2],line);
								else
									id = subStr;
							}

							if (match[0] == ":" || ((match[0] == "=>" || match[0] == "=") && Nav.pathIndex(id) >= 0 && object.getClass() == Room)){
								if (subStr.length == 0)
									Output.err("Expected identifier before colon.",obj[2],line);

								var isConnected:Boolean = match[0] != "=>";

								beg = end+match[0].length;
								match = obj[1].substr(beg).match(/[\{\[\"\'\:\n]/);
			
								if (!match){
									match = new Array("");
									end = int.MAX_VALUE;
								}
								else
									end = obj[1].indexOf(match[0],beg);

								if (match[0] == '"' || match[0] == "'"){
									if (firstChar(obj[1].substring(beg)) == match[0]){
										beg = end;
										end = obj[1].indexOf(match[0],beg+1);
										val = obj[1].substring(beg+1,end);
										index = obj[1].substr(end+1).indexOf("\n");

										if (index < 0)
											index = int.MAX_VALUE;
											
										if (id == "Event"){
											subStr = obj[1].substr(end+1);
											setEvent(val,object,subStr,obj[2],line);
											if (firstChar(subStr) == "{"){
												end = obj[1].indexOf("{",end+1);
												match = new Array("{");
											}
										}
										else if (trim(obj[1].substr(end+1,index)).length == 0){
											// Is String
											Output.err(object.setVar(id,val),obj[2],line);
										}
										else
											Output.err("Syntax error.",obj[2],line);
									}
									else
										Output.err("Syntax error.",obj[2],line);
								}
								else if (match[0] == '['){
									if (firstChar(obj[1].substr(beg)) == '['){
										beg = end;
										end += endOfSegment(obj[1].substr(end),'[',']');
										var list:Array = strToList(obj[1].substring(beg+1,end),obj[2],line);

										if (list){
											// Is List
											if (id == "Event"){
												subStr = obj[1].substr(end+1);
												setEvent(list,object,subStr,obj[2],line);
												if (firstChar(subStr) == "{"){
													end = obj[1].indexOf("{",end+1);
													match = new Array("{");
												}
											}
											else
												Output.err(object.setVar(id,list),obj[2],line);
										}
									}
									else
										Output.err("Syntax error.",obj[2],line);
								}
								else if (match[0] != ':'){
									val = trim(obj[1].substring(beg,end));
									if (val.length != val.replace(/\s+/g, "").length){
										Output.err("Syntax error.",obj[2],line);
									}
									else if (val && val.length > 0){
										if (val == "null"){
											// Is null
											if (id == "Event")
												Output.err("Event cannot be null.",obj[2],line);
											else if (id == "extends")
												Output.err("Cannot extend null.",obj[2],line);
											else
												Output.err(object.setVar(id,null),obj[2],line);
										}
										else if (val == "true" || val == "false"){
											// Is boolean
											if (id == "Event")
												Output.err("Event cannot be a boolean.",obj[2],line);
											else if (id == "extends")
												Output.err("Cannot extend a boolean.",obj[2],line);
											else
												Output.err(object.setVar(id,val == "true"),obj[2],line);
										}
										else if (!isNaN(Number(val))){
											// Is number
											if (id == "Event")
												Output.err("Event cannot be a number.",obj[2],line);
											else if (id == "extends")
												Output.err("Cannot extend a number.",obj[2],line);
											else
												Output.err(object.setVar(id,Number(val)),obj[2],line);
										}
										else{
											var objVal:_Object = _Object.getObject(val);
											if (objVal){
												// Is object
												if (id == "Event")
													Output.err("Event cannot be an object.",obj[2],line);
												else if (id == "extends"){
													if (object.getClass() != objVal.getClass() && objVal.getClass() != GenericObject)
														Output.err(object + " cannot extend " +objVal+ ". Object type mismatch.",obj[2],line);
													else if (object == objVal)
														Output.err("An object cannot extend itself.",obj[2],line);
													else{
														index = extensions[0].indexOf(object);

														if (index >= 0){
															extensions[0][index] = object;
															extensions[1][index] = objVal;
														}
														else{
															extensions[0].push(object);
															extensions[1].push(objVal);
														}
													}
												}
												else
													Output.err(object.setVar(id,objVal,isConnected),obj[2],line);
											}
											else if (object.getListeners().indexOf(val) >= 0){
												// Is Event Listener
												subStr = obj[1].substr(end);
												setEvent(new EventListener(val),object,subStr,obj[2],line);
												if (firstChar(subStr) == "{"){
													end = obj[1].indexOf("{",end);
													match = new Array("{");
												}
											}
											else if (id == "Event" && isListener(val))
												Output.err('Event Listener "' + val +'" cannot be used within parent object of Event.',obj[2],line);
											else if (id == "Event")
												Output.err('Invalid Event Listener "' + val + '".',obj[2],line);
											else
												Output.err('Undefined instance "' + val + '".',obj[2],line);
										}
									}
									else if (id == "Event" || id == "extends")
										Output.err((id == "Event" ? "Event" : "extends" )+" cannot be undefined.",obj[2],line);
								}
								else{
									Output.err("Expected identifier before colon.",obj[2],line);
								}

							}
							else if (match[0] == "=>" || match[0] == "="){
								if (Nav.pathIndex(id) < 0){
									Output.err("Invalid path identifier.",obj[2],line);
									if (match[0] == "=")
										Output.warn("When assigning initial values to an object the assign operator is only allowed for assigning navigation between rooms. Use colon between identifier and value of other properties.",obj[2],line);
								}
								else
									Output.err("Initial navigation between rooms can only be assigned in Room objects.",obj[2],line);
							}
							else if (match[0].length == 0 || match[0] == "\n"){

								if (subStr.length > 0)
									Output.err("Expected colon after identifier.",obj[2],line);
							}
							else if (match[0] == "{" || match[0] == "["){
								if(subStr.length == 0)
									Output.err("Expected identifier before " + (match[0] == "{" ? "leftbrace." : "leftbracket."),obj[2],line);
								else
									Output.err("Expected colon after identifier.",obj[2],line);
							}
							else if (match[0] == '"' || match[0] == "'")
								Output.err("Identifier cannot be or contain a string.",obj[2],line);
							else if (match[0] == "}")
								Output.err("Expected leftbrace before rightbrace.",obj[2],line);
							else if (match[0] == "]")
								Output.err("Expected leftbracket before rightbracket.",obj[2],line);
		
							while(match && match.length > 0 && match[0].length > 0 && match[0] != "\n"){
								if (match[0] == "'" || match[0] == '"'){
									beg = obj[1].indexOf(match[0],beg);
									end = obj[1].indexOf(match[0],beg+1);
				
									if (end >= 0)
										beg = end+1;
									else
										beg = int.MAX_VALUE;
								}
								else if (match[0] == "["){
									beg = obj[1].indexOf("[",beg);
									end = endOfSegment(obj[1].substr(beg),"[","]");
			
									if (end >= 0)
										beg = beg+end+1;
									else{
										Output.err('Expected rightbracket before end of file.',obj[2],line);
										beg = int.MAX_VALUE;
									}
								}
								else if (match[0] == "{"){
									beg = obj[1].indexOf("{",beg);
									end = endOfSegment(obj[1].substr(beg));
			
									if (end >= 0)
										beg = beg+end+1;
									else{
										Output.err('Expected rightbrace before end of file.',obj[2],line);
										beg = int.MAX_VALUE;
									}
								}
								else
									beg = obj[1].indexOf(match[0],beg)+1;

								match = obj[1].substr(beg).match(/[\{\[\"\'\:\n]/);
							}
						}

						if (!match || match[0].length == 0)
							beg = int.MAX_VALUE;
						else if (match[0] == "\n")
							beg = obj[1].indexOf("\n",beg)+1;
					}
				}

			while (extensions[0].length > 0){
				var queue:Array = new Array(extensions[0][0]);
				if (getExtendQueue(0,queue,extensions)){
					while (queue.length > 1){
						queue[queue.length-2].extendsObject(queue[queue.length-1]);
						index = extensions[0].indexOf(queue[queue.length-2]);
						extensions[0].splice(index,1);
						extensions[1].splice(index,1);
						queue.splice(queue.length-1,1);
					}
				}
				else{
					Output.err('Objects cannot extend themselves in a loop.');
					while (queue.length > 0){
						Output.warn('\t"'+queue[queue.length-1] + '" was not extended.');
						index = extensions[0].indexOf(queue[queue.length-1]);
						extensions[0].splice(index,1);
						extensions[1].splice(index,1);
						queue.splice(queue.length-1,1);
					}
				}
			}
		}

		private static function getExtendQueue(index:int,queue:Array,arr:Array):Boolean{
			if (queue.indexOf(arr[1][index]) >= 0)
				return false;
			queue.push(arr[1][index]);
			var i:int = arr[0].indexOf(arr[1][index]);
			if (i >= 0)
				return getExtendQueue(i,queue,arr);
			return true;
		}

		private static function setEvent(val:*,object:_Object,str:String,file:String,line:int):void{
			var evt:*,
				subStr:String,
				enabled:Boolean = true,
				overriding:Boolean = false;

			str = trim(str);

			if (str.charAt() == "{")
				subStr = str.substring(1,endOfSegment(str));

			if (subStr){
				if (toClass(val) == Array){
					var list:Array = val;
					
					if (list.length > 3)
						Output.err("Expected no more than 3 entries in list.",file,line);
					else if (list.length == 0)
						Output.err("Expected at least 1 entry in list.",file,line);
					else{
						var clss:Class = toClass(list[0]);
						if (clss == String || clss == EventListener && object.getListeners().indexOf(String(list[0])) >= 0)
							evt = list[0];
						else{
							if (isListener(list[0]))
								Output.err('Event Listener "' + list[0] +'" cannot be used within parent object of Event.',file,line);
							else
								Output.err("Expected entry 1 in list to be Event Listener or String.",file,line);
							return;
						}

						if (list.length >= 2){
							if (toClass(list[1]) == Boolean || !list[1] && list[1] != null)
								enabled = list[1];
							else{
								Output.err("Expected entry 2 in list to be Boolean.",file,line);
								return;
							}
						}

						if (list.length == 3){
							
							if (toClass(list[2]) == Boolean || !list[2] && list[2] != null)
								overriding = list[2];
							else{
								Output.err("Expected entry 3 in list to be Boolean.",file,line);
								return;
							}
						}
					}
				}
				else
					evt = val;
				
				object.addEvent(new _Event(evt,new Array(subStr,file,line),enabled,overriding,object));
			}
			else
				Output.err("Expected leftbrace after Event.",file,line);
		}

		private static function countLines(str:String):int{
			return str.match(new RegExp("\n","/g")).length;
		}

		private static function strToList(str:String,file:String,line:int):Array{
			var list:Array = new Array(),
				match:Array,
				end:int,
				subStr:String,
				index:int = 0,
				beg:int = 0;
				
			while(beg < str.length){
				match = str.substr(beg).match(/(\[|\]|\"|\'|\,)/);

				if (match)
					end = str.indexOf(match[0],beg);
				else
					end = int.MAX_VALUE;

				if (!match || match[0] == ","){
					subStr = trim(str.substring(beg,end));

					if (subStr.length == 0 || subStr == "null")
						list.push(null);
					else if (subStr == "true" || subStr == "false")
						list.push(subStr == "true");
					else if (!isNaN(Number(subStr)))
						list.push(Number(subStr));
					else{
						var object:_Object = _Object.getObject(trim(subStr));
						if (object)
							list.push(object);
						else if (isListener(subStr))
							list.push(new EventListener(subStr));
						else{
							Output.err("Syntax error.",file,line);
							return null;
						}
					}
				}
				else if (match[0] == "["){
					if (firstChar(str.substr(beg)) == '['){
						beg = end;
						end += endOfSegment(str.substr(end),'[',']');
						subStr = str.substring(beg+1,end);
						index = str.substr(end+1).indexOf(",");

						if (index < 0)
							index = int.MAX_VALUE;
	
						if (trim(str.substr(end+1,index)).length == 0){
							var subList:Array = strToList(subStr,file,line);
	
							if (subList)
								list.push(subList);
							else
								return null;
						}

						end += index+1;
					}
					else{
						Output.err("Syntax error.",file,line);
						return null;
					}
				}
				else if (match[0] != "]"){
					beg = end;
					end = str.indexOf(match[0],beg+1);
					subStr = str.substring(beg+1,end);
					index = str.substr(end+1).indexOf(",");

					if (index < 0)
						index = int.MAX_VALUE;

					if (trim(str.substr(end+1,index)).length == 0)
						list.push(subStr);
					else{
						Output.err("Syntax error.",file,line);
						return null;
					}

					end += index+1;
				}
				else{
					Output.err("Expected leftbracket before rightbracket.",file,line);
					return null;
				}
				
				beg = end+1;
				if (beg <= 0)
					beg = int.MAX_VALUE;
				
			}

			return list;
		}

		private static function removeComments(dataList:Array):void{
			var match:Array,
				index:int,
				end:int;

			for (var i:int = 0; i < dataList.length; i++){
				var beg:int = 0;

				while((match = dataList[i].substr(beg).match(/(\"|\'|\/\/|\/\*)/)) && match[0].length > 0){
					index = dataList[i].indexOf(match[0],beg);

					if (match[0] == "//" || match[0] == "/*"){
						if (match[0] == "//")
							match = dataList[i].match(/\/\/([^]*?)\n/g);
						else
							match = dataList[i].match(/\/\*([^]*?)\*\//g);

						if (match.length > 0){
							end = dataList[i].indexOf(match[0],index)+match[0].length;
							var subStr:String = "";
							for (var j:int = countLines(match[0]); j > 0; j--)
								subStr += "\n";
							dataList[i] = dataList[i].substr(0,index) + subStr + dataList[i].substr(end);
							beg = index;
						}
						else{
							dataList[i] = dataList[i].substr(0,index);
							beg = int.MAX_VALUE;
						}
					}
					else{
						end = dataList[i].indexOf(match[0],index+1);

						if (end >= 0)
							beg = end+1;
						else
							beg = int.MAX_VALUE;
					}
				}
				dataList[i] = dataList[i].replace(/\s+$/g, "");
			}
		}

		private static function isListener(str:String):Boolean {
			return listenerList.indexOf(str) >= 0;
		}

		private static function isReserved(str:String):Boolean {
			return reservedList.indexOf(str) >= 0 || isListener(str);
		}

		private static function trim(str:String):String{
			return (str ? str.replace(/^\s+|\s+$/g, "") : "");
		}

		private static function startsWith(str:String,pattern:String):Boolean{
			if(str.substring(0,pattern.length) == pattern)
				return true;
			return false;
		}

		private static function firstChar(str:String):String{
			return trim(str).charAt();
		}

		private function removeAt(str:String,i:int):String{
			return str.substr(0,i)+str.substr(i+1);
		}
		
		private function getMatch(str:String):*{
			var match:Array = str.match(regex)
			str = trim(str);
			
			if (match[0]){
				if (startsWith(str,match[0]))
					return match[0];
				if (startsWith(str,"!"+match[0]))
					return "!"+match[0];
				if (startsWith(str,"++"+match[0]))
					return "++"+match[0];
				if (startsWith(str,"--"+match[0]))
					return "--"+match[0];
				if (!isNaN(match[0]) && firstChar(str) == "-" && startsWith(trim(str.substr(str.indexOf("-")+1)),match[0]))
					return Number(match[0])*(-1);
				return new Output("Syntax error.");
			}
			return null
		}

		private static function listToClass(list:Array):Array{
			var newList: Array = new Array();
			for (var i:int = 0; i < list.length; i++)
				newList[i] = toClass(list[i]);
			return newList;
		}

		private static function toClass(instance:*):Class{
			if (!instance)
				return null;
			return Class(getDefinitionByName(getQualifiedClassName(instance)));
		}

		private static function numberEnd(str:String):int{
			var match:Array = str.match(/[^0-9\.]/),
				index:int = (match ? str.indexOf(match[0]) : str.length);
			if (str.indexOf(".",str.indexOf(".")+1) > 0)
				return str.indexOf(".",str.indexOf(".")+1);
			return index;
		}

		private static function operandEnd(str:String):int{
			var match:Array = str.match(/[^a-zA-Z_0-9\$]/);
			return (match ? str.indexOf(match[0]) : str.length);
		}

		private function endOfScope(str:String):*{
			var beg:int = 0,
				end:int,
				val:* = getMatch(str),
				match:String = (toClass(val) != Output ? val : null);

			while (match == "if" || match == "while" || match == "foreach" || match == "else"){
				if (match == "else")
					return new Output("Else was unexpected.",beg);
				
				beg = str.indexOf(match,beg)+match.length;
	
				if (firstChar(str.substr(beg)) != "(")
					return new Output('Expected leftparent after "'+match+'".',beg);
		
				beg = str.indexOf("(",beg);
				end = endOfSegment(str.substr(beg),"(",")") + beg;
		
				if (end < beg)
					return new Output("Expected rightparent before end of script.",beg);

				beg = end+1;
				val = getMatch(str.substr(beg));
				match = (toClass(val) != Output ? val : null);
			}
			return beg;
		}

		private static function endOfSegment(str:String,char1:String = "{",char2:String = "}"):int{
			var index:int = str.indexOf(char1),
				charCounter:int = 1,
				regex:RegExp = new RegExp("[\\"+char1+"\\"+char2+"\"\']");

			while (charCounter > 0 && index >= 0){
				var subStr:String = str.substr(++index),
					match:Array = subStr.match(regex),
					prevIndex = index;

				if (!match)
					return -1;
				if (match[0] == char1 || match[0] == char2){
					charCounter += (match[0] == char1 ? 1 : -1);
					index+=subStr.indexOf(match[0]);
					
					if (index < prevIndex)
						return -1;
				}
				else{
					index+=subStr.indexOf(match[0],subStr.indexOf(match[0])+1);

					if (index < prevIndex)
						return str.length;
				}
			}
			return index;
		}

		public static function getModuleIds():Array{
			return modules[0];
		}

		public static function getModuleClass(i:int):Class{
			return modules[2][i];
		}

		public static function getModuleFunc(index:int,str:String):XML{
			for (var i:int = 0; i < modules[1][index].length; i++){
				if (modules[1][index][i].@name == str){
					return modules[1][index][i];
					break;
				}
			}
			return null;
		}
	}
}