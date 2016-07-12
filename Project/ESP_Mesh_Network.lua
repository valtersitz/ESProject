***********************************************************************
                            MESH NETWORK
***********************************************************************

myNode = 1 --my node number
partnerNode = 1 -- output the value of this node (can output more than one if needed)
networkSize =  -- number of ESPs in the network, up to 99 for now

-- global variables, keeps the stack small and more predictable if all variables are global

unsigned long timeCentral = 0xFFFFF800 -- synchronise with node 0, as can't reset the millis counter. start high so can spot rollover errors (otherwise every 49 days)
unsigned long timeOffset  = 0xFFFFF800 -- offset from my local millis counter - numbers set so if program node 0, it does a refresh immediately
valueSensor1{} -- tab to store sensor's value
valueSensor2{} 
valueSensor3{} 
valueSensor4{} 
nodeTimestamps{} -- timestamps for each value
lowestNode = 255 -- 0 to 15, 255 is false, 0-15 is node last got a time sync signal from, actually the "main node"
inPacketLen = 0

void setup() -- usefull?
{
  outputRS232();
}

void loop() --usefull?
{
  rxRadio(); -- NOT APPLICABLE HERE: send the message through radio, all the nodes get the message, upload its data during time slot and send it to everyone. 
  NodeTimeSlot(); -- have to find an algorithm to make sure every node upload its data as fast as possible
}

 
// start radio routines

void txRadio(char c)
{
  // send a byte via radio, will display on the remote screen
  altSerial.write(c);
}  

void rxRadio()
{
  byte c;
  while (altSerial.available())
  {
    c = altSerial.read(); // fetch the byte
    processRadioString(c); // is it a command?
  }  
  
}  

