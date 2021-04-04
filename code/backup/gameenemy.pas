{ Enemy behaviour.

  Feel free to use this code as a starting point for your own projects.
  (This code is in public domain, unlike most other CGE code which
  is covered by the LGPL license variant, see the COPYING.txt file.) }
unit GameEnemy;

interface

uses Classes, Generics.Collections,
  CastleVectors, CastleWindow, CastleScene, CastleControls, CastleLog, X3DNodes, CastleTransform,
  CastleFilesUtils, CastleSceneCore, CastleKeysMouse, CastleColors,
  CastleCameras,  CastleBoxes, CastleViewport,
  CastleUIControls, CastleApplicationProperties, CastleDebugTransform;

type

  { TMyPlayer }

  TMyPlayer = class(TCastleBehavior)
  strict private
    Scene: TCastleScene;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ParentChanged; override;
    procedure Update(const SecondsPassed: Single; var RemoveMe: TRemoveType); override;
  end;

type
  { Simple enemy intelligence.
    It controls the parent Scene (TCastleScene): moves it, runs animations of it etc.

    This is a TCastleBehavior descendant,
    and is inserted to parent like EnemyScene.AddBehaviour(...).
    You can get the TEnemy instance of a TCastleScene,
    by taking "Scene.FindBehavior(TEnemy)".

    Other ways of making an association TCastleScene <-> TEnemy logic are possible:

    - TEnemy could be an independent class (not connected to any CGE class),
      and simply have a reference to CGE TCastleScene instance.

      This makes it easy to map TEnemy->TCastleScene.
      To map TCastleScene->TEnemy you could e.g. use TCastleScene.Tag,
      or a dedicated map structure like TDictionary from Generics.Collections.

    - You could also make TEnemy a descendant of TCastleScene.

    Note that TCastleBehavior or TCastleTransform descendants could be
    registered in the CGE editor to visually add and edit them from editor.
    See https://castle-engine.io/manual_editor.php#section_custom_components .
    In this unit we call RegisterSerializableComponent,
    so you only need to add editor_units="GameEnemy" to CastleEngineManifest.xml to see it in action.
  }
  TEnemy = class(TCastleBehavior)
  strict private
    Scene: TCastleScene;
    MoveDirection: Integer; //< Always 1 or -1
    Dead: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ParentChanged; override;
    procedure Update(const SecondsPassed: Single; var RemoveMe: TRemoveType); override;
    procedure Hurt;
  end;

  TEnemyList = specialize TObjectList<TEnemy>;

implementation

uses CastleComponentSerialize;

{ TMyPlayer }

constructor TMyPlayer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

procedure TMyPlayer.ParentChanged;
var
  PlayerBody: TRigidBody;
  Collider: TBoxCollider;
begin
  inherited ParentChanged;
  Scene := Parent as TCastleScene; // TEnemy can only be added as behavior to TCastleScene
  Scene.PlayAnimation('start', true);
  PlayerBody := TRigidBody.Create(Scene);
  PlayerBody.Dynamic := True;
  PlayerBody.Gravity:= True;
  PlayerBody.Animated:= True;

  Collider := TBoxCollider.Create(PlayerBody);
  Collider.Size := Scene.BoundingBox.Size;
  Collider.Restitution := 0.3;
  Collider.Mass:= 1;

  Scene.RigidBody := PlayerBody;
end;

procedure TMyPlayer.Update(const SecondsPassed: Single;
  var RemoveMe: TRemoveType);
begin
  inherited Update(SecondsPassed, RemoveMe);
end;

constructor TEnemy.Create(AOwner: TComponent);
begin
  inherited;
  MoveDirection := -1;
end;

procedure TEnemy.ParentChanged;
var
  RigidBody: TRigidBody;
  Collider: TBoxCollider;
   Debug: TDebugTransformBox;
begin
  inherited;
  Scene := Parent as TCastleScene; // TEnemy can only be added as behavior to TCastleScene
  if Scene.Exists then
  begin
    RigidBody := TRigidBody.Create(Scene);
    RigidBody.Gravity := false;
    RigidBody.Dynamic := false;

    Collider := TBoxCollider.Create(RigidBody);
    Collider.Size := Vector3(Scene.BoundingBox.SizeX, Scene.LocalBoundingBox.SizeY, Scene.BoundingBox.SizeZ);
    Collider.Mass:= 1;
    Collider.Restitution := 0.3;
  end;
  Debug := TDebugTransformBox.Create(Application);
  Debug.Attach(Scene);
  Debug.Exists := true;

  Scene.RigidBody := RigidBody;
end;

procedure TEnemy.Update(const SecondsPassed: Single; var RemoveMe: TRemoveType);
const
  MovingSpeed = 2;
begin
  inherited;

  // We modify the Z coordinate, responsible for enemy going forward
  {Scene.Translation := Scene.Translation +
    Vector3(0, 0, MoveDirection * SecondsPassed * MovingSpeed);

  Scene.Direction := Vector3(0, 0, MoveDirection);
   }
  // Toggle MoveDirection between 1 and -1
  //if Scene.Translation.Z > 5 then
   // MoveDirection := -1
  //else
  ///if Scene.Translation.Z < -5 then
    //MoveDirection := 1;
end;

procedure TEnemy.Hurt;
begin
  Scene.Pickable := false;
  Scene.Collides := false;
end;

initialization
  RegisterSerializableComponent(TEnemy, 'Enemy');
end.
