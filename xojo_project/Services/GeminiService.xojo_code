#tag Class, Name = GeminiService, Description = "Calls the Gemini proxy Edge Function hosted on Supabase. Supports single-turn generateText and multi-turn chat."
	#tag Property, Name = db, Type = SupabaseService, Scope = Private
	#tag EndProperty

	#tag Method, Scope = Public, Name = Constructor
		#tag Parameter, Name = supabase, Type = SupabaseService
		db = supabase
	#tag EndMethod

	// Single-turn: returns the model text or "" on error.
	#tag Method, Scope = Public, Name = GenerateText, Type = String
		#tag Parameter, Name = prompt, Type = String
		Dim j As New JSONItem
		j.Value("type") = "generateText"
		j.Value("prompt") = prompt
		Dim raw As String = db.InvokeFunction("gemini-proxy", j.ToString)
		Return ParseTextResponse(raw)
	#tag EndMethod

	// Multi-turn: history is an array of {role, text} JSONItems.
	#tag Method, Scope = Public, Name = Chat, Type = String
		#tag Parameter, Name = history, Type = JSONItem  // JSONItem array
		#tag Parameter, Name = userMessage, Type = String
		Dim msg As New JSONItem
		msg.Value("role") = "user"
		msg.Value("text") = userMessage
		history.Append(msg)

		Dim body As New JSONItem
		body.Value("type") = "streamChat"
		body.Value("history") = history
		Dim raw As String = db.InvokeFunction("gemini-proxy", body.ToString)
		Return ParseTextResponse(raw)
	#tag EndMethod

	#tag Method, Scope = Private, Name = ParseTextResponse, Type = String
		#tag Parameter, Name = raw, Type = String
		If raw = "" Then Return ""
		Try
			Dim j As New JSONItem(raw)
			If j.HasKey("text") Then Return j.Value("text")
			If j.HasKey("error") Then
				System.DebugLog("GeminiService error: " + j.Value("error"))
				Return ""
			End If
		Catch e As JSONException
			System.DebugLog("GeminiService parse error: " + e.Message)
		End Try
		Return ""
	#tag EndMethod
#tag EndClass
