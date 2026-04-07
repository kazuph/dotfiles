/**
 * vm-coding-agent.js — V8サンドボックス内ツールエグゼキューター
 *
 * ホストから __CONFIG__.tools を受け取り、サンドボックス内でツールを実行して結果を返す。
 * API呼び出しはホスト側で行い、ここではファイル操作・コマンド実行のみ担当。
 *
 * Input:  var __CONFIG__ = { tools: [{name, arguments}] }
 * Output: stdout → JSON { results: [{name, result}] }
 *
 * Host prepends: var __CONFIG__ = JSON.parse('...');
 */

var fs = null, pathMod = null, cp = null;
try { fs = require('fs'); } catch(e) {}
try { pathMod = require('path'); } catch(e) {}
try { cp = require('child_process'); } catch(e) {}

var config = (typeof __CONFIG__ !== 'undefined') ? __CONFIG__ : {};
var tools = config.tools || [];
var WS = '/workspace';

function resolvePath(p) {
  if (!p) return WS;
  if (p.startsWith('/')) return p;
  return pathMod ? pathMod.join(WS, p) : WS + '/' + p;
}

function executeTool(name, args) {
  switch (name) {
    case 'read_file': {
      if (!fs) return 'Error: filesystem not available in sandbox';
      return fs.readFileSync(resolvePath(args.path), 'utf-8');
    }
    case 'write_file': {
      if (!fs) return 'Error: filesystem not available in sandbox';
      var p = resolvePath(args.path);
      var dir = pathMod ? pathMod.dirname(p) : p.substring(0, p.lastIndexOf('/'));
      try { fs.mkdirSync(dir, { recursive: true }); } catch(e) {}
      fs.writeFileSync(p, args.content);
      return 'Written: ' + args.path + ' (' + args.content.length + ' bytes)';
    }
    case 'list_directory': {
      if (!fs) return 'Error: filesystem not available in sandbox';
      var entries = fs.readdirSync(resolvePath(args.path || ''), { withFileTypes: true });
      return entries.map(function(e) {
        return e.isDirectory() ? e.name + '/' : e.name;
      }).join('\n');
    }
    case 'execute_command': {
      if (!cp) return 'Error: command execution not available in sandbox';
      try {
        var cmd = args.command;
        cmd = cmd.replace(/^(node\s+)(?!\/)(\S+)/, '$1/workspace/$2');
        var result = cp.execSync(cmd, {
          encoding: 'utf-8', timeout: 60000, maxBuffer: 2 * 1024 * 1024,
        });
        return result || '(no output)';
      } catch (e) {
        var errMsg = e.stderr || e.stdout || e.message || '';
        if (errMsg.includes('Command failed') && !args.command.startsWith('node')) {
          return 'Error: "' + args.command.split(' ')[0] + '" not available in sandbox. Use read_file/write_file/list_directory/search_text tools instead, or use "node -e ..." for JavaScript execution.';
        }
        return 'Error (exit ' + (e.status || '?') + '):\n' + errMsg;
      }
    }
    case 'search_text': {
      if (!fs) return 'Error: filesystem not available in sandbox';
      var results = [];
      function search(dir, depth) {
        if (depth > 5 || results.length >= 50) return;
        var entries;
        try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch(e) { return; }
        for (var i = 0; i < entries.length; i++) {
          var e = entries[i];
          if (e.name.startsWith('.') || e.name === 'node_modules' || e.name === 'dist') continue;
          var full = dir + '/' + e.name;
          if (e.isDirectory()) { search(full, depth + 1); continue; }
          if (!e.isFile()) continue;
          try {
            var content = fs.readFileSync(full, 'utf-8');
            var lines = content.split('\n');
            for (var j = 0; j < lines.length; j++) {
              if (lines[j].indexOf(args.pattern) >= 0) {
                var rel = full.substring(WS.length + 1);
                results.push(rel + ':' + (j + 1) + ': ' + lines[j].trim());
                if (results.length >= 50) return;
              }
            }
          } catch(e2) {}
        }
      }
      search(resolvePath(args.path || ''), 0);
      return results.length ? results.join('\n') : 'No matches found';
    }
    default:
      return 'Unknown tool: ' + name;
  }
}

// Execute all requested tools and return results
var results = [];
for (var i = 0; i < tools.length; i++) {
  var tc = tools[i];
  var result;
  try {
    result = executeTool(tc.name, tc.arguments);
  } catch (e) {
    result = 'Error: ' + e.message;
  }
  results.push({ name: tc.name, result: result });
}

process.stdout.write(JSON.stringify({ results: results }));
