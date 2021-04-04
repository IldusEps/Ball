{ Main "playing game" state, where most of the game logic takes place.

  Feel free to use this code as a starting point for your own projects.
  (This code is in public domain, unlike most other CGE code which
  is covered by the LGPL license variant, see the COPYING.txt file.) }
unit GameStatePlay;

interface

uses Classes,
  CastleUIState, CastleComponentSerialize, CastleUIControls, CastleControls,
  CastleKeysMouse, CastleViewport, CastleScene, CastleVectors, CastleCameras,
  CastleTransform,
  GameEnemy;

type
  { Main "playing game" state, where most of the game logic takes place. }

  { TStatePlay }

  TStatePlay = class(TUIState)
  private
    { Components designed using CGE editor, loaded from gamestateplay.castle-user-interface. }
    LabelFps: TCastleLabel;
    MainViewport: TCastleViewport;
    WalkNavigation: TCastleWalkNavigation;
    Player: TCastleScene;

    ButtonStart, ButtonStop: TCastleButton;
    FloatEdit_Velocity: TCastleFloatEdit;


    { Enemies behaviours }
    Enemies: TEnemyList;

    {Booleans}
    isStart: Boolean;
  public
    procedure Start; override;
    procedure Stop; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: Boolean); override;
    function Press(const Event: TInputPressRelease): Boolean; override;
    function Motion(const Event: TInputMotion): boolean; override;
    procedure PlayerCollisionEnter(const CollisionDetails: TPhysicsCollisionDetails);
    procedure ClickStart(Sender: TObject);
    procedure ClickStop(Sender: TObject);
  end;

var
  StatePlay: TStatePlay;

implementation

uses SysUtils, Math,
  CastleSoundEngine, CastleLog, CastleStringUtils, CastleFilesUtils,
  GameStateMenu;

{ TStatePlay ----------------------------------------------------------------- }

procedure TStatePlay.Start;
var
  UiOwner: TComponent;
  SoldierScene: TCastleScene;
  Enemy: TEnemy;
  I: Integer;
begin
  inherited;

  { Load designed user interface }
  InsertUserInterface('castle-data:/gamestateplay.castle-user-interface', FreeAtStop, UiOwner);

  { Find components, by name, that we need to access from code }
  LabelFps := UiOwner.FindRequiredComponent('LabelFps') as TCastleLabel;
  MainViewport := UiOwner.FindRequiredComponent('MainViewport') as TCastleViewport;
 // WalkNavigation := UiOwner.FindRequiredComponent('WalkNavigation') as TCastleWalkNavigation;
  ButtonStart:= UiOwner.FindRequiredComponent('Button1') as TCastleButton;
  ButtonStart.OnClick:= @ClickStart;
  ButtonStop:= UiOwner.FindRequiredComponent('Button2') as TCastleButton;
  ButtonStop.OnClick:= @ClickStop;
  FloatEdit_Velocity:= UiOwner.FindRequiredComponent('FloatEdit1') as TCastleFloatEdit;

  Player := UiOwner.FindRequiredComponent('Scene_') as TCastleScene;
  Player.AddBehavior(TMyPlayer.Create(Player));
  Player.RigidBody.OnCollisionEnter:= @PlayerCollisionEnter;

  { Create TEnemy instances, add them to Enemies list }
  Enemies := TEnemyList.Create(true);
  SoldierScene := UiOwner.FindRequiredComponent('Enemy2') as TCastleScene;
  { Below using nil as Owner of TEnemy, as the Enemies list already "owns"
    instances of this class, i.e. it will free them. }
  Enemy := TEnemy.Create(nil);
  SoldierScene.AddBehavior(Enemy);
  Enemies.Add(Enemy);
  LabelFps.Caption:= VectorToNiceStr(SoldierScene.LocalBoundingBox.Size);

  SoldierScene := UiOwner.FindRequiredComponent('Plane') as TCastleScene;
  //Enemy := TEnemy.Create(nil);
  //SoldierScene.AddBehavior(Enemy);

  For I:= 1 to 4 do
  begin
    SoldierScene := UiOwner.FindRequiredComponent('Enemy' + IntToStr(I)) as TCastleScene;
    { Below using nil as Owner of TEnemy, as the Enemies list already "owns"
      instances of this class, i.e. it will free them. }
    Enemy := TEnemy.Create(nil);
    SoldierScene.AddBehavior(Enemy);
    Enemies.Add(Enemy);
    LabelFps.Caption:= VectorToNiceStr(SoldierScene.LocalBoundingBox.Size);
  end;

  isStart:= False;
