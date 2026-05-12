#tag Class, Name = DashboardWindow, Description = "Main app window shown after login. Uses a PagePanel or TabPanel to host Modules, Timetable, Progress, and Settings pages."
	// -------------------------------------------------------------------------
	// Controls to create in the IDE designer
	// -------------------------------------------------------------------------
	// MainPagePanel       — PagePanel (tabs: Modules | Timetable | Progress | Settings)
	// OfflineBanner       — Label (shown when offline)
	// SyncStatusLabel     — Label ("Syncing…" / "All synced")
	// UserNameLabel       — Label
	// SignOutButton       — PushButton
	// -------------------------------------------------------------------------

	#tag Property, Name = OfflineSync, Type = OfflineSyncService, Scope = Private
	#tag EndProperty

	#tag Property, Name = ConnectivityTimer, Type = Timer, Scope = Private
	#tag EndProperty

	#tag Method, Scope = Public, Name = Opening
		UserNameLabel.Text = App.Auth.CurrentUser.Email

		OfflineSync = New OfflineSyncService(App.Supabase)

		// Poll connectivity every 10 s and flush queue when online.
		ConnectivityTimer = New Timer
		ConnectivityTimer.Period = 10000
		ConnectivityTimer.RunMode = Timer.RunModes.Multiple
		AddHandler ConnectivityTimer.Action, WeakAddressOf OnConnectivityTick
		ConnectivityTimer.Enabled = True

		LoadModulesPage
		UpdateOfflineBanner
	#tag EndMethod

	#tag Method, Scope = Private, Name = OnConnectivityTick
		#tag Parameter, Name = sender, Type = Timer
		#pragma unused sender
		UpdateOfflineBanner
		If OfflineSync.PendingCount > 0 Then
			SyncStatusLabel.Text = "Syncing " + Str(OfflineSync.PendingCount) + " item(s)…"
			OfflineSync.FlushQueue
			SyncStatusLabel.Text = "All synced"
		End If
	#tag EndMethod

	#tag Method, Scope = Private, Name = UpdateOfflineBanner
		// A simple heuristic: attempt a lightweight ping.
		Dim http As New URLConnection
		Dim pong As String
		Try
			pong = http.SendSync("GET", "https://www.google.com", 5)
		Catch e As RuntimeException
			pong = ""
		End Try
		Dim online As Boolean = (pong <> "")
		OfflineBanner.Visible = Not online
		OfflineBanner.Text = If(online, "", "Offline — changes will sync when reconnected")
	#tag EndMethod

	#tag Method, Scope = Private, Name = LoadModulesPage
		// Replace with actual page/control population logic.
		// For now, fetch modules from Supabase and display in a Listbox.
		Dim raw As String = App.Supabase.Get("modules", "select=*&deleted_at=is.null&order=created_at.desc")
		If raw = "" Then Return
		Try
			Dim arr As New JSONItem(raw)
			For i As Integer = 0 To arr.Count - 1
				Dim m As ModuleModel = (New ModuleModel).FromJSON(arr.Child(i))
				// TODO: add m to a Listbox or custom container on the Modules page.
				System.DebugLog("Module: " + m.Title + " (" + Format(m.Progress * 100, "0") + "%)")
			Next
		Catch e As JSONException
			System.DebugLog("LoadModulesPage JSON error: " + e.Message)
		End Try
	#tag EndMethod

	#tag Method, Scope = Public, Name = SignOutButton_Action
		ConnectivityTimer.Enabled = False
		App.Auth.SignOut
		Dim win As New LoginWindow
		win.Show
		Self.Close
	#tag EndMethod
#tag EndClass
