#tag Class, Name = PomodoroWindow, Description = "Study session timer. Counts down a configurable Pomodoro interval, logs the session on completion."
	// -------------------------------------------------------------------------
	// Controls to create in the IDE designer
	// -------------------------------------------------------------------------
	// TimerLabel        — Label  (large, shows "25:00")
	// StartPauseButton  — PushButton ("Start" / "Pause" / "Resume")
	// StopButton        — PushButton
	// ModulePopupMenu   — PopupMenu (populated from loaded modules)
	// DurationSlider    — Slider  (5–60 minutes, tick 5)
	// DurationLabel     — Label  ("25 min")
	// SessionNotesField — TextArea
	// -------------------------------------------------------------------------

	#tag Property, Name = SessionTimer, Type = Timer, Scope = Private
	#tag EndProperty

	#tag Property, Name = SecondsRemaining, Type = Integer, Scope = Private
	#tag EndProperty

	#tag Property, Name = TotalSeconds, Type = Integer, Scope = Private
	#tag EndProperty

	#tag Property, Name = SessionStartTime, Type = String, Scope = Private
	#tag EndProperty

	#tag Property, Name = IsRunning, Type = Boolean, Scope = Private
	#tag EndProperty

	#tag Property, Name = Modules, Type = ModuleModel(), Scope = Private
	#tag EndProperty

	#tag Method, Scope = Public, Name = Opening
		LoadModules
		DurationSlider.Value = 25
		UpdateDurationLabel
		ResetTimer
	#tag EndMethod

	#tag Method, Scope = Private, Name = LoadModules
		Dim raw As String = App.Supabase.Get("modules", "select=id,title&deleted_at=is.null&order=title.asc")
		If raw = "" Then Return
		Try
			Dim arr As New JSONItem(raw)
			ReDim Modules(arr.Count - 1)
			ModulePopupMenu.DeleteAllRows
			For i As Integer = 0 To arr.Count - 1
				Modules(i) = (New ModuleModel).FromJSON(arr.Child(i))
				ModulePopupMenu.AddRow(Modules(i).Title)
			Next
		Catch e As JSONException
		End Try
	#tag EndMethod

	#tag Method, Scope = Private, Name = ResetTimer
		TotalSeconds = DurationSlider.Value * 60
		SecondsRemaining = TotalSeconds
		UpdateTimerLabel
		StartPauseButton.Caption = "Start"
		IsRunning = False
	#tag EndMethod

	#tag Method, Scope = Private, Name = UpdateTimerLabel
		Dim mins As Integer = SecondsRemaining \ 60
		Dim secs As Integer = SecondsRemaining Mod 60
		TimerLabel.Text = Format(mins, "00") + ":" + Format(secs, "00")
	#tag EndMethod

	#tag Method, Scope = Private, Name = UpdateDurationLabel
		DurationLabel.Text = Str(DurationSlider.Value) + " min"
	#tag EndMethod

	// -------------------------------------------------------------------------
	// Button actions
	// -------------------------------------------------------------------------

	#tag Method, Scope = Public, Name = StartPauseButton_Action
		If Not IsRunning Then
			// Start or Resume
			If SessionStartTime = "" Then
				SessionStartTime = Format(Now, "yyyy-MM-ddTHH:mm:ss") + "Z"
			End If
			If SessionTimer = Nil Then
				SessionTimer = New Timer
				SessionTimer.Period = 1000
				SessionTimer.RunMode = Timer.RunModes.Multiple
				AddHandler SessionTimer.Action, WeakAddressOf OnTick
			End If
			SessionTimer.Enabled = True
			IsRunning = True
			StartPauseButton.Caption = "Pause"
		Else
			SessionTimer.Enabled = False
			IsRunning = False
			StartPauseButton.Caption = "Resume"
		End If
	#tag EndMethod

	#tag Method, Scope = Public, Name = StopButton_Action
		If SessionTimer <> Nil Then SessionTimer.Enabled = False
		IsRunning = False
		If SessionStartTime <> "" Then
			LogSession
		End If
		SessionStartTime = ""
		ResetTimer
	#tag EndMethod

	#tag Method, Scope = Public, Name = DurationSlider_ValueChanged
		If Not IsRunning Then
			ResetTimer
		End If
		UpdateDurationLabel
	#tag EndMethod

	// -------------------------------------------------------------------------
	// Timer tick
	// -------------------------------------------------------------------------

	#tag Method, Scope = Private, Name = OnTick
		#tag Parameter, Name = sender, Type = Timer
		#pragma unused sender
		SecondsRemaining = SecondsRemaining - 1
		UpdateTimerLabel
		If SecondsRemaining <= 0 Then
			SessionTimer.Enabled = False
			IsRunning = False
			LogSession
			SessionStartTime = ""
			MsgBox "Session complete! Great work."
			ResetTimer
		End If
	#tag EndMethod

	// -------------------------------------------------------------------------
	// Persist session to Supabase
	// -------------------------------------------------------------------------

	#tag Method, Scope = Private, Name = LogSession
		Dim durationMins As Integer = (TotalSeconds - SecondsRemaining) \ 60
		If durationMins < 1 Then Return

		Dim selectedModule As String = ""
		Dim idx As Integer = ModulePopupMenu.ListIndex
		If idx >= 0 And idx <= UBound(Modules) Then
			selectedModule = Modules(idx).ID
		End If

		Dim s As New StudySessionModel
		s.UserID = App.Auth.CurrentUser.ID
		s.ModuleID = selectedModule
		s.DurationMinutes = durationMins
		s.StartedAt = SessionStartTime
		s.EndedAt = Format(Now, "yyyy-MM-ddTHH:mm:ss") + "Z"
		s.Notes = SessionNotesField.Text

		// Post to Supabase; queue offline if it fails.
		Dim result As String = App.Supabase.Post("study_sessions", s.ToJSON)
		If result = "" Or result.Contains("""error""") Then
			App.OfflineSync.Enqueue("POST", "study_sessions", "", s.ToJSON)
		End If
	#tag EndMethod
#tag EndClass
