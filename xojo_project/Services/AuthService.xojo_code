#tag Class, Name = AuthService, Description = "Wraps SupabaseService auth calls. Parses JWT response and exposes typed result objects."
	#tag Property, Name = db, Type = SupabaseService, Scope = Private
	#tag EndProperty

	#tag Property, Name = CurrentUser, Type = UserModel, Scope = Public
	#tag EndProperty

	#tag Method, Scope = Public, Name = Constructor
		#tag Parameter, Name = supabase, Type = SupabaseService
		db = supabase
	#tag EndMethod

	#tag Method, Scope = Public, Name = SignIn, Type = Boolean
		#tag Parameter, Name = email, Type = String
		#tag Parameter, Name = password, Type = String
		#tag Parameter, Name = errorMsg, Type = String ByRef
		Dim raw As String = db.SignInWithPassword(email, password)
		If raw = "" Then
			errorMsg = "No response from server."
			Return False
		End If
		Try
			Dim j As New JSONItem(raw)
			If j.HasKey("error") Then
				errorMsg = j.Value("error_description")
				Return False
			End If
			Dim token As String = j.Value("access_token")
			db.SetAuthToken(token)
			// Persist token so next launch skips login.
			App.Preferences.Value("auth_token") = token

			Dim userJ As JSONItem = j.Child("user")
			Dim u As New UserModel
			u.ID = userJ.Value("id")
			u.Email = userJ.Value("email")
			CurrentUser = u
			Return True
		Catch e As JSONException
			errorMsg = "Unexpected response format."
			Return False
		End Try
	#tag EndMethod

	#tag Method, Scope = Public, Name = SignUp, Type = Boolean
		#tag Parameter, Name = email, Type = String
		#tag Parameter, Name = password, Type = String
		#tag Parameter, Name = errorMsg, Type = String ByRef
		Dim raw As String = db.SignUp(email, password)
		If raw = "" Then
			errorMsg = "No response from server."
			Return False
		End If
		Try
			Dim j As New JSONItem(raw)
			If j.HasKey("error") Then
				errorMsg = j.Value("error_description")
				Return False
			End If
			Return True
		Catch e As JSONException
			errorMsg = "Unexpected response format."
			Return False
		End Try
	#tag EndMethod

	#tag Method, Scope = Public, Name = SignOut
		App.Preferences.Value("auth_token") = ""
		db.SignOut
		CurrentUser = Nil
	#tag EndMethod
#tag EndClass
