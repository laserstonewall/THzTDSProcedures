#pragma rtGlobals=1		// Use modern global access method.

//This adds a menu macro, so that the user doesn't have to remember that it is ChrisTHz() function that opens everything
Menu "Macros"
	"Display THz control panel/1", ChrisTHz()
End

function ChrisTHz()

	//Save the current data folder, b/c we will be moving to the new data folder to hold
	//the global variables, and we will need to go back to that
	String dfSave = GetDataFolder(1)
	
	//Create data folder in Packages, isolates it from the user so don't get a bunch of variables clogging stuff up
	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S root:Packages:ChrisTHzExtras
	
	//Brings window to front if open already, or opens if not
	DoWindow/HIDE=? $("ChrisTHzWindow")
	if (V_flag != 0)
		DoWindow/F ChrisTHzWindow;
	else
		Execute/Q "ChrisTHzWindow()"
	endif
	
	//-------Set up the global constants-------//
	
	//gzero_pad stores the zeropadding
	ControlInfo/W=ChrisTHzWindow zero_padding_selector
	String/G gzero_pad = S_value
	
	//gwin_fun stores the desired window function
	ControlInfo/W=ChrisTHzWindow win_fun_selector
	String/G gwin_fun= S_value

	//goffset_begin is the beginning of the time period averaged to get rid of the DC offset
	Variable offset_begin_dummy = NumVarOrDefault("root:Packages:ChrisTHzExtras:goffset_begin",0)
	Variable/G goffset_begin = offset_begin_dummy//V_Value
	
	//goffset_end is the end of the time period averaged to get rid of the DC offset
	Variable offset_end_dummy = NumVarOrDefault("root:Packages:ChrisTHzExtras:goffset_end",2)
	Variable/G goffset_end = offset_end_dummy//V_Value
	
	//------------Variables related to killing and adding points at the beginning and end of the time trace-----------//
		//gkill_begin_value is the number of points to delete off the beginning of the trace
		Variable kill_begin_dummy = NumVarOrDefault("root:Packages:ChrisTHzExtras:gkill_begin_value",0)
		Variable/G gkill_begin_value = kill_begin_dummy//V_Value
		
		//gkill_end_value is the point after which all the rest of the wave points will be deleted
		Variable kill_end_dummy = NumVarOrDefault("root:Packages:ChrisTHzExtras:gkill_end_value",300)
		Variable/G gkill_end_value = kill_end_dummy//V_Value
		
		//gnumpnts_begin is the number of points to add to the beginning of the trace
		Variable numpnts_begin_dummy = NumVarOrDefault("root:Packages:ChrisTHzExtras:gnumpnts_begin",0)
		Variable/G gnumpnts_begin = numpnts_begin_dummy//V_Value
		
		//gvalpnts_begin is the number of points to add to the beginning of the trace
		Variable valpnts_begin_dummy = NumVarOrDefault("root:Packages:ChrisTHzExtras:gvalpnts_begin",0)
		Variable/G gvalpnts_begin = valpnts_begin_dummy//V_Value
		
		//gnumpnts_end is the number of points to add to the end of the trace
		Variable numpnts_end_dummy = NumVarOrDefault("root:Packages:ChrisTHzExtras:gnumpnts_end",0)
		Variable/G gnumpnts_end = numpnts_end_dummy//V_Value
		
		//gvalpnts_end is the number of points to add to the beginning of the trace
		Variable valpnts_end_dummy = NumVarOrDefault("root:Packages:ChrisTHzExtras:gvalpnts_end",0)
		Variable/G gvalpnts_end = valpnts_end_dummy//V_Value
	//----------------------------------------------------------------------------------------------------------------------------------//
	
	//-------------Variables related to loading the file, which columns, etc.-------------------------------------//
		//gmult_file_string stores the previously loaded multiple files for convenient reloading
		String mult_file_dummy = StrVarOrDefault("gmult_file_string","")
		String/G gmult_file_string = mult_file_dummy
		
		//gtrace_type stores which type of file you are loading from so the correct columns are loaded
		ControlInfo/W=ChrisTHzWindow trace_type_selector
		String/G gtrace_type = S_value
		
		//gdata_columns stores which type of file you are loading from so the correct columns are loaded
		ControlInfo/W=ChrisTHzWindow data_columns_selector
		String/G gdata_type = S_value
		
		//Now that we have set an initial data type and column to load, let's use the set variable's command
		Variable/G grow_data_start, gstage_pos, gtime_trace, gx_data
		
		set_data_loads();
	//----------------------------------------------------------------------------------------------------------------------------------//
	
	//---------------Set the enabled/disabled states of set variable boxes based on the associated checkboxes-------------//
		ControlInfo/W=ChrisTHzWindow Offset_checkbox
		if(V_Value == 0)
			SetVariable begin_time_control, win = ChrisTHzWindow, disable=2
			SetVariable end_time_control, win = ChrisTHzWindow, disable=2
		elseif(V_Value == 1)
			SetVariable begin_time_control, win = ChrisTHzWindow, disable=0
			SetVariable end_time_control, win = ChrisTHzWindow, disable=0
		endif
		
		ControlInfo/W=ChrisTHzWindow Kill_Begin_Points
		if(V_Value == 0)
			SetVariable kill_begin_value, win = ChrisTHzWindow, disable=2
		elseif(V_Value == 1)
			SetVariable kill_begin_value, win = ChrisTHzWindow, disable=0
		endif
		
		ControlInfo/W=ChrisTHzWindow Kill_End_Points
		if(V_Value == 0)
			SetVariable kill_end_value, win = ChrisTHzWindow, disable=2
		elseif(V_Value == 1)
			SetVariable kill_end_value, win = ChrisTHzWindow, disable=0
		endif
		
		ControlInfo/W=ChrisTHzWindow AddBeginWave
		if(V_Value == 0)
			SetVariable num_begin_add, win = ChrisTHzWindow, disable=2
			SetVariable value_begin_add, win = ChrisTHzWindow, disable=2
		elseif(V_Value == 1)
			SetVariable num_begin_add, win = ChrisTHzWindow, disable=0
			SetVariable value_begin_add, win = ChrisTHzWindow, disable=0
		endif
		
		ControlInfo/W=ChrisTHzWindow AddEndWave
		if(V_Value == 0)
			SetVariable num_End_add, win = ChrisTHzWindow, disable=2
			SetVariable value_End_add, win = ChrisTHzWindow, disable=2
		elseif(V_Value == 1)
			SetVariable num_End_add, win = ChrisTHzWindow, disable=0
			SetVariable value_End_add, win = ChrisTHzWindow, disable=0
		endif
	//-----------------------------------------------------------------------------------------------------------------------------------------------------------------//
	
	//Go back to the original data folder
	SetDataFolder dfSave
	
end

