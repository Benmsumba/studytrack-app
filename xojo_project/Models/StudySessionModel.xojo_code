#tag Class, Name = StudySessionModel, Description = "A completed Pomodoro/study session logged against a module."
	#tag Property, Name = ID, Type = String, Scope = Public
	#tag EndProperty

	#tag Property, Name = UserID, Type = String, Scope = Public
	#tag EndProperty

	#tag Property, Name = ModuleID, Type = String, Scope = Public
	#tag EndProperty

	#tag Property, Name = DurationMinutes, Type = Integer, Scope = Public
	#tag EndProperty

	#tag Property, Name = StartedAt, Type = String, Scope = Public
	#tag EndProperty

	#tag Property, Name = EndedAt, Type = String, Scope = Public
	#tag EndProperty

	#tag Property, Name = Notes, Type = String, Scope = Public
	#tag EndProperty

	#tag Method, Scope = Public, Name = FromJSON, Type = StudySessionModel
		#tag Parameter, Name = j, Type = JSONItem
		Dim s As New StudySessionModel
		s.ID = j.Value("id")
		s.UserID = j.Value("user_id")
		s.ModuleID = j.Value("module_id")
		s.DurationMinutes = j.Value("duration_minutes")
		s.StartedAt = j.Value("started_at")
		s.EndedAt = j.Value("ended_at")
		If j.HasKey("notes") Then s.Notes = j.Value("notes")
		Return s
	#tag EndMethod

	#tag Method, Scope = Public, Name = ToJSON, Type = String
		Dim j As New JSONItem
		j.Value("user_id") = UserID
		j.Value("module_id") = ModuleID
		j.Value("duration_minutes") = DurationMinutes
		j.Value("started_at") = StartedAt
		j.Value("ended_at") = EndedAt
		j.Value("notes") = Notes
		Return j.ToString
	#tag EndMethod
#tag EndClass
