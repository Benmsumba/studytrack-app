#tag Class, Name = LoginWindow, Description = "Sign-in / sign-up screen. Create the visual layout in the Xojo IDE designer — this file holds only the logic."
	// -------------------------------------------------------------------------
	// Controls (add these in the IDE designer and connect their names here)
	// -------------------------------------------------------------------------
	// EmailField       — TextField
	// PasswordField    — TextField  (Password = True)
	// SignInButton     — PushButton
	// SignUpButton     — PushButton
	// ErrorLabel       — Label
	// BusySpinner      — ProgressWheel or ProgressBar
	// ToggleModeButton — PushButton  ("No account? Sign up" / "Have account? Sign in")
	// -------------------------------------------------------------------------

	#tag Property, Name = IsSignUpMode, Type = Boolean, Scope = Private
	#tag EndProperty

	#tag Method, Scope = Public, Name = Opening
		// Called when the window first appears.
		ErrorLabel.Text = ""
		BusySpinner.Visible = False
		UpdateModeUI
	#tag EndMethod

	#tag Method, Scope = Private, Name = UpdateModeUI
		If IsSignUpMode Then
			SignInButton.Visible = False
			SignUpButton.Visible = True
			ToggleModeButton.Caption = "Already have an account? Sign in"
		Else
			SignInButton.Visible = True
			SignUpButton.Visible = False
			ToggleModeButton.Caption = "No account? Sign up"
		End If
	#tag EndMethod

	// -------------------------------------------------------------------------
	// Button actions — wire these up via the IDE's event editor
	// -------------------------------------------------------------------------

	#tag Method, Scope = Public, Name = SignInButton_Action
		If Not Validate Then Return
		SetBusy(True)
		Dim errMsg As String
		Dim ok As Boolean = App.Auth.SignIn(EmailField.Text.Trim, PasswordField.Text, errMsg)
		SetBusy(False)
		If ok Then
			Dim win As New DashboardWindow
			win.Show
			Self.Close
		Else
			ShowError(errMsg)
		End If
	#tag EndMethod

	#tag Method, Scope = Public, Name = SignUpButton_Action
		If Not Validate Then Return
		SetBusy(True)
		Dim errMsg As String
		Dim ok As Boolean = App.Auth.SignUp(EmailField.Text.Trim, PasswordField.Text, errMsg)
		SetBusy(False)
		If ok Then
			ShowError("Account created! Check your email to confirm, then sign in.")
			IsSignUpMode = False
			UpdateModeUI
		Else
			ShowError(errMsg)
		End If
	#tag EndMethod

	#tag Method, Scope = Public, Name = ToggleModeButton_Action
		IsSignUpMode = Not IsSignUpMode
		ErrorLabel.Text = ""
		UpdateModeUI
	#tag EndMethod

	// -------------------------------------------------------------------------
	// Helpers
	// -------------------------------------------------------------------------

	#tag Method, Scope = Private, Name = Validate, Type = Boolean
		If EmailField.Text.Trim = "" Then
			ShowError("Email is required.")
			Return False
		End If
		If PasswordField.Text.Length < 6 Then
			ShowError("Password must be at least 6 characters.")
			Return False
		End If
		Return True
	#tag EndMethod

	#tag Method, Scope = Private, Name = SetBusy
		#tag Parameter, Name = busy, Type = Boolean
		BusySpinner.Visible = busy
		SignInButton.Enabled = Not busy
		SignUpButton.Enabled = Not busy
		EmailField.Enabled = Not busy
		PasswordField.Enabled = Not busy
	#tag EndMethod

	#tag Method, Scope = Private, Name = ShowError
		#tag Parameter, Name = msg, Type = String
		ErrorLabel.Text = msg
	#tag EndMethod
#tag EndClass
