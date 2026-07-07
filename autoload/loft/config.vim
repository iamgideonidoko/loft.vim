vim9script

def DeepMerge(base: dict<any>, user: dict<any>): dict<any>
  var merged = deepcopy(base)
  for [key, value] in items(user)
    if has_key(merged, key) && type(merged[key]) == v:t_dict && type(value) == v:t_dict
      merged[key] = DeepMerge(merged[key], value)
    else
      merged[key] = deepcopy(value)
    endif
  endfor
  return merged
enddef

export def Defaults(): dict<any>
  return {
    close_invalid_buf_on_switch: true,
    enable_smart_order_by_default: true,
    smart_order_marked_bufs: false,
    smart_order_alt_bufs: true,
    smart_order_on_window_switch: false,
    enable_recent_marked_mapping: true,
    post_leader_marked_mapping: 'l',
    show_marked_mapping_num: true,
    marked_mapping_num_style: 'solid',
    ui_timeout_on_curr_buf_move: 800,
    reverse_order: false,
    confirm_force_delete: true,
    allow_delete_current_buffer: true,
    auto_delete_missing_file_bufs: true,
    exclude_buftypes: [],
    open_at: 'current',
    window: {
      width: v:none,
      height: v:none,
      row: v:none,
      col: v:none,
      row_offset: 0,
      col_offset: 0,
      title: v:none,
      title_pos: 'center',
      footer: v:none,
      footer_pos: 'center',
      zindex: 100,
      border: 'rounded',
    },
    help_window: {
      disable: false,
      width: v:none,
      height: v:none,
      row: v:none,
      col: v:none,
      row_offset: 0,
      col_offset: 0,
      border: v:none,
      zindex: v:none,
    },
    keymaps: {
      ui: {
        k: 'move_up',
        j: 'move_down',
        '<C-k>': 'move_entry_up',
        '<C-j>': 'move_entry_down',
        dd: 'delete_entry',
        D: 'force_delete_entry',
        '<CR>': 'select_entry',
        '<Esc>': 'close',
        q: 'close',
        m: 'toggle_mark_entry',
        '<C-s>': 'toggle_smart_order',
        '?': 'show_help',
        '<M-k>': 'move_up_to_marked_entry',
        '<M-j>': 'move_down_to_marked_entry',
      },
      ui_visual: {
        d: 'delete_selected_entries',
        D: 'force_delete_selected_entries',
      },
      general: {
        '<leader>lf': {
          kind: 'open_loft',
          desc: 'Open Loft',
        },
        '<Tab>': {
          kind: 'switch_to_next_buffer',
          desc: 'Switch to next buffer',
        },
        '<S-Tab>': {
          kind: 'switch_to_prev_buffer',
          desc: 'Switch to previous buffer',
        },
        '<leader>x': {
          kind: 'close_buffer',
          desc: 'Close buffer',
        },
        '<leader>X': {
          kind: 'force_close_buffer',
          desc: 'Force close buffer',
        },
        '<leader>ln': {
          kind: 'switch_to_next_marked_buffer',
          desc: 'Switch to next marked buffer',
        },
        '<leader>lp': {
          kind: 'switch_to_prev_marked_buffer',
          desc: 'Switch to previous marked buffer',
        },
        '<leader>lm': {
          kind: 'toggle_mark_current_buffer',
          desc: 'Toggle mark current buffer',
        },
        '<leader>ls': {
          kind: 'toggle_smart_order',
          desc: 'Toggle smart order',
        },
        '<leader>la': {
          kind: 'switch_to_alt_buffer',
          desc: 'Switch to alternate buffer',
        },
        '<S-M-i>': {
          kind: 'move_buffer_up',
          desc: 'Move buffer up',
        },
        '<S-M-o>': {
          kind: 'move_buffer_down',
          desc: 'Move buffer down',
        },
      },
    },
    persistence: {
      enabled: false,
      path: v:none,
    },
  }
enddef

export def Merge(opts: dict<any>): dict<any>
  return DeepMerge(loft#config#Defaults(), opts)
enddef
