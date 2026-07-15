{
  system-config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    vmpk
  ];
  xdg.configFile."vmpk.sourceforge.net/VMPK.conf".text = ''
    [Connections]
    AdvancedEnabled=false
    InEnabled=true
    InPort=21928
    InputDriver=Network
    OmniEnabled=false
    OutPort=FluidSynth
    OutputDriver=FluidSynth
    ThruEnabled=true
  ''
  + builtins.concatStringsSep "\n" (
    map (i: ''
      [Controllers${toString i}]
      1=0
      10=64
      11=127
      2=0
      4=0
      5=0
      64=0
      65=0
      66=0
      67=0
      69=0
      7=100
      8=0
      91=127
      92=0
      93=0
      94=0
      95=0
    '') (lib.lists.range 0 15)
  )
  + ''
    [DrumstickRT]
    PublicNameIN=VMPK Input
    PublicNameOUT=VMPK Output

    [ExtraControllers]
    00="Soft,67,0,0,64,0,"
    01="Sostenuto,66,0,0,64,0,"
    02="Sustain,64,0,0,64,0,"

    [FluidSynth]
    AudioDriver=pulseaudio
    BufferTime=21
    Chorus=1
    Gain=1
    InstrumentsDefinition=${pkgs.soundfont-fluid}/share/soundfonts/FluidR3_GM2-2.sf2
    PeriodSize=128
    Periods=8
    Polyphony=256
    Reverb=1
    SampleRate=48000
    chorus_depth=4.25
    chorus_level=0.6
    chorus_nr=3
    chorus_speed=0.2
    reverb_damp=0.3
    reverb_level=0.7
    reverb_size=0.5
    reverb_width=0.8
  ''
  + builtins.concatStringsSep "\n" (
    map (i: ''
      [Instrument${toString i}]
      Bank=-1
      Controller=1
      Program=1
    '') (lib.lists.range 0 15)
  )
  + ''
    [Keyboard]
    MapFile=default
    RawKeyboardMode=false
    RawMapFile=default

    [Network]
    address=225.0.0.37
    interface=
    ipv6=false

    [Palette_0]
    1\color=@Variant(\0\0\0\x43\x1\xff\xff\x30\x30\x8c\x8c\xc6\xc6\0\0)
    size=1

    [Palette_1]
    1\color=@Variant(\0\0\0\x43\x1\xff\xff\x30\x30\x8c\x8c\xc6\xc6\0\0)
    2\color=@Variant(\0\0\0\x43\x1\xff\xff||\xfc\xfc\0\0\0\0)
    size=2

    [Palette_2]
    1\color=@Variant(\0\0\0\x43\x1\xff\xff\xff\xff\0\0\0\0\0\0)
    10\color=@Variant(\0\0\0\x43\x1\xff\xff\x30\x30\x8c\x8c\xc6\xc6\0\0)
    11\color=@Variant(\0\0\0\x43\x1\xff\xff\0\0\x80\x80\x80\x80\0\0)
    12\color=@Variant(\0\0\0\x43\x1\xff\xff\xd2\xd2ii\x1e\x1e\0\0)
    13\color=@Variant(\0\0\0\x43\x1\xff\xff\xff\xff\0\0\xff\xff\0\0)
    14\color=@Variant(\0\0\0\x43\x1\xff\xffkk\x8e\x8e##\0\0)
    15\color=@Variant(\0\0\0\x43\x1\xff\xff\0\0\xff\xff\xff\xff\0\0)
    16\color=@Variant(\0\0\0\x43\x1\xff\xff\xad\xad\xff\xff//\0\0)
    2\color=@Variant(\0\0\0\x43\x1\xff\xff\0\0\xff\xff\0\0\0\0)
    3\color=@Variant(\0\0\0\x43\x1\xff\xff\0\0\0\0\xff\xff\0\0)
    4\color=@Variant(\0\0\0\x43\x1\xff\xff\xff\xff\xd7\xd7\0\0\0\0)
    5\color=@Variant(\0\0\0\x43\x1\xff\xff\x80\x80\0\0\0\0\0\0)
    6\color=@Variant(\0\0\0\x43\x1\xff\xff\0\0\x80\x80\0\0\0\0)
    7\color=@Variant(\0\0\0\x43\x1\xff\xff\0\0\0\0\x80\x80\0\0)
    8\color=@Variant(\0\0\0\x43\x1\xff\xff\xff\xff\x8c\x8c\0\0\0\0)
    9\color=@Variant(\0\0\0\x43\x1\xff\xff\x80\x80\0\0\x80\x80\0\0)
    size=16

    [Palette_3]
    1\color=@Variant(\0\0\0\x43\x1\xff\xff\xff\xff\0\0\0\0\0\0)
    10\color=@Variant(\0\0\0\x43\x1\xff\xff\x7f\x7f\0\0\xff\xff\0\0)
    11\color=@Variant(\0\0\0\x43\x1\xff\xff\xff\xff\0\0\xff\xff\0\0)
    12\color=@Variant(\0\0\0\x43\x1\xff\xff\xff\xff\0\0\x7f\x7f\0\0)
    2\color=@Variant(\0\0\0\x43\x1\xff\xff\xff\xff\x7f\x7f\0\0\0\0)
    3\color=@Variant(\0\0\0\x43\x1\xff\xff\xff\xff\xff\xff\0\0\0\0)
    4\color=@Variant(\0\0\0\x43\x1\xff\xff\x7f\x7f\xff\xff\0\0\0\0)
    5\color=@Variant(\0\0\0\x43\x1\xff\xff\0\0\xff\xff\0\0\0\0)
    6\color=@Variant(\0\0\0\x43\x1\xff\xff\0\0\xff\xff\x7f\x7f\0\0)
    7\color=@Variant(\0\0\0\x43\x1\xff\xff\0\0\xff\xff\xff\xff\0\0)
    8\color=@Variant(\0\0\0\x43\x1\xff\xff\0\0\x7f\x7f\xff\xff\0\0)
    9\color=@Variant(\0\0\0\x43\x1\xff\xff\0\0\0\0\xff\xff\0\0)
    size=12

    [Palette_4]
    1\color=@Variant(\0\0\0\x43\x1\xff\xff\xff\xff\xff\xff\xff\xff\0\0)
    2\color=@Variant(\0\0\0\x43\x1\xff\xff\0\0\0\0\0\0\0\0)
    size=2

    [Palette_5]
    1\color=@Variant(\0\0\0\x43\x1\xff\xff\0\0\0\0\0\0\0\0)
    2\color=@Variant(\0\0\0\x43\x1\xff\xff\xff\xff\xff\xff\xff\xff\0\0)
    3\color=@Variant(\0\0\0\x43\x1\xff\xff\xff\xff\xff\xff\xff\xff\0\0)
    4\color=@Variant(\0\0\0\x43\x1\xff\xff\xff\xff\xff\xff\xff\xff\0\0)
    size=4

    [Palette_6]
    1\color=@Variant(\0\0\0\x43\x1\xff\xff\xff\xff\0\0\0\0\0\0)
    10\color=@Variant(\0\0\0\x43\x1\xff\xff\x7f\x7f\0\0\xff\xff\0\0)
    11\color=@Variant(\0\0\0\x43\x1\xff\xff\xff\xff\0\0\xff\xff\0\0)
    12\color=@Variant(\0\0\0\x43\x1\xff\xff\xff\xff\0\0\x7f\x7f\0\0)
    2\color=@Variant(\0\0\0\x43\x1\xff\xff\xff\xff\x7f\x7f\0\0\0\0)
    3\color=@Variant(\0\0\0\x43\x1\xff\xff\xff\xff\xff\xff\0\0\0\0)
    4\color=@Variant(\0\0\0\x43\x1\xff\xff\x7f\x7f\xff\xff\0\0\0\0)
    5\color=@Variant(\0\0\0\x43\x1\xff\xff\0\0\xff\xff\0\0\0\0)
    6\color=@Variant(\0\0\0\x43\x1\xff\xff\0\0\xff\xff\x7f\x7f\0\0)
    7\color=@Variant(\0\0\0\x43\x1\xff\xff\0\0\xff\xff\xff\xff\0\0)
    8\color=@Variant(\0\0\0\x43\x1\xff\xff\0\0\x7f\x7f\xff\xff\0\0)
    9\color=@Variant(\0\0\0\x43\x1\xff\xff\0\0\0\0\xff\xff\0\0)
    size=12

    [Preferences]
    AlwaysOnTop=false
    BaseOctave=6
    Channel=1
    CurrentPalette=0
    DrumsChannel=9
    EnableKeyboardInput=true
    EnableMouseInput=true
    EnableTouchInput=false
    EnforceChannelState=false
    ForcedDarkMode=false
    InstrumentName=General MIDI
    InstrumentsDefinition=:/vpiano/gmgsxg.ins
    Language=
    NumKeys=88
    QtStyle=
    ShowColorScale=false
    ShowStatusBar=false
    StartingKey=9
    Transpose=0
    Velocity=100
    VelocityColor=true

    [Shortcuts]
    actionChannelDown=Down
    actionChannelUp=Up
    actionContents=F1
    actionControllerDown=Alt+-
    actionControllerUp=Alt++
    actionNextBank=Ctrl+PgUp
    actionNextController=Ctrl++
    actionNextProgram=PgUp
    actionOctaveDown=Left
    actionOctaveUp=Right
    actionPanic=Esc
    actionPreviousBank=Ctrl+PgDown
    actionPreviousController=Ctrl+-
    actionPreviousProgram=PgDown
    actionTransposeDown=Ctrl+Left
    actionTransposeUp=Ctrl+Right
    actionVelocityDown=Home
    actionVelocityUp=End

    [SonivoxEAS]
    BufferTime=60
    ChorusAmt=0
    ChorusType=-1
    InstrumentsDefinition=
    ReverbAmt=25800
    ReverbType=1

    [TextSettings]
    namesAlteration=0
    namesFont="Helvetica,50"
    namesOctave=1
    namesOrientation=0
    namesVisibility=1
    octaveSubscript=true

    [Window]
    Geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\a\x80\0\0\0\0\0\0\v\x84\0\0\x3\xf3\0\0\a\x80\0\0\0\0\0\0\v\x84\0\0\x3\xf3\0\0\0\0\0\0\0\0\a\x80\0\0\a\x80\0\0\0\0\0\0\v\x84\0\0\x3\xf3)
    State=@ByteArray(\0\0\0\xff\0\0\0\0\xfd\0\0\0\0\0\0\x4\x5\0\0\x3\x91\0\0\0\x4\0\0\0\x4\0\0\0\b\0\0\0\b\xfc\0\0\0\x2\0\0\0\x2\0\0\0\x2\0\0\0\x18\0t\0o\0o\0l\0\x42\0\x61\0r\0N\0o\0t\0\x65\0s\x1\0\0\0\0\xff\xff\xff\xff\0\0\0\0\0\0\0\0\0\0\0\x1e\0t\0o\0o\0l\0\x42\0\x61\0r\0P\0r\0o\0g\0r\0\x61\0m\0s\x1\0\0\x2\xf\xff\xff\xff\xff\0\0\0\0\0\0\0\0\0\0\0\x2\0\0\0\x4\0\0\0$\0t\0o\0o\0l\0\x42\0\x61\0r\0\x43\0o\0n\0t\0r\0o\0l\0l\0\x65\0r\0s\x1\0\0\0\0\xff\xff\xff\xff\0\0\0\0\0\0\0\0\0\0\0\x18\0t\0o\0o\0l\0\x42\0\x61\0r\0\x45\0x\0t\0r\0\x61\x1\0\0\x1\xa6\xff\xff\xff\xff\0\0\0\0\0\0\0\0\0\0\0\x1a\0t\0o\0o\0l\0\x42\0\x61\0r\0\x42\0\x65\0n\0\x64\0\x65\0r\x1\0\0\x2\xda\xff\xff\xff\xff\0\0\0\0\0\0\0\0\0\0\0\x1e\0t\0o\0o\0l\0\x42\0\x61\0r\0S\0\x65\0t\0t\0i\0n\0g\0s\x1\0\0\x3\xb3\xff\xff\xff\xff\0\0\0\0\0\0\0\0)
  '';
}
