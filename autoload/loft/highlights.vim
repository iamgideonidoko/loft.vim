vim9script

def AddPropType(name: string, group: string): void
  if empty(prop_type_get(name))
    prop_type_add(name, {
      highlight: group,
    })
  endif
enddef

export def Setup(): void
  highlight default link LoftCurrentBuffer PmenuSel
  highlight default link LoftMarkedBuffer DiffAdd
  highlight default link LoftMark DiagnosticInfo
  highlight default link LoftCurrentIndicator Statement
  highlight default link LoftModified DiagnosticWarn
  highlight default link LoftBufferNumber Comment
  AddPropType('LoftCurrentBufferProp', 'LoftCurrentBuffer')
  AddPropType('LoftMarkedBufferProp', 'LoftMarkedBuffer')
  AddPropType('LoftMarkProp', 'LoftMark')
  AddPropType('LoftCurrentIndicatorProp', 'LoftCurrentIndicator')
  AddPropType('LoftModifiedProp', 'LoftModified')
  AddPropType('LoftBufferNumberProp', 'LoftBufferNumber')
  AddPropType('LoftVisualSelectionProp', 'Visual')
enddef
