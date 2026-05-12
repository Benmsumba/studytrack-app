#tag Class, Name = TopicModel, Description = "A topic within a module. Carries spaced-repetition scheduling and a self-rating."
	#tag Property, Name = ID, Type = String, Scope = Public
	#tag EndProperty

	#tag Property, Name = ModuleID, Type = String, Scope = Public
	#tag EndProperty

	#tag Property, Name = UserID, Type = String, Scope = Public
	#tag EndProperty

	#tag Property, Name = Title, Type = String, Scope = Public
	#tag EndProperty

	#tag Property, Name = Notes, Type = String, Scope = Public
	#tag EndProperty

	#tag Property, Name = Rating, Type = Integer, Scope = Public  // 1–10 self rating
	#tag EndProperty

	#tag Property, Name = IsCompleted, Type = Boolean, Scope = Public
	#tag EndProperty

	#tag Property, Name = NextReviewAt, Type = String, Scope = Public  // ISO datetime
	#tag EndProperty

	#tag Property, Name = CreatedAt, Type = String, Scope = Public
	#tag EndProperty

	#tag Method, Scope = Public, Name = FromJSON, Type = TopicModel
		#tag Parameter, Name = j, Type = JSONItem
		Dim t As New TopicModel
		t.ID = j.Value("id")
		t.ModuleID = j.Value("module_id")
		t.UserID = j.Value("user_id")
		t.Title = j.Value("title")
		If j.HasKey("notes") Then t.Notes = j.Value("notes")
		If j.HasKey("rating") Then t.Rating = j.Value("rating")
		If j.HasKey("is_completed") Then t.IsCompleted = j.Value("is_completed")
		If j.HasKey("next_review_at") Then t.NextReviewAt = j.Value("next_review_at")
		t.CreatedAt = j.Value("created_at")
		Return t
	#tag EndMethod

	#tag Method, Scope = Public, Name = ToJSON, Type = String
		Dim j As New JSONItem
		j.Value("module_id") = ModuleID
		j.Value("user_id") = UserID
		j.Value("title") = Title
		j.Value("notes") = Notes
		j.Value("rating") = Rating
		j.Value("is_completed") = IsCompleted
		Return j.ToString
	#tag EndMethod
#tag EndClass
