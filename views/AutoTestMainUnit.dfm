object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Autotest 4 Delphi'
  ClientHeight = 123
  ClientWidth = 476
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  DesignSize = (
    476
    123)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 62
    Height = 13
    Caption = 'Test project:'
  end
  object Label2: TLabel
    Left = 8
    Top = 35
    Width = 93
    Height = 13
    Caption = 'Directory to watch:'
  end
  object Label3: TLabel
    Left = 8
    Top = 62
    Width = 97
    Height = 13
    Caption = 'Path to DCC32.exe:'
  end
  object TestProjectEdit: TEdit
    Left = 111
    Top = 5
    Width = 330
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
  end
  object StartStopButton: TButton
    Left = 393
    Top = 90
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Start'
    TabOrder = 1
    ExplicitLeft = 403
    ExplicitTop = 64
  end
  object SelectTestProjectButton: TButton
    Left = 447
    Top = 5
    Width = 21
    Height = 21
    Anchors = [akTop, akRight]
    Caption = '...'
    TabOrder = 2
    ExplicitLeft = 457
  end
  object AddWatchedDirectoryButton: TButton
    Left = 447
    Top = 32
    Width = 21
    Height = 21
    Anchors = [akTop, akRight]
    Caption = '...'
    TabOrder = 3
    ExplicitLeft = 457
  end
  object WatchedDirectoryEdit: TEdit
    Left = 111
    Top = 32
    Width = 330
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 4
  end
  object DCC32ExePathEdit: TEdit
    Left = 111
    Top = 59
    Width = 330
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 5
  end
  object SelectDCC32ExePathButton: TButton
    Left = 447
    Top = 59
    Width = 21
    Height = 21
    Anchors = [akTop, akRight]
    Caption = '...'
    TabOrder = 6
  end
  object PopupMenu1: TPopupMenu
    Left = 64
    Top = 64
    object MI_Start: TMenuItem
      Caption = 'Start'
    end
    object MI_Stop: TMenuItem
      Caption = 'Stop'
      Enabled = False
    end
    object MI_Show: TMenuItem
      Caption = 'Show'
      Enabled = False
    end
    object MI_Hide: TMenuItem
      Caption = 'Hide'
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object MI_Quit: TMenuItem
      Caption = 'Quit'
    end
  end
  object TrayIcon: TCoolTrayIcon
    CycleInterval = 0
    Icon.Data = {
      0000010002002020100000000000E80200002600000010101000000000002801
      00000E0300002800000020000000400000000100040000000000800200000000
      0000000000000000000000000000000000000000800000800000008080008000
      0000800080008080000080808000C0C0C0000000FF0000FF000000FFFF00FF00
      0000FF00FF00FFFF0000FFFFFF00000000000008770000078000000000000000
      0000070000000000007000000000000000070000077777700000700000000000
      00700078FFFFFFFF870007000000000087007FFF88871888FFF7007800000000
      7008FF822399999978FF800700000007008FF22239999999997FF80070000070
      08F82223999999999997FF80070000007F8222299993739999997FF700000700
      FF22223999377799999997FF00700007F8222239993773999999998F70008008
      F2222229999333999999997F8008707F82222223999999999999999FF007707F
      822222239999999999999998F707007F822222223999999999999998F700007F
      222222222233399999999998F700007F222222222222223399999998F700007F
      822222222222222239999998F700707F822222222222222223999998F700700F
      82222222222222222399999FF0078008F2222222223993222299997F80080007
      F8222222223999222299998F70000700FF22222222399322229998FF00700000
      7FF222222223322223997FF70000007008F82222222222222397FF8007000007
      008FF22222222222398FF800700000007008FF822222222378FF800700000000
      07007FFFF888888FFFF700700000000000700078FFFFFFFF8700070000000000
      0007000077777770000070000000000000000700000000000070000000000000
      0000000877000077800000000000FFE007FFFF8001FFFE00007FFC00003FF000
      000FF000000FE0000007C0000003C00000038000000180000001000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00008000000180000001C0000003C0000003E0000007F000000FF800001FFC00
      003FFE00007FFF8001FFFFE007FF280000001000000020000000010004000000
      0000C00000000000000000000000000000000000000000000000000080000080
      00000080800080000000800080008080000080808000C0C0C0000000FF0000FF
      000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00000008AAA98000000008
      AA399999800000AAA9999999990008AAA999999999800AAA3999999999908AAA
      A99999999998AAAAA29999999999AAAAAAA339999999AAAAAAAAAA399999AAAA
      AAAAAAA399998AAAAAAAAAAA99980AAAAAAAAAAA399008AAAAAAAAAA998000AA
      AAAAAAA399000008AAAAAAA98000000008AAA3700000F81F0000E0070000C003
      0000800100008001000000000000000000000000000000000000000000000000
      00008001000080010000C0030000E0070000F81F0000}
    IconVisible = True
    IconIndex = 0
    PopupMenu = PopupMenu1
    LeftPopup = True
    Left = 24
    Top = 64
  end
end
