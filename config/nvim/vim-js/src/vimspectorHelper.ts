import { commands, workspace } from 'coc.nvim'
import { getApi } from './api'
const { nvim } = workspace

debugger
const mapsConfig = {
  w: ['watches', 'goToWindow'],
  c: ['code', 'goToWindow'],
  s: ['stack_trace', 'goToWindow'],
  v: ['variables', 'goToWindow'],
  t: ['tabpage', 'goToWindow'],
  i: ['StepInto', 'func'],
  o: ['StepOut', 'func'],
  '\\': ['Continue', 'func'],
  q: ['Reset', 'func'], // quit
}

const mapsCaller = {
  func: (name, key) => nvim.command(`nmap ${key} :call vimspector#${name}()<cr>`),
  goToWindow: (name, key) => nvim.command(`nmap ${key} :win_gotoid(g:vimspector_session_windows.${name})<cr>`),
}

const maps = Object.entries(mapsConfig).map(([key, [val, cmd]]) => {
  const vimkey = `<C-${key}>`
  const setupFn = () => mapsCaller[cmd](val, vimkey)
  const saveMapEval = `['${vimkey}', maparg('${vimkey}', 'n')]`
  return {
    vimkey,
    setupFn,
    saveMapEval,
  }
})
async function setupMaps() {
  const api = await getApi()
  for (const { setupFn } of maps) {
    setupFn()
  }
}
// workspace.registerAutocmd({ event: 'User', pattern: 'VimspectorUICreated', request: true, callback: setupMaps })
commands.registerCommand('vim-js.vimspector.start', setupMaps)
// workspace.nvim.registerAutocmd('User VimspectorUICreated', setupMaps)
