#tag Class, Name = SupabaseService, Description = "HTTP wrapper around the Supabase REST API. Handles auth headers, JSON serialisation, and basic error reporting."
	#tag Property, Name = BaseURL, Type = String, Scope = Private
	#tag EndProperty

	#tag Property, Name = AnonKey, Type = String, Scope = Private
	#tag EndProperty

	#tag Property, Name = AuthToken, Type = String, Scope = Private
	#tag EndProperty

	// -------------------------------------------------------------------------
	// Lifecycle
	// -------------------------------------------------------------------------

	#tag Method, Scope = Public, Name = Constructor
		#tag Parameter, Name = url, Type = String
		#tag Parameter, Name = anonKey, Type = String
		BaseURL = url
		AnonKey = anonKey
	#tag EndMethod

	#tag Method, Scope = Public, Name = SetAuthToken
		#tag Parameter, Name = token, Type = String
		AuthToken = token
	#tag EndMethod

	// -------------------------------------------------------------------------
	// REST helpers — all return raw JSON strings; parse with JSONItem upstream.
	// -------------------------------------------------------------------------

	#tag Method, Scope = Public, Name = Get, Type = String
		#tag Parameter, Name = endpoint, Type = String
		#tag Parameter, Name = query, Type = String  // e.g. "id=eq.123&select=*"
		Dim http As New URLConnection
		ApplyHeaders(http)
		Dim url As String = BaseURL + "/rest/v1/" + endpoint
		If query <> "" Then url = url + "?" + query
		Return http.SendSync("GET", url, 30)
	#tag EndMethod

	#tag Method, Scope = Public, Name = Post, Type = String
		#tag Parameter, Name = endpoint, Type = String
		#tag Parameter, Name = body, Type = String  // JSON string
		Dim http As New URLConnection
		ApplyHeaders(http)
		http.SetRequestHeader("Prefer", "return=representation")
		Dim content As New URLConnection.HTTPContent(body, "application/json")
		Return http.SendSync("POST", BaseURL + "/rest/v1/" + endpoint, content, 30)
	#tag EndMethod

	#tag Method, Scope = Public, Name = Patch, Type = String
		#tag Parameter, Name = endpoint, Type = String
		#tag Parameter, Name = query, Type = String
		#tag Parameter, Name = body, Type = String
		Dim http As New URLConnection
		ApplyHeaders(http)
		http.SetRequestHeader("Prefer", "return=representation")
		Dim content As New URLConnection.HTTPContent(body, "application/json")
		Dim url As String = BaseURL + "/rest/v1/" + endpoint
		If query <> "" Then url = url + "?" + query
		Return http.SendSync("PATCH", url, content, 30)
	#tag EndMethod

	#tag Method, Scope = Public, Name = Delete, Type = String
		#tag Parameter, Name = endpoint, Type = String
		#tag Parameter, Name = query, Type = String
		Dim http As New URLConnection
		ApplyHeaders(http)
		Dim url As String = BaseURL + "/rest/v1/" + endpoint
		If query <> "" Then url = url + "?" + query
		Return http.SendSync("DELETE", url, 30)
	#tag EndMethod

	// -------------------------------------------------------------------------
	// Auth endpoints
	// -------------------------------------------------------------------------

	#tag Method, Scope = Public, Name = SignInWithPassword, Type = String
		#tag Parameter, Name = email, Type = String
		#tag Parameter, Name = password, Type = String
		Dim body As String = "{""email"":""" + email + """,""password"":""" + password + """}"
		Dim http As New URLConnection
		http.SetRequestHeader("apikey", AnonKey)
		http.SetRequestHeader("Content-Type", "application/json")
		Dim content As New URLConnection.HTTPContent(body, "application/json")
		Return http.SendSync("POST", BaseURL + "/auth/v1/token?grant_type=password", content, 30)
	#tag EndMethod

	#tag Method, Scope = Public, Name = SignUp, Type = String
		#tag Parameter, Name = email, Type = String
		#tag Parameter, Name = password, Type = String
		Dim body As String = "{""email"":""" + email + """,""password"":""" + password + """}"
		Dim http As New URLConnection
		http.SetRequestHeader("apikey", AnonKey)
		http.SetRequestHeader("Content-Type", "application/json")
		Dim content As New URLConnection.HTTPContent(body, "application/json")
		Return http.SendSync("POST", BaseURL + "/auth/v1/signup", content, 30)
	#tag EndMethod

	#tag Method, Scope = Public, Name = SignOut
		Dim http As New URLConnection
		ApplyHeaders(http)
		http.SendSync("POST", BaseURL + "/auth/v1/logout", 30)
		AuthToken = ""
	#tag EndMethod

	// -------------------------------------------------------------------------
	// Storage
	// -------------------------------------------------------------------------

	#tag Method, Scope = Public, Name = UploadFile, Type = String
		#tag Parameter, Name = bucket, Type = String
		#tag Parameter, Name = path, Type = String
		#tag Parameter, Name = data, Type = MemoryBlock
		#tag Parameter, Name = mimeType, Type = String
		Dim http As New URLConnection
		ApplyHeaders(http)
		Dim content As New URLConnection.HTTPContent(data, mimeType)
		Return http.SendSync("POST", BaseURL + "/storage/v1/object/" + bucket + "/" + path, content, 60)
	#tag EndMethod

	#tag Method, Scope = Public, Name = GetPublicURL, Type = String
		#tag Parameter, Name = bucket, Type = String
		#tag Parameter, Name = path, Type = String
		Return BaseURL + "/storage/v1/object/public/" + bucket + "/" + path
	#tag EndMethod

	// -------------------------------------------------------------------------
	// Edge Functions
	// -------------------------------------------------------------------------

	#tag Method, Scope = Public, Name = InvokeFunction, Type = String
		#tag Parameter, Name = functionName, Type = String
		#tag Parameter, Name = body, Type = String
		Dim http As New URLConnection
		ApplyHeaders(http)
		Dim content As New URLConnection.HTTPContent(body, "application/json")
		Return http.SendSync("POST", BaseURL + "/functions/v1/" + functionName, content, 60)
	#tag EndMethod

	// -------------------------------------------------------------------------
	// Private
	// -------------------------------------------------------------------------

	#tag Method, Scope = Private, Name = ApplyHeaders
		#tag Parameter, Name = http, Type = URLConnection
		http.SetRequestHeader("apikey", AnonKey)
		http.SetRequestHeader("Content-Type", "application/json")
		If AuthToken <> "" Then
			http.SetRequestHeader("Authorization", "Bearer " + AuthToken)
		End If
	#tag EndMethod
#tag EndClass
