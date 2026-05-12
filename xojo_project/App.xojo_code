#tag Class, Name = App, Description = "Application entry point. Initialise services, then show LoginWindow or DashboardWindow based on saved session."
	#tag Property, Name = Supabase, Type = SupabaseService, Scope = Public
	#tag EndProperty

	#tag Property, Name = Auth, Type = AuthService, Scope = Public
	#tag EndProperty

	#tag Method, Scope = Public, Name = Opening
		// Called once at startup before any window is shown.
		Dim supabaseUrl As String = "https://YOUR_PROJECT.supabase.co"
		Dim supabaseKey As String = "YOUR_ANON_KEY"  // load from prefs or env in production

		Supabase = New SupabaseService(supabaseUrl, supabaseKey)
		Auth = New AuthService(Supabase)

		// Restore saved session token if one exists.
		Dim savedToken As String = App.Preferences.Value("auth_token")
		If savedToken <> "" Then
			Supabase.SetAuthToken(savedToken)
			Dim win As New DashboardWindow
			win.Show
		Else
			Dim win As New LoginWindow
			win.Show
		End If
	#tag EndMethod

	#tag Method, Scope = Public, Name = Preferences, Type = Dictionary
		// Thin wrapper around a persistent Dictionary stored in a Preferences file.
		// Replace with Xojo's built-in Preferences class if targeting macOS/Windows only.
		Static prefs As New Dictionary
		Return prefs
	#tag EndMethod
#tag EndClass
