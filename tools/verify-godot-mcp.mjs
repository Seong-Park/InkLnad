import { Client } from './godot-mcp/node_modules/@modelcontextprotocol/sdk/dist/esm/client/index.js';
import { StdioClientTransport } from './godot-mcp/node_modules/@modelcontextprotocol/sdk/dist/esm/client/stdio.js';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import path from 'node:path';

const root = path.resolve(import.meta.dirname, '..');
const project = path.join(root, 'godot');
const godot = process.env.GODOT_BIN ?? 'C:/Users/pjs93/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe';
const log = [];
let editor;
const client = new Client({name:'ink-land-verification',version:'1.0.0'});
const transport = new StdioClientTransport({command:process.execPath,args:[path.join(root,'tools/godot-mcp/dist/index.js')],env:{...process.env,GODOT_BIN:godot}});
async function call(name, args = {}, expectedError = false) {
  const result = await client.callTool({name,arguments:args});
  log.push({name,args,result});
  if (!!result.isError !== expectedError) throw new Error(`${name}: ${JSON.stringify(result)}`);
  console.log(`${name}: ${expectedError ? 'expected rejection' : 'OK'}`);
  return result;
}
function requireText(result, text) {
  if (!JSON.stringify(result).includes(text)) throw new Error(`Missing expected text: ${text}`);
}
try {
  await client.connect(transport);
  const inventory = await client.listTools();
  if (inventory.tools.length !== 20) throw new Error('Expected 20 tools');
  log.push({tools:inventory.tools.map(t=>t.name)});
  await call('list_project',{project_path:project});
  const scene = 'tests/environment/McpSmoke.tscn';
  await call('create_scene',{project_path:project,scene_path:scene,root_name:'McpSmoke',root_type:'Node',overwrite:true});
  await call('write_script',{project_path:project,script_path:'tests/environment/smoke.gd',content:'extends Node\n\nfunc _ready() -> void:\n\tif not get_parent().has_node("DiskProbe") or not get_parent().has_node("LiveProbe"):\n\t\tpush_error("Missing MCP probe nodes")\n\t\tget_tree().quit(1)\n\t\treturn\n\tprint("INK_LAND_MCP_SMOKE_PASS")\n\tget_tree().quit(0)\n'});
  await call('add_node',{project_path:project,scene_path:scene,parent_path:'.',name:'DiskProbe',type:'Node',script_path:'tests/environment/smoke.gd'});
  requireText(await call('read_scene',{project_path:project,scene_path:scene}),'DiskProbe');
  editor = spawn(godot,['--headless','--editor','--path',project],{stdio:['ignore','pipe','pipe']});
  editor.stdout.on('data',data=>log.push({editor_stdout:String(data)}));
  editor.stderr.on('data',data=>log.push({editor_stderr:String(data)}));
  await new Promise(resolve=>setTimeout(resolve,6000));
  requireText(await call('editor_ping'),'ed1daf0bf');
  await call('editor_open_scene',{scene_path:'res://'+scene});
  await new Promise(resolve=>setTimeout(resolve,1000));
  await call('editor_add_node',{parent_path:'.',name:'LiveProbe',type:'Node',scene_path:'res://'+scene});
  requireText(await call('editor_get_scene_tree'),'LiveProbe');
  await call('editor_save_scene');
  const saved = await readFile(path.join(project,scene),'utf8');
  if (!saved.includes('LiveProbe')) throw new Error('Live node not saved');
  const guard = await call('add_node',{project_path:project,scene_path:scene,parent_path:'.',name:'MustNotWrite',type:'Node'},true);
  requireText(guard,'desync');
  editor.kill();
  await new Promise(resolve=>editor.once('exit',resolve));
  editor = spawn(godot,['--headless','--editor','--path',project,'res://'+scene],{stdio:['ignore','pipe','pipe']});
  editor.stdout.on('data',data=>log.push({editor_stdout:String(data)}));
  editor.stderr.on('data',data=>log.push({editor_stderr:String(data)}));
  await new Promise(resolve=>setTimeout(resolve,6000));
  requireText(await call('editor_get_scene_tree'),'LiveProbe');
  const run = await call('run_headless',{project_path:project,scene_path:scene,timeout_ms:10000});
  requireText(run,'INK_LAND_MCP_SMOKE_PASS');
  requireText(run,'[exit code 0]');
  if (/SCRIPT ERROR|ERROR:/i.test(JSON.stringify(run))) throw new Error('Godot error in runtime');
  log.push({status:'PASS',godot_version:'4.7.2.stable.official.ed1daf0bf'});
} catch (error) {
  log.push({status:'FAIL',error:String(error)});
  console.error(error);
  process.exitCode = 1;
} finally {
  if (editor) editor.kill();
  await client.close();
  await mkdir(path.join(root,'docs/setup'),{recursive:true});
  await writeFile(path.join(root,'docs/setup/mcp-verification.json'),JSON.stringify(log,null,2)+'\n');
}