Window ChrisTHzWindow() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(899,81,1464,793)
	ModifyPanel frameStyle=3
	SetDrawLayer UserBack
	SetDrawEnv fsize= 16,fstyle= 1
	DrawText 33,23,"Chris THz Control Panel"
	SetDrawEnv linethick= 3,linebgc= (56576,56576,56576)
	DrawLine 0,350,251,350
	DrawLine 64,219,64,219
	DrawLine 85,235,85,235
	SetDrawEnv fsize= 16,fstyle= 5
	DrawText 374,26,"Time trace"
	SetDrawEnv fsize= 16,fstyle= 1
	DrawText 69,374,"Axis rescales"
	SetDrawEnv linethick= 3,linebgc= (56576,56576,56576)
	DrawLine 0,25,251,25
	DrawText 55,148,"Arbitrary naming allowed"
	SetDrawEnv linefgc= (26112,26112,26112),linebgc= (56576,56576,56576)
	DrawLine -5,160,252,160
	DrawText 28,231,"Name must be XXXX_1, XXXX_2, etc."
	DrawText 8,306,"Name must be ApXXX_YYYK, SaXXX_YYYK"
	SetDrawEnv linefgc= (26112,26112,26112),linebgc= (56576,56576,56576)
	DrawLine -5,239,252,239
	DrawText 56,324,"where XXX is any text and"
	DrawText 45,342,"YYY is a decimal temperature"
	DrawRect 21,74,21,74
	DrawRect 215,307,215,307
	SetDrawEnv fsize= 14,fstyle= 1
	DrawText 324,360,"Custom load parameters:"
	DrawText 304,469,"Row/column enumeration starts from 0"
	DrawText 293,487,"Assumes data columns order: x, y, r, phase"
	SetDrawEnv fsize= 14,fstyle= 1
	DrawText 72,512,"Left axis type"
	SetDrawEnv linefgc= (26112,26112,26112),linebgc= (56576,56576,56576)
	DrawLine -5,515,252,515
	SetDrawEnv fsize= 16
	DrawText 121,690,"You can use Ctrl+1 to bring up THz control panel"
	SetDrawEnv fsize= 16,fstyle= 5
	DrawText 296,529,"Fast Fourier Transform (FFT)"
	Button LoadMultipleSelections,pos={35,34},size={180,40},proc=ButtonProc_LoadMultipleTraces,title="Select/Load Time\r Trace(s) / Do FFTs"
	Button LoadMultipleSelections,fStyle=1
	Button Start100pl,pos={35,169},size={180,40},proc=Do_100_percent_line,title="Do 100% Lines"
	Button Start100pl,fStyle=1
	Button Transmission_Aperture,pos={34,246},size={180,40},proc=Do_Transmission_With_Aperture,title="Transmission with aperture"
	Button Transmission_Aperture,fStyle=1
	Button Fix_Axes,pos={129,379},size={130,30},proc=ChangeAxes_TransmissionValues,title="Trans 0.1-3.0 THz"
	Button Fix_Axes,fStyle=1
	Button Axes_100pct,pos={6,379},size={115,30},proc=ChangeAxes_100pct_values,title="100% axes"
	Button Axes_100pct,fStyle=1
	PopupMenu zero_padding_selector,pos={300,558},size={201,21},bodyWidth=100,proc=ZeroPad_PopUp_Procedure,title="Zero padding value: "
	PopupMenu zero_padding_selector,mode=1,popvalue="None",value= #"\"None;512;1024;2048;4096;8192;16384;32768;65536\""
	Button Axes_100p01,pos={6,417},size={115,30},proc=ChangeAxes_TimeTraceValues,title="Time trace"
	Button Axes_100p01,fStyle=1
	PopupMenu win_fun_selector,pos={318,587},size={183,21},bodyWidth=100,proc=WinFunPopUpProcedure,title="Window Fuction:"
	PopupMenu win_fun_selector,mode=1,popvalue="None",value= #"\"None;Hanning;Hemming;Bartlet;Blackman;Cos1;Cos2;Cos3;Cos4;Blackman367;Blackman361;Blackman492;Blackman474;KaiserBessel;KaiserBessel20;KaiserBessel25;KaiserBessel30;Parzen;Riemann;Poisson2;Poisson3;Poisson4\""
	Button defaulter,pos={330,631},size={119,28},proc=DefaultButton,title="Reset to Defaults"
	Button defaulter,fStyle=1
	SetVariable begin_time_control,pos={300,55},size={116,16},bodyWidth=40,title="Begin time (ps):"
	SetVariable begin_time_control,limits={-inf,inf,0},value= root:Packages:ChrisTHzExtras:goffset_begin
	SetVariable end_time_control,pos={424,55},size={108,16},bodyWidth=40,title="End time (ps):"
	SetVariable end_time_control,limits={-inf,inf,0},value= root:Packages:ChrisTHzExtras:goffset_end
	CheckBox FFT_checkbox,pos={362,536},size={86,16},proc=CheckProc,title="Do FFTs?"
	CheckBox FFT_checkbox,fSize=14,fStyle=1,value= 1
	Button Fix_Axes1,pos={128,417},size={130,30},proc=ChangeAxes_TransmissionValues2,title="Trans 0.1-1.0 THz"
	Button Fix_Axes1,fStyle=1
	Button ReloadLastSelections,pos={35,85},size={180,40},proc=ButtonProc_ReloadMultTraces,title="Reload previous\rselection(s)"
	Button ReloadLastSelections,fStyle=1
	Button log_axes,pos={137,523},size={115,31},proc=ButtonProc_LogLeftAxis,title="Log"
	Button log_axes,fStyle=1
	Button linear_axes,pos={7,523},size={115,31},proc=ButtonProc_LinearLeftAxis,title="Linear"
	Button linear_axes,fStyle=1
	PopupMenu trace_type_selector,pos={296,276},size={232,21},bodyWidth=150,proc=Trace_Type_Popup,title="Trace file format:"
	PopupMenu trace_type_selector,mode=1,popvalue="Original THz Pointcounter",value= #"\"Original THz Pointcounter;Magnet Manual Scan;Magnet Auto Scan;Custom\""
	PopupMenu data_columns_selector,pos={308,308},size={210,21},bodyWidth=120,proc=Data_Column_Popup,title="Data type to load: "
	PopupMenu data_columns_selector,mode=3,popvalue="X channel (V)",value= #"\"Time (ps);Axis Position (um);X channel (V);Y channel (V);R: Magnitude (V);Phase (rad)\""
	SetVariable first_data_row,pos={364,368},size={126,16},bodyWidth=30,title="Row data starts at: "
	SetVariable first_data_row,limits={0,inf,0},value= root:Packages:ChrisTHzExtras:grow_data_start
	SetVariable position_data_colum,pos={335,389},size={155,16},bodyWidth=30,title="Column of stage position: "
	SetVariable position_data_colum,limits={0,inf,0},value= root:Packages:ChrisTHzExtras:gstage_pos
	SetVariable x_data_column,pos={379,432},size={111,16},bodyWidth=30,title="Column of data: "
	SetVariable x_data_column,limits={0,inf,0},value= root:Packages:ChrisTHzExtras:gx_data
	SetVariable time_data_column,pos={354,410},size={136,16},bodyWidth=30,title="Column of time trace: "
	SetVariable time_data_column,limits={0,inf,0},value= root:Packages:ChrisTHzExtras:gtime_trace
	CheckBox Offset_checkbox,pos={289,35},size={125,16},proc=CheckProc_offset,title="Subtract offset?"
	CheckBox Offset_checkbox,fSize=14,fStyle=1,value= 1
	Button autoscaler,pos={64,455},size={130,30},proc=ButtonProc_1,title="Auto Scale"
	Button autoscaler,fStyle=1
	CheckBox Kill_Begin_Points,pos={289,85},size={224,16},proc=CheckProc_KillBegin,title="Delete points from beginning?"
	CheckBox Kill_Begin_Points,fSize=13,fStyle=1,value= 0
	CheckBox Kill_End_Points,pos={289,132},size={182,16},proc=CheckProc_KillEnd,title="Delete points from end?"
	CheckBox Kill_End_Points,fSize=13,fStyle=1,value= 0
	SetVariable kill_begin_value,pos={317,106},size={190,16},disable=2,title="Kill x points at the beginning:"
	SetVariable kill_begin_value,limits={-inf,inf,0},value= root:Packages:ChrisTHzExtras:gkill_begin_value
	SetVariable kill_end_value,pos={317,152},size={190,16},disable=2,title="Kill everything after point:     "
	SetVariable kill_end_value,limits={-inf,inf,0},value= root:Packages:ChrisTHzExtras:gkill_end_value
	CheckBox AddBeginWave,pos={289,177},size={261,16},proc=AddPntsBeginCheck,title="Add points to time trace beginning?"
	CheckBox AddBeginWave,fSize=13,fStyle=1,value= 0
	SetVariable num_begin_add,pos={291,196},size={134,16},disable=2,title="How many points?"
	SetVariable num_begin_add,limits={-inf,inf,0},value= root:Packages:ChrisTHzExtras:gnumpnts_begin
	SetVariable value_begin_add,pos={431,195},size={119,16},disable=2,title="What value?"
	SetVariable value_begin_add,limits={-inf,inf,0},value= root:Packages:ChrisTHzExtras:gvalpnts_begin
	CheckBox AddEndWave,pos={289,221},size={240,16},proc=AddPntsEndCheck,title="Add points to time trace ending?"
	CheckBox AddEndWave,fSize=13,fStyle=1,value= 0
	SetVariable num_end_add,pos={291,240},size={134,16},disable=2,title="How many points?"
	SetVariable num_end_add,limits={-inf,inf,0},value= root:Packages:ChrisTHzExtras:gnumpnts_end
	SetVariable value_end_add,pos={431,239},size={119,16},disable=2,title="What value?"
	SetVariable value_end_add,limits={-inf,inf,0},value= root:Packages:ChrisTHzExtras:gvalpnts_end
EndMacro

