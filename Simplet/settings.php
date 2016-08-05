'<!DOCTYPE HTML><html><head><meta charset="UTF-8"><meta http-equiv="refresh" content="10">
<p>
<HEAD>

	<TITLE>ESP8266 - Settings</TITLE>

</HEAD>

<BODY>

	<CENTER><FONT COLOR=BLUE SIZE=6>ESP8266 - Settings</FONT></CENTER>

<BR>

<TABLE>

<TR>

	<TD WIDTH=100> <li><a href="main.html">Main</a></li> </TD>

	<TD WIDTH=100> <li>Settings</li> </TD>

	<TD WIDTH=100> <li><a href="about.html">About</a></li> </TD>

</TR>

</TABLE>

<BR>


<h1><li>Configure a new setpoint</li></h1>

<p><li>Current setpoints</li></p>

<TABLE BORDER=1>

<TR> 

<TD></TD> 

<TD>Temperature</TD>

<TD>Algae con.</TD>

</TR> 

<TR> 

<TD>ESP01</TD>

<!--SP1--><TD></TD>

<TD>Algae_sp</TD>

<TR> 

<TD>ESP02</TD>

<TD>Temp_sp</TD>

<TD>Algae_sp</TD>


</TABLE>


<BR>

<p>1) Select the equipment</p>

<form method="post" action="Select.php">
<select name="equipment">
<option value="01">ESP01</option>
<option value="02">ESP02</option>
</select>

<BR>

<p>2) Select the sensor</p>

<form method="post" action="Select.php">
<select name="sensor">
<option value="01">Temperature</option>
<option value="02">Algae concentration</option>
</select>

<BR>

<p>3) Define the setpoint</p>
<form action='main.html'><p>ENTER THE SETPOINT<input type='text' name='msg' size=50 autofocus> <input type='submit' value='Submit'></form>
<form method="post" action="Select.php">
<select name="setpoint">
<option value="01">Number1</option>
<option value="02">Number2</option>
<option value="02">Number3</option>
</select>

<p>Confirm new setpoint:
<input type="submit" value="OK" /></p>
<hr width="50%" align="left" noshade>
<h1><li>Configure a station</li></h1>
<p>1) Rename a station</p>
<p><li>Select the station:</li></p>
<select name="sensor">
<option value="01">ESP01</option>
<option value="02">ESP02</option>
</select>
<BR>
<BR>
<li>New name:</li>
<form action='settings.html'><p>Enter New Name <input type='text' name='msg' size=50 autofocus> <input type='submit' value='Submit'></form>
<input type="text" name="Nome" size="40" /> 
<input type="button" name="botao-ok" value="Ok">
<BR>
<li>Access point mode:</li>
<select name="sensor">
<option value="01">On</option>
<option value="02">Off</option>
</select>
<input type="button" name="botao-ok" value="Ok">
<hr width="50%" align="left" noshade>
<h1><li>Configure the network</li></h1>
<li>Port number:</li>
<input type="text" name="Nome" size="40" /> 
<input type="button" name="botao-ok" value="Ok">
<BR>
<li>Password:</li>
<input type="text" name="Nome" size="40" /> 
<input type="button" name="botao-ok" value="Ok">


</BODY>

</HTML>
