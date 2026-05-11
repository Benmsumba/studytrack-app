#!/usr/bin/env dart
// Standalone health check for the StudyTrack → Supabase connection.
// Run from the repo root:
//
//   dart scripts/supabase_health_check.dart
//
// The script reads studytrack/.env (or falls back to .env at the repo root),
// then fires three HTTP probes and reports the result for each one.
// No external packages required — only dart:io and dart:convert.

import 'dart:convert';
import 'dart:io';

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

Future<void> main() async {
  _printHeader('StudyTrack · Supabase Connection Health Check');

  final env = _loadEnv();

  final supabaseUrl = env['SUPABASE_URL'] ?? '';
  final anonKey = env['SUPABASE_ANON_KEY'] ?? '';

  // --- Pre-flight: credentials present? ---
  _section('Step 0 · Environment Variables');
  final urlOk = supabaseUrl.isNotEmpty && !supabaseUrl.contains('your-project');
  final keyOk = anonKey.isNotEmpty && anonKey != 'your-anon-key-here';

  _check(
    'SUPABASE_URL is set',
    urlOk,
    urlOk ? supabaseUrl : 'MISSING or placeholder — edit studytrack/.env',
  );
  _check(
    'SUPABASE_ANON_KEY is set',
    keyOk,
    keyOk
        ? '${anonKey.substring(0, 12)}… (truncated)'
        : 'MISSING or placeholder — edit studytrack/.env',
  );

  if (!urlOk || !keyOk) {
    _fatal(
      'Cannot continue: fill in studytrack/.env with real credentials first.\n'
      '  Copy template:  cp studytrack/.env.example studytrack/.env\n'
      '  Then set SUPABASE_URL and SUPABASE_ANON_KEY from:\n'
      '  Supabase Dashboard → Project → Settings → API',
    );
    exit(1);
  }

  final baseUrl = supabaseUrl.replaceAll(RegExp(r'/+$'), '');

  // --- Probe 1: Auth service health ---
  _section('Step 1 · Auth Service  (GET /auth/v1/health)');
  await _probe(
    label: 'Auth health endpoint',
    url: '$baseUrl/auth/v1/health',
    headers: {'apikey': anonKey},
    expectStatus: 200,
    hint:
        'If this fails with 401/403, check your SUPABASE_ANON_KEY.\n'
        'If it fails with connection refused, check your SUPABASE_URL.',
  );

  // --- Probe 2: REST API reachability ---
  _section('Step 2 · REST API  (GET /rest/v1/)');
  await _probe(
    label: 'REST root endpoint',
    url: '$baseUrl/rest/v1/',
    headers: {'apikey': anonKey, 'Authorization': 'Bearer $anonKey'},
    expectStatus: 200,
    hint:
        'A 404 here means the project URL is wrong.\n'
        'A 401 means the anon key is invalid.',
  );

  // --- Probe 3: profiles table (RLS + schema) ---
  _section('Step 3 · Database Read  (GET /rest/v1/profiles?limit=1)');
  await _probe(
    label: 'profiles table accessible',
    url: '$baseUrl/rest/v1/profiles?limit=1',
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
      'Accept': 'application/json',
    },
    // Expecting either 200 (empty array — nobody signed in) or 401.
    // A 200 with [] is SUCCESS: table exists and RLS is enforcing correctly.
    // A 42P01 / 404 means the schema migration has NOT been run yet.
    expectStatus: 200,
    hint:
        'If you get {"code":"42P01"} the "profiles" table does not exist.\n'
        '→ Run the migration in your Supabase SQL Editor:\n'
        '  supabase/migrations/20240101000000_initial_schema.sql\n'
        '\n'
        'If you get a 401, no active session exists — that is NORMAL for\n'
        'an unauthenticated probe because RLS hides all rows.',
    allowedStatuses: {200, 401},
  );

  _printFooter();
}

// ---------------------------------------------------------------------------
// HTTP probe helper
// ---------------------------------------------------------------------------

Future<void> _probe({
  required String label,
  required String url,
  required Map<String, String> headers,
  required int expectStatus,
  String hint = '',
  Set<int> allowedStatuses = const {},
}) async {
  final effective = {expectStatus, ...allowedStatuses};

  stdout.write('  ⏳  $label … ');

  try {
    final request = await HttpClient().getUrl(Uri.parse(url));
    headers.forEach(request.headers.set);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    final status = response.statusCode;
    final ok = effective.contains(status);

    if (ok) {
      final preview = body.length > 120 ? '${body.substring(0, 120)}…' : body;
      _success('HTTP $status\n       Response: $preview');
    } else {
      _failure('HTTP $status (expected one of $effective)\n       Body: $body');
      if (hint.isNotEmpty) {
        _hint(hint);
      }
    }
  } on SocketException catch (e) {
    _failure('Network error: ${e.message}');
    _hint(
      'Cannot reach $url\n'
      'Check that SUPABASE_URL is correct and you have internet access.',
    );
  } on Object catch (e) {
    _failure('Unexpected error: $e');
  }
}

// ---------------------------------------------------------------------------
// .env file loader
// ---------------------------------------------------------------------------

Map<String, String> _loadEnv() {
  final candidates = [
    'studytrack/.env',
    '.env',
  ];

  for (final path in candidates) {
    final file = File(path);
    if (file.existsSync()) {
      _info('Reading env from: $path');
      final result = <String, String>{};
      for (final line in file.readAsLinesSync()) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final eq = trimmed.indexOf('=');
        if (eq < 0) continue;
        final key = trimmed.substring(0, eq).trim();
        final value = trimmed.substring(eq + 1).trim();
        result[key] = value;
      }
      return result;
    }
  }

  _info('No .env file found — falling back to process environment variables.');
  return Map<String, String>.from(Platform.environment);
}

// ---------------------------------------------------------------------------
// Output helpers
// ---------------------------------------------------------------------------

const _green = '\x1B[32m';
const _red = '\x1B[31m';
const _yellow = '\x1B[33m';
const _cyan = '\x1B[36m';
const _bold = '\x1B[1m';
const _reset = '\x1B[0m';

void _printHeader(String title) {
  print('');
  print('$_bold$_cyan══════════════════════════════════════════════════$_reset');
  print('$_bold  $title$_reset');
  print('$_bold$_cyan══════════════════════════════════════════════════$_reset');
  print('');
}

void _printFooter() {
  print('');
  print(
    '$_cyan──────────────────────────────────────────────────$_reset',
  );
  print(
    '  All probes complete.  If every step shows ✅ your app'
    ' can talk to Supabase.',
  );
  print(
    '  If any step shows ❌ follow the hint printed next to it.',
  );
  print('$_cyan──────────────────────────────────────────────────$_reset');
  print('');
}

void _section(String title) => print('\n$_bold  $title$_reset');
void _info(String msg) => print('  $_cyan$msg$_reset');
void _hint(String msg) {
  for (final line in msg.split('\n')) {
    print('  $_yellow  ↳ $line$_reset');
  }
}

void _check(String label, bool ok, String detail) {
  if (ok) {
    print('  $_green✅  $label$_reset — $detail');
  } else {
    print('  $_red❌  $label$_reset — $detail');
  }
}

void _success(String msg) => print('$_green✅  $msg$_reset');
void _failure(String msg) => print('$_red❌  $msg$_reset');
void _fatal(String msg) => stderr.writeln('$_red$_bold\nFATAL: $msg$_reset\n');