end;

procedure TStatePlay.Stop;
begin
  FreeAndNil(Enemies);
  inherited;
end;

procedure TStatePlay.Update(const SecondsPassed: Single; var HandleInput: Boolean);
begin
  inherited;
  { This virtual method is executed every frame.}
 // LabelFps.Caption := 'FPS: ' + Container.Fps.ToString;
end;

function TStatePlay.Press(const Event: TInputPressRelease): Boolean;
var
  HitEnemy: TEnemy;
  CameraPos, CameraDir, CameraUp: TVector3;
begin
  Result := inherited;
  if Result then Exit; // allow the ancestor to handle keys

  { This virtual method is executed when user presses
    a key, a mouse button, or touches a touch-screen.

    Note that each UI control has also events like OnPress and OnClick.
    These events can be used to handle the "press", if it should do something
    specific when used in that UI control.
    The TStatePlay.Press method should be used to handle keys
    not handled in children controls.
  }

  if Event.IsMouseButton(buttonLeft) then
  begin
    //SoundEngine.Sound(SoundEngine.SoundFromName('shoot_sound'));
    isStart:= True;
  end;

  if isStart then
  begin
    Player.StopAnimation;
    Player.Translation.Y := 0;
    MainViewport.Camera.GetView(CameraPos, CameraDir, CameraUp);
    Player.Gravity := True;
    Player.RigidBody.LinearVelocity := Vector3(0, 0, -(StrToFloat(FloatEdit_Velocity.Text)));
    isStart:= False;
    //MainViewport.Camera.Direction := Player.Translation;
    {MainViewport.Camera.SetView(Vector3(Player.Translation.X, Player.Translation.Y - 50, Player.Translation.Z - 1),
       Player.Translation,Vector3(0,1,0));}
  end;
//  if Event.IsKey(CtrlM) then
//  begin
//    WalkNavigation.MouseLook := not WalkNavigation.MouseLook;
//    Exit(true);
//  end;

  if Event.IsKey(keyF5) then
  begin
    Container.SaveScreenToDefaultFile;
    Exit(true);
  end;

  if Event.IsKey(keyEscape) then
  begin
    TUIState.Current := StateMenu;
    Exit(true);
  end;
end;

function TStatePlay.Motion(const Event: TInputMotion): boolean;
var
  CameraPos, CameraDir, CameraUp: TVector3;
begin
  Result:= inherited Motion(Event);
    MainViewport.Camera.GetView(CameraPos, CameraDir, CameraUp);
    Player.Translation:= CameraDir;
    //MainViewport.Camera.Direction := Player.Translation;
    {MainViewport.Camera.SetView(Vector3(Player.Translation.X, Player.Translation.Y - 50, Player.Translation.Z - 1),
       Player.Translation,Vector3(0,1,0));}
end;

procedure TStatePlay.PlayerCollisionEnter(
  const CollisionDetails: TPhysicsCollisionDetails);
begin
  if CollisionDetails.OtherTransform <> nil then
  begin
    LabelFps.Caption := 'ggg'+CollisionDetails.OtherTransform.Name;
    if CollisionDetails.OtherTransform.Name.IndexOf('Enemy') > -1 then
       if StrToInt(CollisionDetails.OtherTransform.Name[CollisionDetails.OtherTransform.Name.Length]) > 1 then
       begin
          isStart:= True;
          Player.Translation:= CollisionDetails.OtherTransform.Translation;
          Player.Translation.Y:= 10;
          Player.RigidBody.LinearVelocity:= Vector3(0, 0, 0);
          LabelFps.Caption := CollisionDetails.OtherTransform.Name[CollisionDetails.OtherTransform.Name.Length];
       end;
  end;
end;

procedure TStatePlay.ClickStart(Sender: TObject);
begin
    Player.Translation.Z:= -10;
    Player.Translation.Y:= 0;
    Player.Translation.X:= 0;
    Player.RigidBody.LinearVelocity:= Vector3(0, 0, 0);
    Player.PlayAnimation('start', true);
end;

procedure TStatePlay.ClickStop(Sender: TObject);
begin
  TUIState.Current:= StateMenu;
end;

end.
