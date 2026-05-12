#tag Class, Name = ModuleModel, Description = "A study module (course unit) belonging to a user."
	#tag Property, Name = ID, Type = String, Scope = Public
	#tag EndProperty

	#tag Property, Name = UserID, Type = String, Scope = Public
	#tag EndProperty

	#tag Property, Name = Title, Type = String, Scope = Public
	#tag EndProperty

	#tag Property, Name = ColorHex, Type = String, Scope = Public  // e.g. "#4A90D9"
	#tag EndProperty

	#tag Property, Name = TotalTopics, Type = Integer, Scope = Public
	#tag EndProperty

	#tag Property, Name = CompletedTopics, Type = Integer, Scope = Public
	#tag EndProperty

	#tag Property, Name = CreatedAt, Type = String, Scope = Public
	#tag EndProperty

	#tag Property, Name = DeletedAt, Type = String, Scope = Public  // soft delete
	#tag EndProperty

	#tag Method, Scope = Public, Name = Progress, Type = Double
		// Returns completion ratio 0.0–1.0.
		If TotalTopics = 0 Then Return 0.0
		Return CompletedTopics / TotalTopics
	#tag EndMethod

	#tag Method, Scope = Public, Name = FromJSON, Type = ModuleModel
		#tag Parameter, Name = j, Type = JSONItem
		Dim m As New ModuleModel
		m.ID = j.Value("id")
		m.UserID = j.Value("user_id")
		m.Title = j.Value("title")
		m.ColorHex = j.Value("color_hex")
		If j.HasKey("total_topics") Then m.TotalTopics = j.Value("total_topics")
		If j.HasKey("completed_topics") Then m.CompletedTopics = j.Value("completed_topics")
		m.CreatedAt = j.Value("created_at")
		Return m
	#tag EndMethod

	#tag Method, Scope = Public, Name = ToJSON, Type = String
		Dim j As New JSONItem
		j.Value("title") = Title
		j.Value("color_hex") = ColorHex
		j.Value("user_id") = UserID
		Return j.ToString
	#tag EndMethod
#tag EndClass
