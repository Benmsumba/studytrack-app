#tag Class, Name = UserModel, Description = "Represents an authenticated Supabase user."
	#tag Property, Name = ID, Type = String, Scope = Public
	#tag EndProperty

	#tag Property, Name = Email, Type = String, Scope = Public
	#tag EndProperty

	#tag Property, Name = CreatedAt, Type = String, Scope = Public
	#tag EndProperty

	#tag Method, Scope = Public, Name = FromJSON, Type = UserModel
		#tag Parameter, Name = j, Type = JSONItem
		Dim u As New UserModel
		u.ID = j.Value("id")
		u.Email = j.Value("email")
		u.CreatedAt = j.Value("created_at")
		Return u
	#tag EndMethod
#tag EndClass
