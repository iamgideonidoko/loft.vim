vim9script

var state = {
  initialized: false,
  config: {},
  registry: [],
  update_paused: false,
  update_paused_once: false,
  is_smart_order_on: true,
  prev_winid: 0,
  stat_cache: {},
  recent_mark_keys: [],
  recent_mark_prefix: '',
  general_mapping_keys: [],
  general_mapping_keys_prev: [],
  general_mappings: {},
  main_popup: 0,
  main_bufnr: -1,
  help_popup: 0,
  help_bufnr: -1,
  last_win_before_loft: 0,
  last_buf_before_loft: -1,
  saved_cursor_line: 0,
  visual_anchor: 0,
  pending_keys: '',
  count_prefix: '',
  move_timer: -1,
  help_content_height: 0,
  event_data: {},
}

export def Get(): dict<any>
  return state
enddef
