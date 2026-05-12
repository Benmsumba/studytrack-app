#tag Class, Name = OfflineSyncService, Description = "Queues mutations in a local SQLite database while offline. On reconnect, flushes the queue to Supabase in FIFO order."
	#tag Property, Name = db, Type = SupabaseService, Scope = Private
	#tag EndProperty

	#tag Property, Name = localDB, Type = SQLiteDatabase, Scope = Private
	#tag EndProperty

	#tag Property, Name = IsSyncing, Type = Boolean, Scope = Public
	#tag EndProperty

	#tag Method, Scope = Public, Name = Constructor
		#tag Parameter, Name = supabase, Type = SupabaseService
		db = supabase
		InitLocalDB
	#tag EndMethod

	#tag Method, Scope = Private, Name = InitLocalDB
		Dim dbFile As FolderItem = SpecialFolder.ApplicationData.Child("studytrack_offline.sqlite")
		localDB = New SQLiteDatabase
		localDB.DatabaseFile = dbFile
		If Not localDB.Connect Then
			System.DebugLog("OfflineSyncService: could not open SQLite: " + localDB.ErrorMessage)
			Return
		End If
		Dim sql As String = _
			"CREATE TABLE IF NOT EXISTS sync_queue (" & _
			"  id        INTEGER PRIMARY KEY AUTOINCREMENT," & _
			"  created   TEXT    NOT NULL DEFAULT (datetime('now'))," & _
			"  method    TEXT    NOT NULL," & _  // GET, POST, PATCH, DELETE
			"  endpoint  TEXT    NOT NULL," & _
			"  query     TEXT    NOT NULL DEFAULT ''," & _
			"  body      TEXT    NOT NULL DEFAULT ''," & _
			"  retries   INTEGER NOT NULL DEFAULT 0" & _
			")"
		localDB.ExecuteSQL(sql)
	#tag EndMethod

	#tag Method, Scope = Public, Name = Enqueue
		#tag Parameter, Name = method, Type = String
		#tag Parameter, Name = endpoint, Type = String
		#tag Parameter, Name = query, Type = String
		#tag Parameter, Name = body, Type = String
		Dim sql As String = _
			"INSERT INTO sync_queue (method, endpoint, query, body) VALUES (?, ?, ?, ?)"
		localDB.ExecuteSQL(sql, method, endpoint, query, body)
	#tag EndMethod

	#tag Method, Scope = Public, Name = FlushQueue
		// Call this when connectivity is restored. Processes all pending mutations.
		If IsSyncing Then Return
		IsSyncing = True
		Try
			Dim rs As RowSet = localDB.SelectSQL("SELECT * FROM sync_queue ORDER BY id ASC")
			While Not rs.AfterLastRow
				Dim qid As Integer = rs.Column("id").IntegerValue
				Dim method As String = rs.Column("method").StringValue
				Dim endpoint As String = rs.Column("endpoint").StringValue
				Dim query As String = rs.Column("query").StringValue
				Dim body As String = rs.Column("body").StringValue

				Dim success As Boolean = False
				Select Case method
				Case "POST"
					Dim result As String = db.Post(endpoint, body)
					success = (result <> "" And Not result.Contains("""error"""))
				Case "PATCH"
					Dim result As String = db.Patch(endpoint, query, body)
					success = (result <> "" And Not result.Contains("""error"""))
				Case "DELETE"
					Dim result As String = db.Delete(endpoint, query)
					success = True  // treat 404 as already deleted
				End Select

				If success Then
					localDB.ExecuteSQL("DELETE FROM sync_queue WHERE id = ?", qid)
				Else
					localDB.ExecuteSQL("UPDATE sync_queue SET retries = retries + 1 WHERE id = ?", qid)
				End If
				rs.MoveToNextRow
			Wend
		Catch e As DatabaseException
			System.DebugLog("FlushQueue error: " + e.Message)
		Finally
			IsSyncing = False
		End Try
	#tag EndMethod

	#tag Method, Scope = Public, Name = PendingCount, Type = Integer
		Try
			Dim rs As RowSet = localDB.SelectSQL("SELECT COUNT(*) AS n FROM sync_queue")
			Return rs.Column("n").IntegerValue
		Catch e As DatabaseException
			Return 0
		End Try
	#tag EndMethod
#tag EndClass