function  processReceivedString(receivedString) -- returns the location of infos in the message
  --if (radioString.startsWith("SSID=")) { processSSID();} // parse commands
   if (timeLoc = strfind(receivedString,"Time")) then { processTimeSignal(timeLoc)} end -- parse command
   if (dataLoc = strfind(receivedString, ("Data")) then { processDataMessage(dataLoc)} end -- node,sample,timestamp
   --if (radioString.startsWith("Pack=")) { processPacket();} // all data in one large packet - too large somewhere around 100 bytes starts to error
   --and now delete the receivedstring
   --receivedString = ""; 
end  
  

function processTimeSignal(timeLoc) -- Synchronize all nodes to the first running node ("main"). pass Time03FFFFFFFF where 03 is the previous node and the rest is the number of ms in hexa
 s = strsub (receivedString,timeLoc+4,timeLoc+14);
  --[[   INTENT TO ADAPT INSTRUCTABLE CODE BUT CAN'T SEE THE USE
 messageFrom = strsub(s,1,2)
 if ((messageFrom <= lowestNode) && (myNode != 0))then --  current time slot is less or equal than the last node update number, so refresh time, so minimum number of hops
   nodetime = tmr.now()
   centraltime = strsub(s,3) -- time received with the message, number of ms since system started, up to 49 days
   --centraltime = centraltime + 250; -- probably not usefull offset to allow for delay with transmission, determined by trial and error, if slow, then add more
   timeOffset = centraltime-nodetime --delay 
   lowestNode = messageFrom -- update with the new current time and the lowest node number (ie "main" node)
 end  
end]]
 centraltime = strsub(s,3)
 if tmr.now() < centraltime then        -- if late
    nodetime = centraltime              -- get the right time, synchronization of the system
 else 
    centralTime = tmr.now()             -- update the system time
    comTime = centralTime-centraltime   -- get the communication time between ESPs 
 end 
 transmitTime(ReceivedString)
end -- issue to solve: every 49 days centralTime must be reset   

--[[{       INTRUCTABLE CODE -- can't understand the point of this
 void processTimeSignal() // pass Time=03 00000000 where 03 is the node this came from
{String s;
 unsigned long centraltime;
 unsigned long mytime;
 int messageFrom;
 s = stringMid(radioString,6,2);
 s = "000000" + s;
 messageFrom = (int) hexToUlong(s);
 s = radioString;
 s = stringMid(s,9,8);
 lnprintlcd("Time msg from ");
 printlcdstring((String) messageFrom);
 if ((messageFrom <= lowestNode) && (myNode != 0)) // current time slot is less or equal than the last node update number, so refresh time, so minimum number of hops
 {
   mytime = (unsigned long) millis();
   centraltime = hexToUlong(s); // convert back to a number
   centraltime = centraltime + 250; // offset to allow for delay with transmission, determined by trial and error, if slow, then add more
   timeOffset = centraltime - mytime;
   lnprintlcd("New ");
   displayTime();
   lowestNode = messageFrom; // update with the new current lowest node number
 }  
}]]



--[[void refreshTime()
{
  timeCentral = ((unsigned long) millis()) + timeOffset;
}]]
 

function transmitTime(receivedString) -- send my local time, will converge on the lowest node number's time
  newMessage = strsub (receivedString,timeLoc+4,timeLoc+14)..mynode..centralTime..strsub (receivedString,timeLoc+24)
  --send 
end 

String stringLeft(String s, int i) // stringLeft("mystring",2) returns "my"
{
  String t;
  t = s.substring(0,i);
  return t;
}  

String stringMid(String s, int i, int j) // stringmid("mystring",4,3) returns "tri" (index is 1, not zero)
{
  String t;
  t = s.substring(i-1,i+j-1);
  return t;
}  
  
void processDataMessage() // Data=0312AAAABBBBBBBBcrlf where 03 is from, 12 is node (hex), AAAA is integer data, BBBBBBBB is the time stamp
{
  String s;
  unsigned long node;
  unsigned long valueA0;
  unsigned long valueA1;
  unsigned long timestamp;
  unsigned long from;
  unsigned long age;
  unsigned long previousage;
  //printlcdstring("."); // print a dot as data comes in
  s = "000000" + stringMid(radioString,6,2); // node is 2 bytes
  from = hexToUlong(s); // get where this data came from
  s = "000000" + stringMid(radioString,8,2); // node number
  node = hexToUlong(s);
  s = "0000" + stringMid(radioString,10,4); // get the 2 bytes A0 value
  valueA0 = hexToUlong(s);
  s = "0000" + stringMid(radioString,14,4); // get the 2 bytes A1 value
  valueA1 = hexToUlong(s);
  s = stringMid(radioString,18,8);
  timestamp = hexToUlong(s);
  age = (unsigned long) (timeCentral - timestamp);
  previousage = (unsigned long) (timeCentral - nodeTimestamps[node]);
  if (age < previousage) // more recent data so update
  {
    nodeTimestamps[node] = timestamp; // update the time stamp
    nodeValuesA0[node] = (int) valueA0; // update the values
    nodeValuesA1[node] = (int) valueA1; // A1 as well
    //printlcdstring("Update node");
    //printlcdstringln((String) node);
    analogOutput(); // update the analog outputs
  }  
}  

void createDataMessage() // read A0 and A1 create data string
{
  String s;
  byte i;
  String buildMessage;
  unsigned long u;
  String myNodeString;
  updateMyValue(); // update my analog input
  lnprintlcd("My values=");
  printlcdstring((String) nodeValuesA0[myNode]);
  printlcdstring(",");
  printlcdstring((String) nodeValuesA1[myNode]);
  u = (unsigned long) myNode;
  s = ulongToHex(u);
  myNodeString = "Data=" + stringMid(s,7,2); // from me
  delay(150); // for any previous message to go through
  for (i=0;i<16;i++) {
    buildMessage = myNodeString; // start building a string
    u = (unsigned long) i; // 0 to 15 - 2 bytes for the actual node number
    s = ulongToHex(u);
    buildMessage += stringMid(s,7,2);
    u = (unsigned long) nodeValuesA0[i];
    s = ulongToHex(u);
    buildMessage += stringMid(s,5,4); // data value in hex for A0
    u = (unsigned long) nodeValuesA1[i];
    s = ulongToHex(u);
    buildMessage += stringMid(s,5,4); // data value in hex for A1
    s = ulongToHex(nodeTimestamps[i]); // timestamp value for this node
    buildMessage += s;// add this
    altSerial.println(buildMessage); // transmit via radio
    delay(150); // errors on 75, ok on 100
  }
}  

void outputRS232() // output all mesh values in one long hex string to RS232 port aaaabbbbccccdddd etc where a is node 0 value 0, b is node 0 value 1, c is node 1 value 0
{
  String buildMessage;
  byte i;
  String s;
  unsigned long u;
  buildMessage = "All values=";
  for (i=0;i<16;i++) {
    u = (unsigned long) nodeValuesA0[i];
    s = ulongToHex(u);
    buildMessage += stringMid(s,5,4); // data value in hex for A0
    u = (unsigned long) nodeValuesA1[i];
    s = ulongToHex(u);
    buildMessage += stringMid(s,5,4); // data value in hex for A1
   }   
 Serial.println(buildMessage);  
}  
  
void updateMyValue()
{
  refreshTime(); // timecentral
  int sensorValue = analogRead(A0);
  nodeValuesA0[myNode] = sensorValue;
  sensorValue = analogRead(A1);
  nodeValuesA1[myNode] = sensorValue;
  nodeTimestamps[myNode] = timeCentral; // this was updated now
}  

void NodeTimeSlot() // takes 100ms at beginning of slot so don't tx during this time.
// time slots are 4096 milliseconds - easier to work with binary maths
{
  unsigned long t;
  unsigned long remainder;
  int timeSlot = 0;
  refreshTime(); // update timeCentral
  t = timeCentral >> 12; // 4096ms counter
  t = t << 12; // round
  remainder = timeCentral - t;
  if (( remainder >=0) && (remainder < 100)) // beginning of a 4096ms time slot
  {
     digitalWrite(13,HIGH);
     //printlcdstring("Slot ");
     timeSlot = getTimeSlot();
     lnprintlcd((String) timeSlot);
     printlcdstring(" ");
     //printPartnerNode(); // print my partner's value
     printNode(timeSlot); // print the value of this node
     //printHeapStack(); // heap should always be less than stack
     if ( timeSlot == 0) { lowestNode = 255; } // reset if nod zero get time from the lowest node number, 0 to 15 and if 255 then has been reset
     delay(110);
     digitalWrite(13,LOW);
     if (timeSlot == myNode) // transmit if in my time slot
     {
       lnprintlcd("Sending my data"); // all nodes transmit central time, when listening, take the lowest number and ignore others
       transmitTime();
       digitalWrite(13,HIGH); // led on while tx long data message
       createDataMessage(); // send out all my local data via radio
       outputRS232(); // send out all the node values via RS232 port (eg to a PC)
       digitalWrite(13,LOW); // led off
       //buildPacket(); - too large, deleted this
       //printPartnerNode(); // print my partner's value
      }
  }  
}  

int getTimeSlot() // find out which time slot we are in
{
  int n;
  unsigned long x;
  refreshTime();
  x = timeCentral >> 12; // divide by 4096
  x = x & 0x0000000F; // mask so one of 16
  n = (int) x;
  return n;
}  

//void printPartnerNode() // can output partner node's values or do other things
//{
//  printlcdstring("Mate ");
//  printlcdstring((String) partnerNode);
//  printlcdstring("=");
//  printlcdstring((String) nodeValuesA0[partnerNode]);
//  printlcdstring(",");
//  printlcdstring((String) nodeValuesA1[partnerNode]);
//}  

void printNode(int x) // print current node
{
  printlcdstring("= ");
  printlcdstring((String) nodeValuesA0[x]);
  printlcdstring(",");
  printlcdstring((String) nodeValuesA1[x]);
  
}  
  
/* This function places the current value of the heap and stack pointers in the
 * variables. You can call it from any place in your code and save the data for
 * outputting or displaying later. This allows you to check at different parts of
 * your program flow.
 * The stack pointer starts at the top of RAM and grows downwards. The heap pointer
 * starts just above the static variables etc. and grows upwards. SP should always
 * be larger than HP or you'll be in big trouble! The smaller the gap, the more
 * careful you need to be. Julian Gall 6-Feb-2009.
 */
uint8_t * heapptr, * stackptr;
void check_mem() {
  stackptr = (uint8_t *)malloc(4);          // use stackptr temporarily
  heapptr = stackptr;                     // save value of heap pointer
  free(stackptr);      // free up the memory again (sets stackptr to 0)
  stackptr =  (uint8_t *)(SP);           // save value of stack pointer
}

void printHeapStack()
{
  int n;
  check_mem();
  printlcdstring("Heap/Stack=");
  n = (int) heapptr;
  printlcdstring((String) n);
  printlcdstring(",");
  n = (int) stackptr;
  printlcdstring((String) n);
}    

void analogOutput() // output on pins 3 and 5 my partner's voltages
{
  int x;
  x = nodeValuesA0[partnerNode];
  analogWrite(3, x/4); // analog inputs are 0-1023, outputs are 0-255
  x = nodeValuesA1[partnerNode];
  analogWrite(5, x/4);
}