Function ZeroPad_PopUp_Procedure(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			SVAR gzero_pad = root:Packages:ChrisTHzExtras:gzero_pad
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			gzero_pad = popStr
			
			break
	endswitch

	return 0
End

Function WinFunPopUpProcedure(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			SVAR gwin_fun = root:Packages:ChrisTHzExtras:gwin_fun
			Variable popNum = pa.popNum
			gwin_fun = pa.popStr
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function Trace_Type_Popup(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			SVAR gtrace_type = root:Packages:ChrisTHzExtras:gtrace_type
			gtrace_type = popStr
			
			set_data_loads();
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function Data_Column_Popup(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			SVAR gdata_type = root:Packages:ChrisTHzExtras:gdata_type
			gdata_type = popStr
			
			set_data_loads();
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function DefaultButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			SVAR gzero_pad = root:Packages:ChrisTHzExtras:gzero_pad
			SVAR gwin_fun = root:Packages:ChrisTHzExtras:gwin_fun
			NVAR goffset_begin = root:Packages:ChrisTHzExtras:goffset_begin
			NVAR goffset_end = root:Packages:ChrisTHzExtras:goffset_end
			
			PopUpMenu zero_padding_selector, win = ChrisTHzWindow, popmatch = "None"
			PopUpMenu win_fun_selector, win = ChrisTHzWindow, popmatch = "None"
			goffset_begin = 0
			goffset_end = 2
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


function set_data_loads()

	SVAR gtrace_type = root:Packages:ChrisTHzExtras:gtrace_type
	SVAR gdata_type = root:Packages:ChrisTHzExtras:gdata_type

	NVAR grow_data_start = root:Packages:ChrisTHzExtras:grow_data_start
	NVAR gstage_pos = root:Packages:ChrisTHzExtras:gstage_pos
	NVAR gtime_trace = root:Packages:ChrisTHzExtras:gtime_trace
	NVAR gx_data = root:Packages:ChrisTHzExtras:gx_data

	if(cmpstr(gtrace_type,"Original THz Pointcounter") == 0)
		grow_data_start = 3
		gstage_pos = 2
		gtime_trace = 1
		gx_data = 3
	elseif(cmpstr(gtrace_type,"Magnet Manual Scan") == 0)
		grow_data_start = 3
		gstage_pos = 2
		gtime_trace = 1
		gx_data = 3
	elseif(cmpstr(gtrace_type,"Magnet Auto Scan") == 0)
		grow_data_start = 3
		gstage_pos = 4
		gtime_trace = 3
		gx_data = 5
	elseif(cmpstr(gtrace_type,"Custom") == 0)
		//grow_data_start = 0
		//gstage_pos = 0
		//gtime_trace = 0
		//gx_data = 0
	endif
	
	if(cmpstr(gdata_type,"Time (ps)") == 0)
		//Print "Time"
		gx_data -= 2
		CheckBox Offset_checkbox, win = ChrisTHzWindow, value = 0
		CheckBox FFT_checkbox, win = ChrisTHzWindow, value = 0
	elseif(cmpstr(gdata_type,"Axis Position (um)") == 0)
		//Print "Axis Pos"
		gx_data -= 1
		CheckBox Offset_checkbox, win = ChrisTHzWindow, value = 0
		CheckBox FFT_checkbox, win = ChrisTHzWindow, value = 0
	elseif(cmpstr(gdata_type,"X channel (V)") == 0)
		//Print "X chan"
		CheckBox Offset_checkbox, win = ChrisTHzWindow, value = 1
		CheckBox FFT_checkbox, win = ChrisTHzWindow, value = 1
	elseif(cmpstr(gdata_type,"Y channel (V)") == 0)
		//Print "Y chan"
		gx_data += 1
		CheckBox Offset_checkbox, win = ChrisTHzWindow, value = 1
		CheckBox FFT_checkbox, win = ChrisTHzWindow, value = 1
	elseif(cmpstr(gdata_type,"R: Magnitude (V)") == 0)
		//Print "R: Mag"
		gx_data += 2
		CheckBox Offset_checkbox, win = ChrisTHzWindow, value = 0
		CheckBox FFT_checkbox, win = ChrisTHzWindow, value = 0
	elseif(cmpstr(gdata_type,"Phase (rad)") == 0)
		//Print "Phase (rad)"
		gx_data += 3
		CheckBox Offset_checkbox, win = ChrisTHzWindow, value = 0
		CheckBox FFT_checkbox, win = ChrisTHzWindow, value = 0
	endif

end

function SingleWaveLoad(folder,file)
	String folder, file	//Folder must have a colon at the end
	
	NVAR goffset_begin = root:Packages:ChrisTHzExtras:goffset_begin
	NVAR goffset_end = root:Packages:ChrisTHzExtras:goffset_end
	
	NVAR gkill_begin_value = root:Packages:ChrisTHzExtras:gkill_begin_value
	NVAR gkill_end_value = root:Packages:ChrisTHzExtras:gkill_end_value
	
	NVAR gnumpnts_begin = root:Packages:ChrisTHzExtras:gnumpnts_begin
	NVAR gvalpnts_begin = root:Packages:ChrisTHzExtras:gvalpnts_begin
	NVAR gnumpnts_end = root:Packages:ChrisTHzExtras:gnumpnts_end
	NVAR gvalpnts_end = root:Packages:ChrisTHzExtras:gvalpnts_end
	
	
	NVAR grow_data_start = root:Packages:ChrisTHzExtras:grow_data_start
	NVAR gstage_pos = root:Packages:ChrisTHzExtras:gstage_pos
	NVAR gtime_trace = root:Packages:ChrisTHzExtras:gtime_trace
	NVAR gx_data = root:Packages:ChrisTHzExtras:gx_data
	
	String columnInfoStr	
	
	//Load the wave, then load the scaling for the wave
	columnInfoStr = "C=" + num2str(gx_data) + ";N=dummy_old_wave;"
	LoadWave/O/Q/A/J/D/K=0/L={0,grow_data_start,0,gx_data,1}/B=columnInfoStr folder + file
	
	columnInfoStr = "C=" + num2str(gtime_trace) + ";N=Scale;"
	LoadWave/O/Q/A/J/D/K=0/L={0,(grow_data_start + 1),1,gtime_trace,1}/B=columnInfoStr folder + file
	
	//LoadWave/O/Q/N/J/D/K=0/L={0,3,0,3,1}/B="N=dummy_old_wave;" folder + file
	//LoadWave/O/Q/W/A/J/D/K=0/L={0,4,1,1,1}/B="C=1;N=Scale;" folder + file
	
	//Take away the .txt if it's there
	if(strsearch(file,".txt",0) > 0)
		file = RemoveEnding(file,".txt")
	endif
	
	Wave dummy_old_wave = $"dummy_old_wave"
	Wave Scale = $"Scale"
	
	//This gets around the naming problem if illegal characters exist, like "."
	Make/O/N=(numpnts(dummy_old_wave)) $file
	Wave dummy_new_wave = $file
	dummy_new_wave = dummy_old_wave
	KillWaves dummy_old_wave
	
	//---------Scale the wave----------//
	Variable scaling = Scale[0]
	SetScale/P x 0,scaling,"", dummy_new_wave
	
	//---------Subtract offset only if checked on the control panel----------//
	ControlInfo/W=ChrisTHzWindow Offset_checkbox
	if(V_Value == 1)
		wavestats/Q/R=((goffset_begin),(goffset_end)) dummy_new_wave; dummy_new_wave -= V_avg;
	endif
	
	//---------Delete points at the end and beginning of the wave if the boxes are checked---------//
	ControlInfo/W=ChrisTHzWindow Kill_End_Points
	if(V_Value == 1)
		DeletePoints gkill_end_value, (numpnts(dummy_new_wave) - gkill_end_value), dummy_new_wave
	endif
	ControlInfo/W=ChrisTHzWindow Kill_Begin_Points
	if(V_Value == 1)
		DeletePoints 0, gkill_begin_value, dummy_new_wave
	endif
	
	//----------Add points to the beginning and end of the wave if boxes are checked-------//
	Variable i;
	ControlInfo/W=ChrisTHzWindow AddBeginWave
	if(V_Value == 1)
		InsertPoints 0, gnumpnts_begin, dummy_new_wave
		for(i = 0; i < gnumpnts_begin; i += 1)
			dummy_new_wave[i] = gvalpnts_begin
		endfor
	endif
	
	ControlInfo/W=ChrisTHzWindow AddEndWave
	if(V_Value == 1)
		Variable wavelength = numpnts(dummy_new_wave)
		InsertPoints wavelength, gnumpnts_end, dummy_new_wave
		for(i = wavelength; i < wavelength + gnumpnts_end; i += 1)
			dummy_new_wave[i] = gvalpnts_end
		endfor
	endif
	
	KillWaves Scale	
	
end

function killendpoints(fname,ptstart)

	String fname
	Variable ptstart
	
	Wave dummy_wave = $fname
	
	DeletePoints ptstart, (numpnts(dummy_wave) - ptstart), dummy_wave
	
end

function killbeginpoints(fname,numpnt)

	String fname
	Variable numpnt
	
	Wave dummy_wave = $fname
	
	DeletePoints 0, numpnt, dummy_wave
	
end

function SingleWaveLoadMagnetAutoScans(folder,file)
	String folder, file	//Folder must have a colon at the end
	
	NVAR goffset_begin = root:Packages:ChrisTHzExtras:goffset_begin
	NVAR goffset_end = root:Packages:ChrisTHzExtras:goffset_end
	
	Wave dummy_old_wave
	Make/O dummy_old_wave, Scale
	
	//Load the wave, then load the scaling for the wave
	LoadWave/O/Q/A/J/D/K=0/L={2,3,0,5,1}/B="C=5;N=dummy_old_wave;" folder + file
	LoadWave/O/Q/W/A/J/D/K=0/L={0,4,1,3,1}/B="C=3;N=Scale;" folder + file
	
	//Take away the .txt if it's there
	if(strsearch(file,".txt",0) > 0)
		file = RemoveEnding(file,".txt")
	endif
	
	//This gets around the naming problem if illegal characters exist, like "."
	Make/O/N=(numpnts(dummy_old_wave)) $file
	Wave dummy_new_wave = $file
	dummy_new_wave = dummy_old_wave
	KillWaves dummy_old_wave
	
	//Scale the wave and correct the offset
	Variable scaling = Scale[0]
	SetScale/P x 0,scaling,"", dummy_new_wave
	wavestats/Q/R=((goffset_begin),(goffset_end)) dummy_new_wave; dummy_new_wave -= V_avg;
	KillWaves Scale	
	
	Variable wave_kill_start = 955
	DeletePoints wave_kill_start, (numpnts(dummy_new_wave)-wave_kill_start), dummy_new_wave
	
end

function SingleWaveLoadY(folder,file)
	String folder, file	//Folder must have a colon at the end
	
	NVAR goffset_begin = root:Packages:ChrisTHzExtras:goffset_begin
	NVAR goffset_end = root:Packages:ChrisTHzExtras:goffset_end
	
	Wave dummy_old_wave
	Make/O dummy_old_wave, Scale
	
	//Load the wave, then load the scaling for the wave
	LoadWave/O/Q/A/J/D/K=0/L={2,3,0,4,1}/B="C=4;N=dummy_old_wave;" folder + file
	LoadWave/O/Q/W/A/J/D/K=0/L={0,4,1,1,1}/B="C=1;N=Scale;" folder + file
	
	//Take away the .txt if it's there
	if(strsearch(file,".txt",0) > 0)
		file = RemoveEnding(file,".txt")
	endif
	
	//This gets around the naming problem if illegal characters exist, like "."
	Make/O/N=(numpnts(dummy_old_wave)) $file
	Wave dummy_new_wave = $file
	dummy_new_wave = dummy_old_wave
	KillWaves dummy_old_wave
	
	//Scale the wave and correct the offset
	Variable scaling = Scale[0]
	SetScale/P x 0,scaling,"", dummy_new_wave
	wavestats/Q/R=((goffset_begin),(goffset_end)) dummy_new_wave; dummy_new_wave -= V_avg;
	KillWaves Scale
	
	Variable wave_kill_start = 1200
		
end

function fft_gen(fullName)

	String fullName
	//Variable padding
	
	SVAR gzero_pad = root:Packages:ChrisTHzExtras:gzero_pad
	String padding = gzero_pad
	
	SVAR gwin_fun = root:Packages:ChrisTHzExtras:gwin_fun
	String win_fun = gwin_fun
	
	Wave w = $fullName
	
	//Do the correct window function if desired, or none
	if(cmpstr(padding,"None") == 0)
		if(cmpstr(win_fun,"None") == 0)
			FFT/OUT=1/DEST=$(fullName + "_FFT") w
		else
			FFT/OUT=1/WINF=$(win_fun)/DEST=$(fullName + "_FFT") w
		endif
	else
		if(cmpstr(win_fun,"None") == 0)
			FFT/OUT=1/PAD={str2num(padding)}/DEST=$(fullName + "_FFT") w
		else
			FFT/OUT=1/PAD={str2num(padding)}/WINF=$(win_fun)/DEST=$(fullName + "_FFT") w
		endif
	endif
		
end

function absorp(transmission_wave_name)

	String transmission_wave_name
	
	Wave trans_wave = $(transmission_wave_name)
	
	Make/O/N=(numpnts(trans_wave)) $("Abs_" + transmission_wave_name)
	
	Wave abs_wave = $("Abs_"+transmission_wave_name)
	
	SetScale/P x 0,(DimDelta(trans_wave,0)),"", abs_wave
	
	abs_wave = -ln(cabs(trans_wave))
	//abs_wave = 1-cabs(trans_wave)

end

function transfolder()
	
	//Get the name and path of either aperture or sample scan, with the correct root name
	String path
	GetFileFolderInfo/Q
	path = S_path
	
	//Make a string that just has the folder name
	variable folder_ending = strsearch(path,":",Inf,1)
	String folder = path[0,folder_ending]
	
	//Make a string that just has the base file name
	variable file_ending = strsearch(path,"_",Inf,1)
	String fname = path[folder_ending + 1,file_ending - 1]
	
	//Find all the temperatures and make sure they have a corresponding aperture/sample scan
	variable kelvin_location = strsearch(path,"K",Inf,1)
	String temperature_string = path[file_ending + 1, kelvin_location - 1]
	Print temperature_string
	
	variable padding = 512*2*2*2*2*2*2*2
	
	String ap_name_string, sa_name_string
	
	//Figure out if the user clicked a sample or aperture scan
	if (cmpstr(fname[0,1],"Ap") == 0)
		ap_name_string = fname+"_" + temperature_string + "K"
		sa_name_string = ap_name_string
		sa_name_string[0,1] = "Sa"
	elseif (cmpstr(fname[0,1],"Sa") == 0)
		sa_name_string = fname+"_" + temperature_string + "K"
		ap_name_string = sa_name_string
		ap_name_string[0,1] = "Ap"
	else
		Print "The selected file does not obey the correct syntax."
		Print "The file selected may be either aperture or sample at a specific temperature."
		Print "If aperture scan, it must start with 'Ap' and if sample it must start with 'Sa'"
		Print "The rest of the file name can include more information, but must end with the temperature"
		Print "in the format ApXXXXXX_Y.YYK, where XXXXXX is any additionaly inforamtion desired"
		Print "and Y.YY is any decimal number that represents the temperature.  It must end with K."
		Print "In order for the function to fully work, the aperture and sample file must have the same name"
		Print "with the only difference being Ap and Sa at the beginning of the file."
		Abort					// Optionally execute if all conditions are FALSE
	endif
	
	//---Load aperture then sample
	SingleWaveLoad(folder,ap_name_string)
	fft_gen(ap_name_string)
	
	SingleWaveLoad(folder,sa_name_string)
	fft_gen(sa_name_string)
	
	String ratio_holder =  ("T_" + ap_name_string[2,kelvin_location])
	Duplicate/O $(ap_name_string+"_FFT"), $ratio_holder
	
	Wave/C top = $(sa_name_string+"_FFT")
	Wave/C bottom = $(ap_name_string+"_FFT")
	Wave/C ratio = $ratio_holder
		
	ratio = top/bottom	
	
end

function ohpl_ffts_auto(baseName,num_waves)
	String baseName
	Variable num_waves
	
	//NVAR gzero_pad = root:Packages:ChrisTHzExtras:gzero_pad
	//Variable padding = gzero_pad;
	Variable i
	String dummy
	for(i=0;i<num_waves;i+=1)
	
		//Create wave name & wave
		dummy = baseName + "_" + num2istr(i+1)
		Wave w = $dummy
		
		//Do the FFT
		fft_gen(dummy)
		
		//Create the files to put the ratios in, for the 100% lines
		duplicate/o $(dummy+"_FFT"), $("R_"+baseName+"_"+num2istr(i+1)+num2istr(i+2))
	endfor
	
	//The loop accidentally overcompensates and since the last is 1/last, must rename it
	Wave old = $("R_"+baseName+"_"+num2istr(num_waves)+num2istr(num_waves+1))
	Make/O $("R_"+baseName+"_"+"1"+num2istr(num_waves));
	Wave new = $("R_"+baseName+"_"+"1"+num2istr(num_waves))
	Duplicate/O old, new; KillWaves old;
	
end

function ohpl_multi_ratios(baseName,num_waves)
	//This function takes the ratios of the FFTs of the scans
	//The ratio waves and FFT waves have already been created in the same folder using ffts_auto()
	String baseName
	Variable num_waves
	
	String dummy = baseName + "_";
	Variable i;
	
	for(i=0;i<num_waves;i+=1)
	
		//Create wave name & wave
		dummy = baseName + "_" + num2istr(i+1)
		
		//Create the files to put the ratios in, for the 100% lines
		duplicate/o $(dummy+"_FFT"), $("R_"+baseName+"_"+num2istr(i+1)+num2istr(i+2))
		
	endfor
	
	//The loop accidentally overcompensates and since the last is 1/last, must rename it
	Wave old = $("R_"+baseName+"_"+num2istr(num_waves)+num2istr(num_waves+1))
	Make/O $("R_"+baseName+"_"+"1"+num2istr(num_waves));
	Wave new = $("R_"+baseName+"_"+"1"+num2istr(num_waves))
	Duplicate/O old, new; KillWaves old;
	
	//---Create the ratios---//
	dummy = baseName + "_"
	for(i=0;i<num_waves-1;i+=1)
		Wave/C ratio = $("R_" + dummy + num2istr(i+1) + num2istr(i+2))
		Wave/C top = $(dummy + num2istr(i+1) + "_FFT")
		Wave/C bottom = $(dummy + num2istr(i+2) + "_FFT")
		ratio = top / bottom
		Print ("R_" + dummy + num2istr(i+1) + num2istr(i+2))
	endfor
	//Because of my habit of dividing the first and last by each other to get a long time 100% line
	//The last file will need to be done manually, because it takes the first and last number in its name
	Wave/C ratio = $("R_" + dummy + "1" + num2istr(num_waves))
	Wave/C top = $(dummy + "1" + "_FFT")
	Wave/C bottom = $(dummy + num2istr(num_waves) + "_FFT")
	ratio = top / bottom
	
end

function ohpl()
	Variable scaling
	
	//Get the name and path of one of the files in the series (shouldn't matter which)
	String path
	GetFileFolderInfo/Q
	path = S_path
	
	//Make a string that just has the folder name
	variable folder_ending = strsearch(path,":",Inf,1)
	String folder = path[0,folder_ending]
	
	//Make a string that just has the base file name
	variable file_ending = strsearch(path,"_",Inf,1)
	String fname = path[folder_ending + 1,file_ending - 1]
	
	//Figure out how many of these files there are
	string wave_name
	variable dummy_ref_num
	ControlInfo/W=ChrisTHzWindow FFT_checkbox  //This is the checkbox on the control panel
	variable num_files = 1
	do
		//-----Create the file name----//
		wave_name =  fname + "_" + num2istr(num_files)
		
		//----------Try to open it--------//
		open/z/r dummy_ref_num as (folder + wave_name)
		
		//-----If openable, open it and do the FFT if desired----//
		if(V_flag == 0)
			SingleWaveLoad(folder , wave_name)
			switch(V_value)
				case 0:  //This is the no case
					break
				case 1: //This is the yes case
					fft_gen(wave_name)
					break
			endswitch
		endif
		
		num_files += 1
		
	while(V_flag == 0) //V_flag == 0 if no error, non-zero if error
	num_files -= 2;
	
	if (num_files == 0)
		Print "Error, incorrect file syntax"						// execute if condition is TRUE
		Print "Must have file name (can include _ characters), followed by _x"
		Print "where x is the number of the file. Each sequential file should increase the index by 1"
		Abort
	endif
	
	//Perform the ratios
	ohpl_multi_ratios(fname,num_files)
	
	String dummy = fname + "_";
	//Find out if the window exists already, and if so kill it
	DoWindow/HIDE=? $(fname + "_Ratios")
	if (V_flag == 0)
		//Make the new window if it doesn't exist already
		Display/n=$(fname + "_Ratios")
		//ModifyGraph width=432,height=288
	else
		DoWindow/F $(fname + "_Ratios")
	endif
	//Append succesive traces to the graph
	Variable i;
	for(i=0;i<num_files-1;i+=1)
		Wave/C dummy_wave = $("R_" + dummy + num2istr(i+1) + num2istr(i+2))
		AppendToGraph dummy_wave						// Optionally execute if condition is FALSE
	endfor
	if(V_flag==0)
		//ModifyGraph width=432,height=288
		//ModifyGraph width=0,height=0
	endif
	//Because of my habit of dividing the first and last by each other to get a long time 100% line
	//The last file will need to be done manually, because it takes the first and last number in its name
	Wave/C dummy_wave = $("R_" + dummy + "1" + num2istr(num_files))
	AppendToGraph dummy_wave
	//Modify the graph to make it look good
	ModifyGraph cmplxMode=3
	SetAxis left 0.9,1.1
	SetAxis bottom 0.1,3.0
	ModifyGraph lsize=2
	ModifyGraph mirror=2,fStyle=1,fSize=14,axThick=1.5;
	ModifyGraph grid(left)=1,minor(left)=1
	Label left "\\f01\\Z18 Transmission";DelayUpdate
	Label bottom "\\f01\\Z18Frequency (THz)"
	//ModifyGraph width=432,height=288
	//ModifyGraph width=0,height=0
	
end

function load_single_trace()
	
	//Get the name and path of one of the files in the series (shouldn't matter which)
	GetFileFolderInfo/Q
	String path = S_path
	
	//Make two strings: the folder name with :, and the file name
	variable folder_ending = strsearch(path,":",Inf,1)
	variable file_ending = strlen(path)
	String folder = path[0,folder_ending]
	String fname = path[folder_ending + 1,file_ending - 1]
	
	SingleWaveLoad(folder,fname)
	
	if(strsearch(fname,".txt",0) > 0)
		fname = RemoveEnding(fname,".txt")
	endif
	
	//---------This will do FFTs based on the value of the checkbox in ChrisTHzWindow-------//
	ControlInfo/W=ChrisTHzWindow FFT_checkbox  //This is the checkbox on the control panel
	switch(V_value)
		case 0: //This is the no case
			break
		case 1:  //This is the yes case
			fft_gen(fname)
			break
	endswitch
	
end

function load_single_trace_file(path)
	
	//----This is the full path to the file, including the file name----//
	String path
	
	//Make two strings: the folder name with :, and the file name
	variable folder_ending = strsearch(path,":",Inf,1)
	variable file_ending = strlen(path)
	String folder = path[0,folder_ending]
	String fname = path[folder_ending + 1,file_ending - 1]
	
	SingleWaveLoad(folder,fname)
	
	if(strsearch(fname,".txt",0) > 0)
		fname = RemoveEnding(fname,".txt")
	endif
	
	//---------This will do FFTs based on the value of the checkbox in ChrisTHzWindow-------//
	ControlInfo/W=ChrisTHzWindow FFT_checkbox  //This is the checkbox on the control panel
	switch(V_value)
		case 0: //This is the no case
			break
		case 1:  //This is the yes case
			fft_gen(fname)
			break
	endswitch
	
end

function load_single_trace_file_rename(path,new_name)
	
	//----This is the full path to the file, including the file name----//
	String path, new_name
	
	//Make two strings: the folder name with :, and the file name
	variable folder_ending = strsearch(path,":",Inf,1)
	variable file_ending = strlen(path)
	String folder = path[0,folder_ending]
	String fname = path[folder_ending + 1,file_ending - 1]
	
	SingleWaveLoad(folder,fname)
	
	if(strsearch(fname,".txt",0) > 0)
		fname = RemoveEnding(fname,".txt")
	endif
	
	Duplicate/O $fname, $new_name; KillWaves $fname
	fname = new_name
	
	//---------This will do FFTs based on the value of the checkbox in ChrisTHzWindow-------//
	ControlInfo/W=ChrisTHzWindow FFT_checkbox  //This is the checkbox on the control panel
	switch(V_value)
		case 0: //This is the no case
			break
		case 1:  //This is the yes case
			fft_gen(fname)
			break
	endswitch
	
end


function load_single_trace_y()
	
	//Get the name and path of one of the files in the series (shouldn't matter which)
	GetFileFolderInfo/Q
	String path = S_path
	
	//Make two strings: the folder name with :, and the file name
	variable folder_ending = strsearch(path,":",Inf,1)
	variable file_ending = strlen(path)
	String folder = path[0,folder_ending]
	String fname = path[folder_ending + 1,file_ending - 1]
	
	SingleWaveLoad(folder,fname)
	SingleWaveLoadY(folder,fname)
	
	if(strsearch(fname,".txt",0) > 0)
		fname = RemoveEnding(fname,".txt")
	endif
	
	//---------This will do FFTs based on the value of the checkbox in ChrisTHzWindow-------//
	ControlInfo/W=ChrisTHzWindow FFT_checkbox  //This is the checkbox on the control panel
	switch(V_value)
		case 0: //This is the no case
			break
		case 1:  //This is the yes case
			fft_gen(fname)
			break
	endswitch
	
end

function load_multiple_traces()

	//-----Get the name and path of one of the files in the series (shouldn't matter which)-----//
	String path
	GetFileFolderInfo/Q
	path = S_path
	
	//-----Make a string that just has the folder name-----//
	variable folder_ending = strsearch(path,":",Inf,1)
	String folder = path[0,folder_ending]
	
	//-----Make a string that just has the base file name-----//
	variable file_ending = strsearch(path,"_",Inf,1)
	String fname = path[folder_ending + 1,file_ending - 1]
	
	//------Figure out if file exists, open if it does, possibly do FFT-----//
	string wave_name
	variable dummy_ref_num
	ControlInfo/W=ChrisTHzWindow FFT_checkbox  //This is the checkbox on the control panel
	variable index = 1
	do
		//Create the file name, to see if it exists.  once it gets to a _x that doesn't exist, it will stop the loop
		//name_dummy =  folder + fname + "_" + num2istr(index)
		wave_name =  fname + "_" + num2istr(index)
		
		//----------This actually tries to open it--------//
		//open/z/r dummy_ref_num as name_dummy
		open/z/r dummy_ref_num as (folder + wave_name)
		
		//-----If openable, open it and do the FFT if desired----//
		if(V_flag == 0)
			SingleWaveLoad(folder , wave_name)
			switch(V_value)
				case 0:  //This is the no case
					break
				case 1: //This is the yes case
					fft_gen(wave_name)
					break
			endswitch
		endif
		
		index += 1
		
	while(V_flag == 0) //V_flag == 0 if no error, non-zero if error
	index -= 2;
	
	if (index == 0)
		Print "Error, incorrect file syntax"						// execute if condition is TRUE
		Print "Must have file name (can include _ characters), followed by _x"
		Print "where x is the number of the file. Each sequential file should increase the index by 1"
		Abort
	endif
	
end

function load_multiple_traces_selections()
	
	Variable ref_num
	String message = "Select one or more time traces from the THz Pointcounter"
	String fileFilters = "All Files:.*;"
	
	//-----Open a file dialog and get all the selections in a carraige return spaced list----//
	Open/D/R/MULT=1/F=fileFilters/M=message ref_num
	String filePaths = S_filename
	
	if (strlen(filePaths) == 0)
		Print "Cancelled"
	else
		Variable numFilesSelected = ItemsInList(filePaths, "\r")
		Variable i
		for(i=0; i<numFilesSelected; i+=1)
			String path = StringFromList(i, filePaths, "\r")
			load_single_trace_file(path)	
		endfor
	endif
	
	//-----Store in case we want to redo this load later with different parameters-----//
	SVAR gmult_file_string = root:Packages:ChrisTHzExtras:gmult_file_string
	gmult_file_string = filePaths
	
end

function reload_multiple_traces_select()
		
	//-----Open a file dialog and get all the selections in a carraige return spaced list----//
	SVAR gmult_file_string = root:Packages:ChrisTHzExtras:gmult_file_string
	String filePaths = gmult_file_string
	
	if (strlen(filePaths) == 0)
		Print "No previous files selected"
	else
		Variable numFilesSelected = ItemsInList(filePaths, "\r")
		Variable i
		for(i=0; i<numFilesSelected; i+=1)
			String path = StringFromList(i, filePaths, "\r")
			load_single_trace_file(path)	
		endfor
	endif
	
end

//function mag_fk_load(f_start,f_end,k_start,k_end)
//	Variable f_start,f_end,k_start,k_end
//	Variable num_files
//	Variable scaling
//	
//	//Get the name and path of one of the files in the series (shouldn't matter which)
//	String path
//	GetFileFolderInfo/Q
//	path = S_path
//	
//	//Make a string that just has the folder name
//	variable folder_ending = strsearch(path,":",Inf,1)
//	String folder = path[0,folder_ending]
//	
//	//Make a string that just has the base file name
//	variable file_ending = strlen(path)
//	String fname = path[folder_ending + 1,file_ending - 1]
//	
//	//
//	string fname_notxt
//	if(strsearch(fname,".txt",0) > 0)
//		fname_notxt = RemoveEnding(fname,".txt")
//	else
//		fname_notxt = fname
//	endif
//	
//	variable padding //= 512*2*2*2*2*2*2*2
//	
//	scaling = ScalingGrabber(folder+fname)
//	SingleWaveLoad(folder,fname)
//		
//	string far_name = fname_notxt + "_F"
//	string ker_name = fname_notxt + "_K"
//	
//	//Duplicate/O/R=(f_start,f_end) $fname_notxt, $far_name
//	//Duplicate/O/R=(k_start,k_end) $fname_notxt, $ker_name
//	Duplicate/O $fname_notxt, $far_name
//	Duplicate/O $fname_notxt, $ker_name
//	
//	//figure out which data folder currently in, so we can set the data folder as that at the end
//	String dfSave = GetDataFolder(1)
//	
//	NewDataFolder/O Original_Time_Trace
//	NewDataFolder/O Original_FFT
//	NewDataFolder/O Faraday_Time_Trace
//	NewDataFolder/O Faraday_FFT
//	NewDataFolder/O Kerr_Time_Trace
//	NewDataFolder/O Kerr_FFT
//	
//	DoAlert 1, "Do you want to perform the FFTs as well?"
//	switch(V_flag)
//		case 1: //This is the yes case
//			fft_gen(fname_notxt)
//			
//			//Duplicate once the scaling has occurred in fname_notxt, happens in fft_gen
//			Duplicate/O/R=(f_start,f_end) $fname_notxt, $far_name
//			Duplicate/O/R=(k_start,k_end) $fname_notxt, $ker_name
//			
//			fft_gen(far_name)
//			fft_gen(ker_name)
//			
//			MoveWave $fname_notxt, :Original_Time_Trace:
//			MoveWave $(fname_notxt+"_FFT"), :Original_FFT:
//			MoveWave $far_name, :Faraday_Time_Trace:
//			MoveWave $(far_name+"_FFT"), :Faraday_FFT:
//			MoveWave $ker_name, :Kerr_Time_Trace:
//			MoveWave $(ker_name + "_FFT"), :Kerr_FFT:
//		case 2:  //This is the no case
//			scale_noFFT(fname_notxt,scaling)
//			
//			Duplicate/O/R=(f_start,f_end) $fname_notxt, $far_name
//			Duplicate/O/R=(k_start,k_end) $fname_notxt, $ker_name
//			
//			scale_noFFT(far_name,scaling)
//			scale_noFFT(ker_name,scaling)
//			
//			MoveWave $fname_notxt, :Original_Time_Trace:
//			MoveWave $far_name, :Faraday_Time_Trace:			
//			MoveWave $ker_name, :Kerr_Time_Trace:
//	endswitch	
//	
//end

function file_finder()
	String folder = "C:Proc_Test:02-21:"
	
	NewPath/O/Q practice_path folder
	
	String all_files = IndexedFile(practice_path,-1,"????")
	
	String file_holder
	Variable begin_index = 0, more_files = 0
	
	Make/O/T/N=0 file_names
	//file_names[0] = "test holder string bitches"
	//Print file_names[0]
	Variable num_files = 0
	do
	
		more_files = strsearch(all_files,";",more_files+1)  //Find next ; means new file
		
		if(more_files != -1)
		
			//----Record that we have one more file and store its name----//
			num_files += 1
			file_holder = all_files[begin_index,more_files-1]
			
			//----Add this file name to our wave of file names-----//
			Redimension/N=(num_files) file_names 
			file_names[num_files - 1] = file_holder
			
			//----Reset begin_index as just past the last ; we were at----//
			begin_index = more_files + 1
			
		endif
		
	while (more_files != -1)				// as long as expression is TRUE
	
end

function file_sorter()//file_names,file_type)//,Ap_name,Sa_name)
	Wave/T file_names
	String file_type, Ap_name,Sa_name
	
	Variable num_files = numpnts(file_names)
	
	if(cmpstr(file_type,"temperature") == 0)
		
	endif
	
end

function file_finder_magnet()
	String folder = "C:Proc_Test:02-21:"
	
	NewPath/O/Q practice_path folder
	
	String all_files = IndexedFile(practice_path,-1,"????")
	
	String file_holder
	Variable begin_index = 0, more_files = 0, field_holder = 0
	Variable field_begin;
	String field;
	Make/O/T/N=0 file_names
	//file_names[0] = "test holder string bitches"
	//Print file_names[0]
	Variable num_files = 0
	do
		more_files = strsearch(all_files,";",more_files+1)  //Find next ; means new file
		if(more_files != -1)
			file_holder = all_files[begin_index,more_files-1] //store the file name, without the ; (this is why we have -1)
			field_holder = strsearch(file_holder,"_kG",0) //See if this is a magnetic field scan file
			if(field_holder != -1) // if it is, let's find out the field so we can get the rotations
				field_begin = strsearch(file_holder,"_",field_holder-1,1)
				field = file_holder[field_begin+1,field_holder-1]
				num_files += 1
				Redimension/N=(num_files) file_names
				file_names[num_files - 1] = file_holder
				//mag_fk_rotations(folder,"HgTe","HgTeC",field,f_start,f_end,k_start,k_end,1)
			endif
			begin_index = more_files + 1
		endif
	while (more_files != -1)				// as long as expression is TRUE
	Print all_files
	
end

//function mag_fk_load_file(path,f_start,f_end,k_start,k_end,do_ffts)
//	String path
//	Variable f_start,f_end,k_start,k_end,do_ffts
//	Variable num_files
//	Variable scaling
//	
//	//Make a string that just has the folder name
//	variable folder_ending = strsearch(path,":",Inf,1)
//	String folder = path[0,folder_ending]
//	
//	//Make a string that just has the base file name
//	variable file_ending = strlen(path)
//	String fname = path[folder_ending + 1,file_ending - 1]
//	
//	//
//	string fname_notxt
//	if(strsearch(fname,".txt",0) > 0)
//		fname_notxt = RemoveEnding(fname,".txt")
//	else
//		fname_notxt = fname
//	endif
//	
//	variable padding //= 512*2*2*2*2*2*2*2
//	
//	scaling = ScalingGrabber(folder+fname)
//	SingleWaveLoad(folder,fname)
//		
//	string far_name = fname_notxt + "_F"
//	string ker_name = fname_notxt + "_K"
//	
//	//Duplicate/O/R=(f_start,f_end) $fname_notxt, $far_name
//	//Duplicate/O/R=(k_start,k_end) $fname_notxt, $ker_name
//	Duplicate/O $fname_notxt, $far_name
//	Duplicate/O $fname_notxt, $ker_name
//	
//	//figure out which data folder currently in, so we can set the data folder as that at the end
//	String dfSave = GetDataFolder(1)
//	
//	NewDataFolder/O Pulses
//	NewDataFolder/O FFTs
//	NewDataFolder/O Faraday_Pulses
//	NewDataFolder/O Faraday_FFTs
//	NewDataFolder/O Kerr_Pulses
//	NewDataFolder/O Kerr_FFTs
//	
//	if(do_ffts != 0)
//		fft_gen(fname_notxt)
//		
//		//Duplicate once the scaling has occurred in fname_notxt, happens in fft_gen
//		Duplicate/O/R=(f_start,f_end) $fname_notxt, $far_name
//		Duplicate/O/R=(k_start,k_end) $fname_notxt, $ker_name
//		
//		fft_gen(far_name)
//		fft_gen(ker_name)
//		
//		MoveWave $fname_notxt, :Pulses:
//		MoveWave $(fname_notxt+"_FFT"), :FFTs:
//		MoveWave $far_name, :Faraday_Pulses:
//		MoveWave $(far_name+"_FFT"), :Faraday_FFTs:
//		MoveWave $ker_name, :Kerr_Pulses:
//		MoveWave $(ker_name + "_FFT"), :Kerr_FFTs:
//	else
//		scale_noFFT(fname_notxt,scaling)
//		
//		Duplicate/O/R=(f_start,f_end) $fname_notxt, $far_name
//		Duplicate/O/R=(k_start,k_end) $fname_notxt, $ker_name
//		
//		scale_noFFT(far_name,scaling)
//		scale_noFFT(ker_name,scaling)
//		
//		MoveWave $fname_notxt, :Pulses:
//		MoveWave $far_name, :Faraday_Pulses:			
//		MoveWave $ker_name, :Kerr_Pulses:
//	endif	
//	
//end
//
//function mag_fk_rotations(folder,parallel,crossed,field,f_start,f_end,k_start,k_end,do_original_FFT)
//	String folder, parallel, crossed, field
//	Variable f_start,f_end,k_start,k_end, do_original_FFT
//	
//	Variable scaling
//	Variable padding
//	
//	String dfSave = GetDataFolder(1)
//	
//	
//	
//	
//	//Create the parallel data folders
//	String parallel_data_folder = parallel
//	
//	NewDataFolder/O/S $(parallel_data_folder)
//	NewDataFolder/O Pulses
//	NewDataFolder/O FFTs
//	NewDataFolder/O Faraday_Pulses
//	NewDataFolder/O Faraday_FFTs
//	NewDataFolder/O Kerr_Pulses
//	NewDataFolder/O Kerr_FFTs
//	
//	NewDataFolder/O Rotations_Faraday
//	NewDataFolder/O Rotations_Kerr
//	
//	//Go back to the original folder
//	SetDataFolder dfSave
//	
//	//Create the crossed data folders
//	String crossed_data_folder = crossed
//	
//	NewDataFolder/O/S $(crossed_data_folder)
//	NewDataFolder/O Pulses
//	NewDataFolder/O FFTs
//	NewDataFolder/O Faraday_Pulses
//	NewDataFolder/O Faraday_FFTs
//	NewDataFolder/O Kerr_Pulses
//	NewDataFolder/O Kerr_FFTs
//	
//	//Go back to the original folder
//	SetDataFolder dfSave
//	
//	//Load the parallel and crossed waves
//	String dummy_string = parallel + "_" + field + "_kG.txt"
//	scaling = ScalingGrabber(folder + dummy_string)
//	SingleWaveLoad(folder,dummy_string)
//	parallel = RemoveEnding(dummy_string,".txt")
//	
//	dummy_string = crossed + "_" + field + "_kG.txt"
//	scaling = ScalingGrabber(folder + dummy_string)
//	SingleWaveLoad(folder,dummy_string)
//	crossed = RemoveEnding(dummy_string,".txt")
//	
//	//Create names for the Faraday and Kerr waves
//	string parallel_far = parallel + "_F"
//	string parallel_ker = parallel + "_K"
//	string crossed_far = crossed + "_F"
//	string crossed_ker = crossed + "_K"
//	
//	if(do_original_FFT == 1)
//		fft_gen(parallel)
//		fft_gen(crossed)
//	endif
//	
//	//Duplicate once the scaling has occurred in fname_notxt, happens in fft_gen
//	Duplicate/O/R=(f_start,f_end) $parallel, $parallel_far
//	Duplicate/O/R=(k_start,k_end) $parallel, $parallel_ker
//	Duplicate/O/R=(f_start,f_end) $crossed, $crossed_far
//	Duplicate/O/R=(k_start,k_end) $crossed, $crossed_ker
//	
//	fft_gen(parallel_far)
//	fft_gen(parallel_ker)
//	fft_gen(crossed_far)
//	fft_gen(crossed_ker)
//	
//	Duplicate/O $(parallel_far + "_FFT"), $("Rot_" + field + "_kG_F")
//	Wave/C top = $(crossed_far + "_FFT")
//	Wave/C bottom = $(parallel_far + "_FFT")
//	Wave/C rotation = $("Rot_" + field + "_kG_F")
//	rotation = atan(top/bottom)
//	
//	Duplicate/O $(parallel_ker + "_FFT"), $("Rot_" + field + "_kG_K")
//	Wave/C top = $(crossed_ker + "_FFT")
//	Wave/C bottom = $(parallel_ker + "_FFT")
//	Wave/C rotation = $("Rot_" + field + "_kG_K")
//	rotation = atan(top/bottom)
//	
//	//Duplicate waves into folders, allowing overwriting if already exist
//	Duplicate/O $(parallel), :$(parallel_data_folder):Pulses:$(parallel); KillWaves $(parallel);
//	Duplicate/O $(parallel + "_FFT"), :$(parallel_data_folder):FFTs:$(parallel + "_FFT"); KillWaves  $(parallel + "_FFT")
//	Duplicate/O $(parallel + "_F"), :$(parallel_data_folder):Faraday_Pulses:$(parallel + "_F"); KillWaves $(parallel + "_F")
//	Duplicate/O $(parallel + "_K"), :$(parallel_data_folder):Kerr_Pulses:$(parallel + "_K"); KillWaves $(parallel + "_K")
//	Duplicate/O $(parallel + "_F" + "_FFT"), :$(parallel_data_folder):Faraday_FFTs:$(parallel + "_F" + "_FFT"); KillWaves $(parallel + "_F" + "_FFT")
//	Duplicate/O $(parallel + "_K" + "_FFT"), :$(parallel_data_folder):Kerr_FFTs:$(parallel + "_K" + "_FFT"); KillWaves $(parallel + "_K" + "_FFT")
//	Duplicate/O $("Rot_" + field + "_kG_F"), :$(parallel_data_folder):Rotations_Faraday:$("Rot_" + field + "_kG_F"); KillWaves $("Rot_" + field + "_kG_F")
//	Duplicate/O $("Rot_" + field + "_kG_K"), :$(parallel_data_folder):Rotations_Kerr:$("Rot_" + field + "_kG_K"); KillWaves $("Rot_" + field + "_kG_K")
//
//	Duplicate/O $(crossed), :$(crossed_data_folder):Pulses:$(crossed); KillWaves $(crossed);
//	Duplicate/O $(crossed + "_FFT"), :$(crossed_data_folder):FFTs:$(crossed + "_FFT"); KillWaves  $(crossed + "_FFT")
//	Duplicate/O $(crossed + "_F"), :$(crossed_data_folder):Faraday_Pulses:$(crossed + "_F"); KillWaves $(crossed + "_F")
//	Duplicate/O $(crossed + "_K"), :$(crossed_data_folder):Kerr_Pulses:$(crossed + "_K"); KillWaves $(crossed + "_K")
//	Duplicate/O $(crossed + "_F" + "_FFT"), :$(crossed_data_folder):Faraday_FFTs:$(crossed + "_F" + "_FFT"); KillWaves $(crossed + "_F" + "_FFT")
//	Duplicate/O $(crossed + "_K" + "_FFT"), :$(crossed_data_folder):Kerr_FFTs:$(crossed + "_K" + "_FFT"); KillWaves $(crossed + "_K" + "_FFT")
//
//end

//function runner()
//	variable f_start = 0;
//	variable f_end = 22;
//	variable k_start = 22;
//	variable k_end = 34;
//	
//	//Move to a new data folder to store all HgTe data
//	NewDataFolder/O/S root:HgTe
//	
//	//mag_fk_load_file("C:Proc_Test:Faraday_Kerr_Tests:HgTe_0.000_kG.txt",f_start,f_end,k_start,k_end,1)
//	
//	//Move to a new data folder to store all HgTeC data
//	NewDataFolder/O/S root:HgTeC
//	
//	//mag_fk_load_file("C:Proc_Test:Faraday_Kerr_Tests:HgTe_0.000_kG.txt",f_start,f_end,k_start,k_end,1)
//	
//end
//
//function runner2()
//	variable f_start = 0;
//	variable f_end = 22;
//	variable k_start = 22;
//	variable k_end = 34;
//	
//	//mag_fk_rotations("C:Proc_Test:Faraday_Kerr_Tests:","HgTe","HgTeC","0.000",f_start,f_end,k_start,k_end,1)
//	//mag_fk_rotations("C:Proc_Test:Faraday_Kerr_Tests:","HgTe","HgTeC","0.500",f_start,f_end,k_start,k_end,1)
//	//mag_fk_rotations("C:Proc_Test:Faraday_Kerr_Tests:","HgTe","HgTeC","1.000",f_start,f_end,k_start,k_end,1)
//
//	//mag_fk_rotations("C:Proc_Test:Faraday_Kerr_Tests:","HgTe","HgTeC","-10.000",f_start,f_end,k_start,k_end,1)
//
//	rot_angle_subtract("0.000","0.500","HgTe")
//	rot_angle_subtract("0.000","1.000","HgTe")
//	rot_angle_subtract("0.000","-10.000","HgTe")
//	rot_angle_subtract("0.000","0.000","HgTe")
//	
//end
//
//function filep()
//	String folder = "C:Proc_Test:Faraday_Kerr_Tests:"
//	
//	variable f_start = 0;
//	variable f_end = 22;
//	variable k_start = 22;
//	variable k_end = 34;
//	
//	NewPath/O/Q practice_path folder
//	
//	String test_string = IndexedFile(practice_path,-1,"????")
//	
//	String file_holder
//	Variable scaling
//	Variable begin_index = 0, more_files = 0, field_holder = 0
//	Variable field_begin;
//	String field;
//	do
//		more_files = strsearch(test_string,";",more_files+1)  //Find next ; means new file
//		if(more_files != -1)
//			file_holder = test_string[begin_index,more_files-1] //store the file name, without the ; (this is why we have -1)
//			field_holder = strsearch(file_holder,"_kG",0) //See if this is a magnetic field scan file
//			if(field_holder != -1) // if it is, let's find out the field so we can get the rotations
//				field_begin = strsearch(file_holder,"_",field_holder-1,1)
//				field = file_holder[field_begin+1,field_holder-1]
//				//mag_fk_rotations(folder,"HgTe","HgTeC",field,f_start,f_end,k_start,k_end,1)
//			endif
//			begin_index = more_files + 1
//		endif
//	while (more_files != -1)				// as long as expression is TRUE
//	//Print test_string
//	
//end
//
//function filep2(f_start,f_end,k_start,k_end,base_name,base_name_crossed)
////function filep2(base_name,base_name_crossed)
//
//	//Variable f_start,f_end,k_start,k_end
//	String base_name, base_name_crossed
//	Variable f_start// = 2
//	Variable f_end// = 20
//	Variable k_start// = 24
//	Variable k_end// = 34
//	//String base_name = "HgTe"
//	//String base_name_crossed = "HgTeC"
//
//	//String path
//	//GetFileFolderInfo/Q
//	//path = S_path
//	
//	//This means that the file structure will start in the top folder, root
//	//You want this, because the magnetic field loading function already takes care of creating all subfolders
//	SetDataFolder root:
//	
//	String path = ("C:Proc_Test:02-28:"+base_name+"_0.000_kG.txt")
//	
//	//Make a string that just has the folder name
//	variable folder_ending = strsearch(path,":",Inf,1)
//	String folder = path[0,folder_ending]
//	
//	//Make a string that just has the reference file name
//	variable file_ending = strlen(path)
//	String ref_fname = path[folder_ending + 1,file_ending - 1]
//	
//	Variable ref_field_end = strsearch(ref_fname,"_kG",0)
//	Variable ref_field_begin = strsearch(ref_fname,"_",ref_field_end-1,1)
//	String ref_field = ref_fname[ref_field_begin+1,ref_field_end-1]
//	Print "Reference field = " + ref_field + " kG for " + base_name
//	//mag_fk_rotations(folder,base_name,base_name_crossed,ref_field,f_start,f_end,k_start,k_end,1)
//	
//	NewPath/O/Q practice_path folder
//	
//	String test_string = IndexedFile(practice_path,-1,"????")
//	
//	//This loop structure figures out how many fields there are, looking at all the files in the folder
//	//figuring out which ones have the right name, then creating a text wave with them all
//	String file_holder
//	Variable scaling
//	Variable begin_index = 0, more_files = 0, field_holder = 0
//	Variable field_begin;
//	String field;
//	Variable num_fields = 0;
//	Make/T/O/N=0  $(base_name + "_field_values")
//	Wave/T text_field_values = $(base_name + "_field_values")
//	do
//		more_files = strsearch(test_string,";",more_files+1)  //Find next ; means new file
//		if(more_files != -1)
//			file_holder = test_string[begin_index,more_files-1] //store the file name, without the ; (this is why we have -1)
//			field_holder = strsearch(file_holder,"_kG",0) //See if this is a magnetic field scan file
//			if(field_holder != -1) // if it is, let's find out the field so we can get the rotations
//				field_begin = strsearch(file_holder,"_",field_holder-1,1)
//				field = file_holder[field_begin+1,field_holder-1]
//				if(cmpstr(file_holder[0,field_begin-1],base_name) == 0)
//						Redimension/N=(num_fields+1) text_field_values
//						text_field_values[num_fields] = field
//						num_fields += 1;
//						//Print file_holder
//				endif
//			endif
//			begin_index = more_files + 1
//		endif
//	while (more_files != -1)				// as long as expression is TRUE
//	Print "There are "+num2str(num_fields)+" field values for "+base_name
//	Sort/A text_field_values, text_field_values
//	
//	begin_index = 0; more_files = 0; field_holder = 0;
//	
//	Variable i;
//	for(i=0;i<num_fields;i+=1)
//		field = text_field_values[i]
//		//mag_fk_rotations(folder,base_name,base_name_crossed,field,f_start,f_end,k_start,k_end,1)
//	endfor
//	
//	String dfSave = GetDataFolder(1)
//	NewDataFolder/O/S $(base_name)
//	NewDataFolder/O/S Rotations_Faraday
//	
//	Variable sizer = numpnts($("Rot_"+ref_field+"_kG_F"))
//	
//	Make/O/N=(sizer,num_fields) rotation_matrix
//	
//	SetDataFolder dfSave
//	
//	for(i=0;i<num_fields;i+=1)
//		field = text_field_values[i]
//		if(cmpstr(field,ref_field) != 0)
//			rot_angle_subtract(ref_field,field,base_name)
//		endif
//	endfor
//	
//	rot_angle_subtract(ref_field,ref_field,base_name)
//	
//	dfSave = GetDataFolder(1)
//	NewDataFolder/O/S $(base_name)
//	NewDataFolder/O/S Rotations_Faraday
//	
//	Variable j
//	Make/O/N=(num_fields) number_fields
//	Wave number_fields
//	for(i=0;i<num_fields;i+=1)
//		for(j=0;j<sizer;j+=1)
//			field = text_field_values[i]
//			number_fields[i] = str2num(text_field_values[i])
//			Wave rot_dummy =  $("Rot_"+field+"_kG_F")
//			rotation_matrix[j][i] = real(rot_dummy[j])
//		endfor
//	endfor
//	
//	NewDataFolder/O BDep
//	Variable freq = DimDelta($("Rot_" + ref_field + "_kG_F"),0)
//	Print freq
//	Variable freq_low_limit = 0.2;
//	Variable freq_high_limit = 2.0;
//	String current_freq;
//	variable iter_skip = 4;
//	variable k;
//	variable avg_dummy = 0;
//	for(i=0;i<sizer;i+=4)
//		current_freq = num2str(freq*i)
//		if(freq*i >= freq_low_limit && freq*i <= freq_high_limit)
//			Make/O/N=(num_fields) $("BDep_"+current_freq+"_THz_F")
//			Wave dummy_bdep = $("BDep_"+current_freq+"_THz_F")
//			for(j=0;j<num_fields;j+=1)
//				for(k=0;k<iter_skip;k+=1)
//					avg_dummy += rotation_matrix[i][j+k]
//				endfor
//				avg_dummy /= iter_skip;
//				dummy_bdep[j] = avg_dummy
//				//dummy_bdep[j] = rotation_matrix[i][j]
//				avg_dummy = 0;
//			endfor
//			Smooth 8, dummy_bdep
//			Duplicate/O dummy_bdep, :BDep:$("BDep_"+num2str(freq*i)+"_THz_F")
//			Killwaves dummy_bdep
//		endif
//	endfor
//	Duplicate/O number_fields, :BDep:number_fields
//	KillWaves number_fields
//	
//	//MatrixTranspose rotation_matrix
//	
//	SetDataFolder dfSave
//	
//end

function magnet_folder_loadall()
	//Variable f_start,f_end,k_start,k_end
	//String base_name = "Sa1_4K_L"
	//String base_name = "HgTe"
	//String base_name_crossed = "HgTeC"

	GetFileFolderInfo/Q
	String path = S_path
	
	//This means that the file structure will start in the top folder, root
	//You want this, because the magnetic field loading function already takes care of creating all subfolders
	//SetDataFolder root:
	
	//String path = ("C:Proc_Test:02-28:"+base_name+"_0.000_kG.txt")
	
	//Make a string that just has the folder name
	variable folder_ending = strsearch(path,":",Inf,1)
	String folder = path[0,folder_ending]
	
	//Make a string that just has the reference file name
	variable file_ending = strlen(path)
	variable kG_position =strsearch(path,"_kG",Inf,1)
	if (kG_position == -1)
		Print "Selected file name not properly formatted"
		Abort
	endif
	variable field_position = strsearch(path,"_",kG_position-1,1)
	String base_name = path[folder_ending + 1,field_position - 1]
	Print base_name
	
	//Variable ref_field_end = strsearch(ref_fname,"_kG",0)
	//Variable ref_field_begin = strsearch(ref_fname,"_",ref_field_end-1,1)
	//String ref_field = ref_fname[ref_field_begin+1,ref_field_end-1]
	//Print "Reference field = " + ref_field + " kG for " + base_name
	//mag_fk_rotations(folder,base_name,base_name_crossed,ref_field,f_start,f_end,k_start,k_end,1)
	
	NewPath/O/Q practice_path folder
	
	String test_string = IndexedFile(practice_path,-1,"????")
	Print test_string
	
	//This loop structure figures out how many fields there are, looking at all the files in the folder
	//figuring out which ones have the right name, then creating a text wave with them all
	String file_holder
	Variable scaling
	Variable begin_index = 0, semicolon_pos = 0, field_holder = 0
	Variable field_begin;
	String field;
	Variable num_fields = 0;
	Make/T/O/N=0  $(base_name + "_field_values")
	Wave/T text_field_values = $(base_name + "_field_values")
	do
		semicolon_pos = strsearch(test_string,";",semicolon_pos+1)  //Find next ; means new file
		if(semicolon_pos != -1)
			file_holder = test_string[begin_index,semicolon_pos-1] //store the file name, without the ; (this is why we have -1)
			field_holder = strsearch(file_holder,"_kG",0) //See if this is a magnetic field scan file
			if(field_holder != -1) // if it is, let's find out the field so we can get the rotations
				field_begin = strsearch(file_holder,"_",field_holder-1,1)
				field = file_holder[field_begin+1,field_holder-1]
				Print field
				if(cmpstr(file_holder[0,field_begin-1],base_name) == 0)
						Redimension/N=(num_fields+1) text_field_values
						text_field_values[num_fields] = field
						num_fields += 1;
						Print file_holder
				endif
			endif
			begin_index = semicolon_pos + 1
		endif
	while (semicolon_pos != -1)				// as long as expression is TRUE
	Print "There are "+num2str(num_fields)+" field values for "+base_name
	Sort/A text_field_values, text_field_values
	
	//begin_index = 0; more_files = 0; field_holder = 0;
	
	Variable i;
	for(i=0;i<num_fields;i+=1)
		file_holder = base_name + "_" + text_field_values[i] + "_kG"
		SingleWaveLoadMagnetAutoScans(folder,(file_holder + ".txt"))
		//mag_fk_rotations(folder,base_name,base_name_crossed,field,f_start,f_end,k_start,k_end,1)
	endfor
	
	//---------This will do FFTs based on the value of the checkbox in ChrisTHzWindow-------//
	ControlInfo/W=ChrisTHzWindow FFT_checkbox  //This is the checkbox on the control panel
	switch(V_value)
		case 0: //This is the no case
			break
		case 1:  //This is the yes case
			for(i=0;i<num_fields;i+=1)
				file_holder = base_name + "_" + text_field_values[i] + "_kG"
				fft_gen(file_holder)
			endfor
			break
	endswitch
	
//	String ref_file_holder = base_name + "_" + text_field_values[0] + "_kG"
//	Wave/C bottom = $(ref_file_holder + "_FFT")
//	for(i=1;i<num_fields;i+=1)
//		file_holder = base_name + "_" + text_field_values[i] + "_kG"
//		Wave/C top = $(file_holder + "_FFT")
//		top = top/bottom
//		//mag_fk_rotations(folder,base_name,base_name_crossed,field,f_start,f_end,k_start,k_end,1)
//	endfor
	
	
//	String dfSave = GetDataFolder(1)
//	NewDataFolder/O/S $(base_name)
//	NewDataFolder/O/S Rotations_Faraday
//	
//	Variable sizer = numpnts($("Rot_"+ref_field+"_kG_F"))
//	
//	Make/O/N=(sizer,num_fields) rotation_matrix
//	
//	SetDataFolder dfSave
//	
//	for(i=0;i<num_fields;i+=1)
//		field = text_field_values[i]
//		if(cmpstr(field,ref_field) != 0)
//			rot_angle_subtract(ref_field,field,base_name)
//		endif
//	endfor
//	
//	rot_angle_subtract(ref_field,ref_field,base_name)
//	
//	dfSave = GetDataFolder(1)
//	NewDataFolder/O/S $(base_name)
//	NewDataFolder/O/S Rotations_Faraday
//	
//	Variable j
//	Make/O/N=(num_fields) number_fields
//	Wave number_fields
//	for(i=0;i<num_fields;i+=1)
//		for(j=0;j<sizer;j+=1)
//			field = text_field_values[i]
//			number_fields[i] = str2num(text_field_values[i])
//			Wave rot_dummy =  $("Rot_"+field+"_kG_F")
//			rotation_matrix[j][i] = real(rot_dummy[j])
//		endfor
//	endfor
//	
//	NewDataFolder/O BDep
//	Variable freq = DimDelta($("Rot_" + ref_field + "_kG_F"),0)
//	Print freq
//	Variable freq_low_limit = 0.2;
//	Variable freq_high_limit = 2.0;
//	String current_freq;
//	variable iter_skip = 4;
//	variable k;
//	variable avg_dummy = 0;
//	for(i=0;i<sizer;i+=4)
//		current_freq = num2str(freq*i)
//		if(freq*i >= freq_low_limit && freq*i <= freq_high_limit)
//			Make/O/N=(num_fields) $("BDep_"+current_freq+"_THz_F")
//			Wave dummy_bdep = $("BDep_"+current_freq+"_THz_F")
//			for(j=0;j<num_fields;j+=1)
//				for(k=0;k<iter_skip;k+=1)
//					avg_dummy += rotation_matrix[i][j+k]
//				endfor
//				avg_dummy /= iter_skip;
//				dummy_bdep[j] = avg_dummy
//				//dummy_bdep[j] = rotation_matrix[i][j]
//				avg_dummy = 0;
//			endfor
//			Smooth 8, dummy_bdep
//			Duplicate/O dummy_bdep, :BDep:$("BDep_"+num2str(freq*i)+"_THz_F")
//			Killwaves dummy_bdep
//		endif
//	endfor
//	Duplicate/O number_fields, :BDep:number_fields
//	KillWaves number_fields
//	
//	//MatrixTranspose rotation_matrix
//	
//	SetDataFolder dfSave
	
end

function magnet_folder_load_manual(path)
	String path
	//Variable f_start,f_end,k_start,k_end
	//String base_name = "Sa1_4K_L"
	//String base_name = "HgTe"
	//String base_name_crossed = "HgTeC"

	//GetFileFolderInfo/Q
	//String path = S_path
	
	//This means that the file structure will start in the top folder, root
	//You want this, because the magnetic field loading function already takes care of creating all subfolders
	//SetDataFolder root:
	
	//String path = ("C:Proc_Test:02-28:"+base_name+"_0.000_kG.txt")
	
	//Make a string that just has the folder name
	variable folder_ending = strsearch(path,":",Inf,1)
	String folder = path[0,folder_ending]
	
	//Make a string that just has the reference file name
	variable file_ending = strlen(path)
	variable kG_position =strsearch(path,"_kG",Inf,1)
	if (kG_position == -1)
		Print "Selected file name not properly formatted"
		Abort
	endif
	variable field_position = strsearch(path,"_",kG_position-1,1)
	String base_name = path[folder_ending + 1,field_position - 1]
	Print base_name
	
	//Variable ref_field_end = strsearch(ref_fname,"_kG",0)
	//Variable ref_field_begin = strsearch(ref_fname,"_",ref_field_end-1,1)
	//String ref_field = ref_fname[ref_field_begin+1,ref_field_end-1]
	//Print "Reference field = " + ref_field + " kG for " + base_name
	//mag_fk_rotations(folder,base_name,base_name_crossed,ref_field,f_start,f_end,k_start,k_end,1)
	
	NewPath/O/Q practice_path folder
	
	String test_string = IndexedFile(practice_path,-1,"????")
	Print test_string
	
	//This loop structure figures out how many fields there are, looking at all the files in the folder
	//figuring out which ones have the right name, then creating a text wave with them all
	String file_holder
	Variable scaling
	Variable begin_index = 0, semicolon_pos = 0, field_holder = 0
	Variable field_begin;
	String field;
	Variable num_fields = 0;
	Make/T/O/N=0  $(base_name + "_field_values")
	Wave/T text_field_values = $(base_name + "_field_values")
	do
		semicolon_pos = strsearch(test_string,";",semicolon_pos+1)  //Find next ; means new file
		if(semicolon_pos != -1)
			file_holder = test_string[begin_index,semicolon_pos-1] //store the file name, without the ; (this is why we have -1)
			field_holder = strsearch(file_holder,"_kG",0) //See if this is a magnetic field scan file
			if(field_holder != -1) // if it is, let's find out the field so we can get the rotations
				field_begin = strsearch(file_holder,"_",field_holder-1,1)
				field = file_holder[field_begin+1,field_holder-1]
				Print field
				if(cmpstr(file_holder[0,field_begin-1],base_name) == 0)
						Redimension/N=(num_fields+1) text_field_values
						text_field_values[num_fields] = field
						num_fields += 1;
						Print file_holder
				endif
			endif
			begin_index = semicolon_pos + 1
		endif
	while (semicolon_pos != -1)				// as long as expression is TRUE
	Print "There are "+num2str(num_fields)+" field values for "+base_name
	Sort/A text_field_values, text_field_values
	
	//begin_index = 0; more_files = 0; field_holder = 0;
	
	Variable i;
	for(i=0;i<num_fields;i+=1)
		file_holder = base_name + "_" + text_field_values[i] + "_kG"
		SingleWaveLoadMagnetAutoScans(folder,(file_holder + ".txt"))
		//mag_fk_rotations(folder,base_name,base_name_crossed,field,f_start,f_end,k_start,k_end,1)
	endfor
	
	//---------This will do FFTs based on the value of the checkbox in ChrisTHzWindow-------//
	ControlInfo/W=ChrisTHzWindow FFT_checkbox  //This is the checkbox on the control panel
	switch(V_value)
		case 0: //This is the no case
			break
		case 1:  //This is the yes case
			for(i=0;i<num_fields;i+=1)
				file_holder = base_name + "_" + text_field_values[i] + "_kG"
				fft_gen(file_holder)
			endfor
			break
	endswitch
	
//	String ref_file_holder = base_name + "_" + text_field_values[0] + "_kG"
//	Wave/C bottom = $(ref_file_holder + "_FFT")
//	for(i=1;i<num_fields;i+=1)
//		file_holder = base_name + "_" + text_field_values[i] + "_kG"
//		Wave/C top = $(file_holder + "_FFT")
//		top = top/bottom
//		//mag_fk_rotations(folder,base_name,base_name_crossed,field,f_start,f_end,k_start,k_end,1)
//	endfor
	
	
//	String dfSave = GetDataFolder(1)
//	NewDataFolder/O/S $(base_name)
//	NewDataFolder/O/S Rotations_Faraday
//	
//	Variable sizer = numpnts($("Rot_"+ref_field+"_kG_F"))
//	
//	Make/O/N=(sizer,num_fields) rotation_matrix
//	
//	SetDataFolder dfSave
//	
//	for(i=0;i<num_fields;i+=1)
//		field = text_field_values[i]
//		if(cmpstr(field,ref_field) != 0)
//			rot_angle_subtract(ref_field,field,base_name)
//		endif
//	endfor
//	
//	rot_angle_subtract(ref_field,ref_field,base_name)
//	
//	dfSave = GetDataFolder(1)
//	NewDataFolder/O/S $(base_name)
//	NewDataFolder/O/S Rotations_Faraday
//	
//	Variable j
//	Make/O/N=(num_fields) number_fields
//	Wave number_fields
//	for(i=0;i<num_fields;i+=1)
//		for(j=0;j<sizer;j+=1)
//			field = text_field_values[i]
//			number_fields[i] = str2num(text_field_values[i])
//			Wave rot_dummy =  $("Rot_"+field+"_kG_F")
//			rotation_matrix[j][i] = real(rot_dummy[j])
//		endfor
//	endfor
//	
//	NewDataFolder/O BDep
//	Variable freq = DimDelta($("Rot_" + ref_field + "_kG_F"),0)
//	Print freq
//	Variable freq_low_limit = 0.2;
//	Variable freq_high_limit = 2.0;
//	String current_freq;
//	variable iter_skip = 4;
//	variable k;
//	variable avg_dummy = 0;
//	for(i=0;i<sizer;i+=4)
//		current_freq = num2str(freq*i)
//		if(freq*i >= freq_low_limit && freq*i <= freq_high_limit)
//			Make/O/N=(num_fields) $("BDep_"+current_freq+"_THz_F")
//			Wave dummy_bdep = $("BDep_"+current_freq+"_THz_F")
//			for(j=0;j<num_fields;j+=1)
//				for(k=0;k<iter_skip;k+=1)
//					avg_dummy += rotation_matrix[i][j+k]
//				endfor
//				avg_dummy /= iter_skip;
//				dummy_bdep[j] = avg_dummy
//				//dummy_bdep[j] = rotation_matrix[i][j]
//				avg_dummy = 0;
//			endfor
//			Smooth 8, dummy_bdep
//			Duplicate/O dummy_bdep, :BDep:$("BDep_"+num2str(freq*i)+"_THz_F")
//			Killwaves dummy_bdep
//		endif
//	endfor
//	Duplicate/O number_fields, :BDep:number_fields
//	KillWaves number_fields
//	
//	//MatrixTranspose rotation_matrix
//	
//	SetDataFolder dfSave
	
end

function chris_ratio(field)
	String field
	
	string top_name = "Sa1_1.6K_L_" + field + "_kG_FFT"
	string bottom_name = "Sa1_4K_L_" + field + "_kG_FFT"
	string base_name = "R_Sa1_1.6K_4K_" + field + "_kG"
	
	Wave/C top = $(top_name)
	Wave/C bottom = $(bottom_name)
	Duplicate/O top, $base_name
	
	Wave/C ratio = $base_name
	
	ratio = top/bottom
	
end

function rot_angle_subtract(ref_field,sub_field,base_name)

	String ref_field,sub_field,base_name
	
	Wave/C ref_F_wave = :$(base_name):Rotations_Faraday:$("Rot_" + ref_field + "_kG_F")
	Wave/C sub_F_wave = :$(base_name):Rotations_Faraday:$("Rot_" + sub_field + "_kG_F")
	
	sub_F_wave -= ref_F_wave
	
	Wave/C ref_K_wave = :$(base_name):Rotations_Kerr:$("Rot_" + ref_field + "_kG_K")
	Wave/C sub_K_wave = :$(base_name):Rotations_Kerr:$("Rot_" + sub_field + "_kG_K")
	
	sub_K_wave = sub_K_wave - (ref_K_wave + sub_F_wave)
	//sub_K_wave -= sub_F_wave
	
	wavestats/Q/R=(0.2,0.9) sub_K_wave; sub_K_wave -= V_avg;
	
	Variable smooth_n = 50
	Variable boxcar_smooth = 20
	//Smooth/B=(boxcar_smooth) smooth_n, sub_F_wave
	//Smooth/B=(boxcar_smooth) smooth_n, sub_K_wave
	Make/O/N=(numpnts(sub_F_wave)) real_dummy
	Make/O/N=(numpnts(sub_F_wave)) imag_dummy
	real_dummy = real(sub_F_wave)
	imag_dummy = imag(sub_F_wave)
	Loess/N=(smooth_n) srcWave=real_dummy
	
	//Smooth/B=(boxcar_smooth) smooth_n, real_dummy
	sub_F_wave = cmplx(real_dummy,imag_dummy)
	
	KillWaves real_dummy,imag_dummy
	
	//Variable offset = 0.04
	//Variable field = str2num(sub_field) * offset
	//sub_F_wave += field
	
end



//this version allows you to input the number of files you want to do, but only starts at file 1...

Function SingleTimeTraceLoad_Button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			load_single_trace()
		
	endswitch

	return 0
End

Function multi_time_trace_no_FFT(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			load_multiple_traces()
	
	endswitch

	return 0
End

Function Do_100_percent_line(ba) : ButtonControl
	STRUCT WMButtonAction &ba	
	
	switch( ba.eventCode )
		case 2: // mouse up
			
			ohpl()
			
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function ChangeAxes_100pct_values(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			ModifyGraph cmplxMode=3
			SetAxis left 0.9,1.1
			SetAxis bottom 0.1,3.0
			ModifyGraph lsize=2
			ModifyGraph mirror=2,fStyle=1,fSize=14,axThick=1.5;
			Label left "\\f01\\Z18 Transmission";DelayUpdate
			Label bottom "\\f01\\Z18Frequency (THz)"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



Function ChangeAxes_TimeTraceValues(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			ModifyGraph lsize=3
			ModifyGraph mirror=2,fStyle=1,fSize=16,axThick=2.0;
			Label left "\\f01\\Z20Signal (V)";DelayUpdate
			Label bottom "\\f01\\Z20Time (ps)"
		break
	endswitch

	return 0
End

Function Mag_FK_Button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			//mag_fk_load(0,22,22,34)
			break
	endswitch

	return 0
End

Function Do_Transmission_With_Aperture(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			transfolder()
			
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function load_multiple_traces_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			load_multiple_traces()
			
	endswitch

	return 0
End

Function ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			load_multiple_traces_selections()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function ButtonProc_LoadMultipleTraces(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			load_multiple_traces_selections()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_ReloadMultTraces(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			reload_multiple_traces_select()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_LogLeftAxis(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			ModifyGraph log(left)=1
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function ButtonProc_LinearLeftAxis(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			ModifyGraph log(left) = 0
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_Yload(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			load_multiple_traces_selections()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ChangeAxes_TransmissionValues(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			ModifyGraph cmplxMode=3
			ModifyGraph Mode=0
			//SetAxis/A
			SetAxis left 0.0,1.1
			SetAxis bottom 0.1,3.0
			ModifyGraph lsize=2
			ModifyGraph mirror=2,fStyle=1,fSize=14,axThick=1.5;
			Label left "\\f01\\Z18 Transmission";DelayUpdate
			Label bottom "\\f01\\Z18Frequency (THz)"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ChangeAxes_TransmissionValues2(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			ModifyGraph cmplxMode=3
			ModifyGraph Mode=0
			//SetAxis/A
			SetAxis left 0.0,1.1
			SetAxis bottom 0.1,1.0
			ModifyGraph lsize=2
			ModifyGraph mirror=2,fStyle=1,fSize=14,axThick=1.5;
			Label left "\\f01\\Z18 Transmission";DelayUpdate
			Label bottom "\\f01\\Z18Frequency (THz)"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_1(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			SetAxis/A
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function ChangeLeftToTrans(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			SetAxis left 0.0,1.1
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function CheckProc_KillBegin(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			if(checked == 0)
				SetVariable kill_begin_value, win = ChrisTHzWindow, disable = 2
			elseif(checked == 1)
				SetVariable kill_begin_value, win = ChrisTHzWindow, disable = 0
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function CheckProc_KillEnd(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			if(checked == 0)
				SetVariable kill_end_value, win = ChrisTHzWindow, disable = 2
			elseif(checked == 1)
				SetVariable kill_end_value, win = ChrisTHzWindow, disable = 0
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function CheckProc_offset(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			ControlInfo/W=ChrisTHzWindow Offset_checkbox
			if(checked == 0)
				SetVariable begin_time_control, win = ChrisTHzWindow, disable=2
				SetVariable end_time_control, win = ChrisTHzWindow, disable=2
			elseif(checked == 1)
				SetVariable begin_time_control, win = ChrisTHzWindow, disable=0
				SetVariable end_time_control, win = ChrisTHzWindow, disable=0
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function AddPntsBeginCheck(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			if(checked == 0)
				SetVariable num_begin_add, win = ChrisTHzWindow, disable=2
				SetVariable value_begin_add, win = ChrisTHzWindow, disable=2
			elseif(checked == 1)
				SetVariable num_begin_add, win = ChrisTHzWindow, disable=0
				SetVariable value_begin_add, win = ChrisTHzWindow, disable=0
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function AddPntsEndCheck(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			if(checked == 0)
				SetVariable num_end_add, win = ChrisTHzWindow, disable=2
				SetVariable value_end_add, win = ChrisTHzWindow, disable=2
			elseif(checked == 1)
				SetVariable num_end_add, win = ChrisTHzWindow, disable=0
				SetVariable value_end_add, win = ChrisTHzWindow, disable=0
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
