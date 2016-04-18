unit uEngine2D;

{******************************************************************************
Shadow Object Engine (SO Engine)
By Dmitriy Sorokin.

Some comments in English, some in Russian. And it depends on mood :-) Sorry!)
*******************************************************************************}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Platform,
  FMX.Objects, Math, System.SyncObjs, {$I 'Utils\DelphiCompatability.inc'}
  uClasses, uEngine2DThread, uEngine2DObject, uEngine2DUnclickableObject,
  uEngine2DSprite, uEngine2DText, uEngine2DClasses, uFormatterList, uEngineFormatter,
  uSpriteList, uEngine2DObjectCreator,
  uEngine2DResources, uEngine2DAnimation, uNamedList, uEngine2DAnimationList,
  uFastFields, uEasyDevice;

type

  tEngine2d = class
  strict private
    fEngineThread: tEngineThread; // ����� � ������� ���������� ���������
    fOptions: TEngine2DOptions; // ��������� ������
    fObjects: TObjectsList; // ������ �������� ��� ���������
    fFastFields: tFastFields; // �������� ������ �� TFastField, ������� ������������ ����� ��������� �������� ������������ ��������
    fSpriteOrder: array of Integer; // ������ ������� ���������. ����� ��� ���������� ���-�� ����������, �������� ����� �������
    fResources: TEngine2DResources;//tResourceArray; // ������ ��������
    fFormatters: TFormatterList; // ������ ����������� ��������
    fAnimationList: TEngine2DAnimationList; // ������ ��������
    fObjectCreator: TEngine2DObjectCreator;
    fMouseDowned: TIntArray; // ������ �������� ������, ������� ���������� ��� ������ � ������ �������
    fMouseUpped: TIntArray; // ������ �������� ������, ������� ���������� ��� ������ � ������ �������
    fClicked: TIntArray; // ������ �������� ������, ������� ������ ��� ����
    fStatus: byte; // ��������� ������ 0-�����, 1-������
    flX, flY: single; // o_O ��� ��������������� �� ��������� ���-��
    FIsMouseDowned: Boolean; // ������ ��������� ��������� ����
    fImage: tImage; // �����, � ������� ���������� ���������
    fBackGround: tBitmap; // ���������. ������ �������� � Repaint �� ���� fImage
    fCritical: TCriticalSection; // ����������� ������ ������
    fWidth, fHeight: integer; // ������ ���� ������ � ������
    fDebug: Boolean; // �� ����� �����, �� �������� ���������� �� �����, ����� ��������� ����� ���������� ������
    FBackgroundBehavior: TProcedure;
    FInBeginPaintBehavior: TProcedure;
    FInEndPaintBehavior: TProcedure;
    FAddedSprite: Integer; // ������� ������� �������� ��������� �����. ��� ����� ��������

    // �������� �������� ������� ��������. �� ����� ����� ������� TEngine2DObject �� ����� �������� �����������
    {FShadowSprite: tSprite; //
    FShadowText: TEngine2dText; }
    FShadowObject: tEngine2DObject;

    procedure prepareFastFields;
    procedure prepareShadowObject;
    procedure setStatus(newStatus: byte);
    procedure setObject(index: integer; newSprite: tEngine2DObject);
    function getObject(index: integer): tEngine2DObject;
    function getSpriteCount: integer; // ����� ������ fSprites
    procedure SetWidth(AWidth: integer); // ��������� ������� ���� ��������� ������
    procedure SetHeight(AHeight: integer); // ��������� ������� ���� ��������� ������
    procedure setBackGround(ABmp: tBitmap);

    procedure BackgroundDefaultBehavior;
    procedure InBeginPaintDefaultBehavior;
    procedure InEndPaintDefaultBehavior;

    procedure SetBackgroundBehavior(const Value: TProcedure);
    procedure BringToBackHandler(ASender: TObject);
    procedure SendToFrontHandler(ASender: TObject);
  protected
      // �������� ������ ������
    property Resources: TEngine2DResources read FResources;
    property AnimationList: TEngine2DAnimationList read fAnimationList;
    property FormatterList: TFormatterList read fFormatters;
    property SpriteList: TObjectsList read fObjects;
    property FastFields: tFastFields read FFastFields; // ������� ����� ��� ������������
  public
    // �������� �������� ������
    property EngineThread: TEngineThread read fEngineThread;
    property Image: TImage read FImage write FImage;
    property BackgroundBehavior: TProcedure read FBackgroundBehavior write SetBackgroundBehavior;
    property InBeginPaintBehavior: TProcedure read FInBeginPaintBehavior write FInBeginPaintBehavior;
    property InEndPaintBehavior: TProcedure read FInBeginPaintBehavior write FInBeginPaintBehavior;

    property IsMouseDowned: Boolean read FIsMouseDowned;
    property Status: byte read fStatus write setStatus;
    property Width: integer read fWidth write setWidth;
    property Height: integer read fHeight write setHeight;

    property Clicked: tIntArray read fClicked;
    property Downed: TIntArray read fMouseDowned;
    property Upped: TIntArray read fMouseUpped;
    property Critical: TCriticalSection read FCritical;
    property New: TEngine2DObjectCreator read FObjectCreator; // ��������� ������� � ����� ��������� �������

    property SpriteCount: integer read getSpriteCount;
    property Sprites[index: integer]: tEngine2DObject read getObject write setObject;

    property Background: TBitmap read fBackGround write setBackGround;
    property Options: TEngine2dOptions read FOptions write FOptions;

    function IsHor: Boolean; // Return True, if Engine.Width > Engine.Height

    procedure SpriteToBack(const n: integer); // ����������� � ������� ��������� ������
    procedure SpriteToFront(const n: integer);// ����������� � ������� ��������� ������

    procedure Resize;

    procedure MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, y: single); virtual;
    procedure MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, y: single); virtual;

    procedure DeleteObject(const AObject: tEngine2DObject); overload; // ������� ������ �� ���������
    procedure AddObject(const AObject: tEngine2DObject; const AName: String = ''); // ��������� ������ �� ���������

    procedure AssignShadowObject(ASpr: tEngine2DObject); // �������� ������ � ShadowObject
    property ShadowObject: tEngine2DObject read FShadowObject;  // ��������� �� ������� ������.

    procedure ClearSprites; // ������� ������ ��������, �.�. �������� ����������� � ������ �����������
    procedure ClearTemp; // ������� ������� ������ � �.�. ������ ������ ���� �������� �����.

    procedure LoadResources(const AFileName: String);
    procedure LoadSECSS(const AFileName: String);
    procedure LoadSEJSON(const AFileName: String);

    procedure Init(AImage: tImage); // ������������� ������, ����� ������� �� �����, �� �������� ������������ fImage
    procedure Repaint; virtual;

    // ������ ��� ���������� ������
    procedure ShowGroup(const AGroup: String);
    procedure HideGroup(const AGroup: String);
    procedure SendToFrontGroup(const AGroup: String); // ������ ������ �� �������� ����
    procedure BringToBackGroup(const AGroup: String); // ���������� ������ �� ������ ����

    procedure Start; virtual; // �������� ������
    procedure Stop; virtual;// ��������� ������

    constructor Create; virtual;
    destructor Destroy; override;

    const
      CGameStarted = 1;
      CGameStopped = 255;
  end;

const
  pi180 = 0.0174532925; // (1/180)*pi ��� ���������� ���������� ����������

implementation

uses
  System.RegularExpressions, System.JSON, uNewFigure;

{ tEngine2d }

procedure tEngine2d.addObject(const AObject: tEngine2DObject; const AName: String);
var
  l: integer;
  vName: string;
begin
  Inc(FAddedSprite);
  if AName = '' then
    vName := 'genname'+IntToStr(FAddedSprite)+'x'+IntToStr(Random(65536))
  else
    vName := AName;

  if fObjects.IsHere(AObject) then
    raise Exception.Create('You are trying to add Object to Engine that already Exist')
  else
  begin
    fCritical.Enter;
    l := spriteCount;
    fObjects.Add(vName, AObject);
    setLength(fSpriteOrder, l + 1);
    fObjects[l].Image := fImage;
    AObject.OnBringToBack := BringToBackHandler;
    AObject.OnSendToFront := SendToFrontHandler;
    fSpriteOrder[l] := l;
    fCritical.Leave;
  end;
end;

procedure tEngine2d.AssignShadowObject(ASpr: tEngine2DObject);
begin
  //  � ������ ��������� ������� �������� ����������� TEngine2DObject, �.�. ����� ��������� �����
  FShadowObject.Position := ASpr.Position;
{  FShadowObject.ScaleX := ASpr.ScaleX;
  FShadowObject.ScaleY := ASpr.ScaleY;  }
  tSprite(FShadowObject).Resources := tSprite(ASpr).Resources;
end;

procedure tEngine2d.BackGroundDefaultBehavior;
begin
  with Self.Image do
    Bitmap.Canvas.DrawBitmap(
      fBackGround,
      RectF(0, 0, fBackGround.width, fBackGround.height),
      RectF(0, 0, bitmap.width, bitmap.height),
      1,
      true);
end;

procedure tEngine2d.BringToBackGroup(const AGroup: String);
var
  i, iObject, iG: Integer;
  vReg: TRegEx;
  vStrs: TArray<string>;
  vN: Integer;
begin
  vReg := TRegEx.Create(',');
  vStrs := vReg.Split(AGroup);
  vN := fObjects.Count - 1;
  for iG := 0 to Length(vStrs) - 1 do
  begin
    i := vN;
    iObject := vN;
    vStrs[iG] := Trim(vStrs[iG]);
    while iObject > 1 do
    begin
      if fObjects[fSpriteOrder[i]].Group = vStrs[iG] then
      begin
        fObjects[fSpriteOrder[i]].BringToBack;
        Inc(i);
      end;
      Dec(i);
      Dec(iObject);
    end;
  end;
end;

procedure tEngine2d.BringToBackHandler(ASender: TObject);
begin
  SpriteToBack(
    SpriteList.IndexOfItem(TEngine2DObject(ASender), FromBeginning)
  );
end;

procedure tEngine2d.clearSprites;
var
  i: integer;
begin
 for i := 0 to spriteCount - 1 do
    fObjects[i].free;

  setLength(fSpriteOrder, 0);
end;

procedure tEngine2d.clearTemp;
begin
  setLength(self.fClicked, 0);
end;

constructor tEngine2d.Create; // (createSuspended: boolean);
begin
  fCritical := TCriticalSection.Create;
  fEngineThread := tEngineThread.Create;
  fResources := TEngine2DResources.Create(fCritical);
  fAnimationList := TEngine2DAnimationList.Create(fCritical);
  fFormatters := TFormatterList.Create(fCritical, Self);
  fObjects := TObjectsList.Create(fCritical);
  fOptions.Up([EAnimateForever]);
  fOptions.Down([EClickOnlyTop]);

  FBackgroundBehavior := BackgroundDefaultBehavior;
  FInBeginPaintBehavior := InBeginPaintDefaultBehavior;
  FInEndPaintBehavior := InEndPaintDefaultBehavior;
  FAddedSprite := 0;
  fDebug := False;
  prepareFastFields;
  clearSprites;
  prepareShadowObject;
  fBackGround := tBitmap.Create;

  fObjectCreator := TEngine2DObjectCreator.Create(Self, fResources, fObjects, fAnimationList, fFormatters, fFastFields, fEngineThread);
end;

procedure tEngine2d.deleteObject(const AObject: tEngine2DObject);
var
  i, vN, vNum, vPos: integer;
begin
  fCritical.Enter;
  vNum := fObjects.IndexOfItem(AObject, FromEnd);
  if vNum > -1 then
  begin
    vN := fObjects.Count - 1;
    fAnimationList.ClearForSubject(AObject);
    fFormatters.ClearForSubject(AObject);
    fFastFields.ClearForSubject(AObject);
    fObjects.Delete(vNum{AObject});

   // AObject.Free;

    vPos := vN + 1;
    // ������� ������� �������
    for i := vN downto 0 do
      if fSpriteOrder[i] = vNum then
      begin
        vPos := i;
        Break;
      end;

    // �� ���� ������� �������� ������� ���������
    vN := vN - 1;
    for i := vPos to vN do
      fSpriteOrder[i] := fSpriteOrder[i+1];

    // ��� ������� ��������, ������� ������ vNum ���� ��������� �� 1
    for i := 0 to vN do
      if fSpriteOrder[i] >= vNum then
        fSpriteOrder[i] := fSpriteOrder[i] - 1;

    // ��������� ����� �������
    SetLength(fSpriteOrder, vN + 1);
  end;
  fCritical.Leave;
  fDebug := True;
end;

destructor tEngine2d.Destroy;
begin
  fObjectCreator.Free;
  clearSprites;
  fImage.free;
  fAnimationList.Free;
  fFormatters.Free;
  fFastFields.Free;
  fBackGround.free;

  inherited;
end;

procedure tEngine2d.Resize;
var
  i: Integer;
begin
  fCritical.Enter;
  // �������������
  for i := 0 to fFormatters.Count - 1 do
    fFormatters[i].Format;
  fCritical.Leave;
end;

procedure tEngine2d.Repaint;
var
  i, l: integer;
  iA, lA: Integer; // �������� �������� � ��������������
  m: tMatrix;
  vAnimation: tAnimation;
begin

  // ��������
  fCritical.Enter;
  lA := fAnimationList.Count - 1;
  for iA := lA downto 0 do
  begin
    if fAnimationList[iA].Animate = TAnimation.CAnimationEnd then
    begin
      vAnimation := fAnimationList[iA];
      fAnimationList.Delete(iA);
      vAnimation.Free;
    end;
  end;
  fCritical.Leave;

  if fDebug then
   fDebug := False;

  fCritical.Enter;
  if (lA > 0) or (FOptions.ToAnimateForever)  then
    with fImage do
    begin
      if Bitmap.Canvas.BeginScene() then
      try
        FInBeginPaintBehavior;
        FBackgroundBehavior;

        l := (fObjects.Count - 1);
        for i := 1 to l do
        {  if fSpriteOrder[i] <= l then
            if fObjects[fSpriteOrder[i]] <> Nil then   }
          
          if fObjects[fSpriteOrder[i]].visible then
          begin
            m :=
              TMatrix.CreateTranslation(-fObjects[fSpriteOrder[i]].x, -fObjects[fSpriteOrder[i]].y) *
              TMatrix.CreateScaling(fObjects[fSpriteOrder[i]].ScaleX, fObjects[fSpriteOrder[i]].ScaleY) *
              TMatrix.CreateRotation(fObjects[fSpriteOrder[i]].rotate * pi180) *
              TMatrix.CreateTranslation(fObjects[fSpriteOrder[i]].x, fObjects[fSpriteOrder[i]].y);
            Bitmap.Canvas.SetMatrix(m);

            fObjects[fSpriteOrder[i]].Repaint;
            {$IFDEF DEBUG}
            if fOptions.ToDrawFigures then
               fObjects[fSpriteOrder[i]].RepaintWithShapes;
            {$ENDIF}
          end;
      finally
        FInEndPaintBehavior;

        Bitmap.Canvas.EndScene();
        {$IFDEF POSIX}
          InvalidateRect(RectF(0, 0, Bitmap.Width , Bitmap.Height));
        {$ENDIF}
      end;
  end;

  fCritical.Leave;
end;

procedure tEngine2d.SendToFrontGroup(const AGroup: String);
var
  i, iObject, iG: Integer;
  vReg: TRegEx;
  vStrs: TArray<string>;
  vN: Integer;
begin
  vReg := TRegEx.Create(',');
  vStrs := vReg.Split(AGroup);
  vN := fObjects.Count - 1;
  for iG := 0 to Length(vStrs) - 1 do
  begin
    i := 1;
    iObject := 1;
    vStrs[iG] := Trim(vStrs[iG]);
    while iObject < vN do
    begin
      if fObjects[fSpriteOrder[i]].Group = vStrs[iG] then
      begin
        fObjects[fSpriteOrder[i]].SendToFront;
        Dec(i);
      end;
      Inc(i);
      Inc(iObject);
    end;
  end;
end;

procedure tEngine2d.SendToFrontHandler(ASender: TObject);
begin
  SpriteToFront(
    SpriteList.IndexOfItem(TEngine2DObject(ASender), FromBeginning)
  );
end;

function tEngine2d.getObject(index: integer): tEngine2DObject;
begin
  fCritical.Enter;
  result := fObjects[index];
  fCritical.Leave;
end;

function tEngine2d.getSpriteCount: integer;
begin
  result := fObjects.Count;//length(fSprites)
end;

procedure tEngine2d.HideGroup(const AGroup: String);
var
  i, iG: Integer;
  vReg: TRegEx;
  vStrs: TArray<string>;
begin
  vReg := TRegEx.Create(',');
  vStrs := vReg.Split(AGroup);
  for iG := 0 to Length(vStrs) - 1 do
  begin
    vStrs[iG] := Trim(vStrs[iG]);
    for i := 0 to fObjects.Count - 1 do
      if fObjects[i].group = vStrs[iG] then
        fObjects[i].visible := False;
  end;
end;

procedure tEngine2d.InBeginPaintDefaultBehavior;
begin

end;

procedure tEngine2d.InEndPaintDefaultBehavior;
begin
  Exit;
  with FImage do
  begin
  // bitmap.Canvas.Blending:=true;
        bitmap.Canvas.SetMatrix(tMatrix.Identity);
        bitmap.Canvas.Fill.Color := TAlphaColorRec.Brown;
        Bitmap.Canvas.Font.Size := 12;
        Bitmap.Canvas.Font.Style := [TFontStyle.fsBold];
        Bitmap.Canvas.Font.Family := 'arial';
        {$IFDEF CONDITIONALEXPRESSIONS}
         {$IF CompilerVersion >= 19.0}
        bitmap.Canvas.FillText(
          RectF(15, 15, 165, 125),
          'FPS=' + floattostr(fEngineThread.fps),
          false, 1, [],
          TTextAlign.Leading
        );

        {  bitmap.Canvas.FillText(
          RectF(15, 85, 165, 125),
          'scale=' + floattostr(getScreenScale),
          false, 1, [],
          TTextAlign.Leading
        );  }

        {if length(self.fClicked) >= 1 then
        begin
          bitmap.Canvas.FillText(RectF(15, 45, 165, 145),
            'sel=' + inttostr(self.fClicked[0]), false, 1, [],
            TTextAlign.Leading);
        end;
        bitmap.Canvas.FillText(
          RectF(25, 65, 200, 200),
          floattostr(flX) + ' ' + floattostr(flY),
          false, 1, [],
          TTextAlign.Leading
        );                  }
        {$ENDIF}{$ENDIF}
        {$IFDEF VER260}
        bitmap.Canvas.FillText(
          RectF(15, 15, 165, 125),
          'FPS=' + floattostr(fEngineThread.fps),
          false, 1, [],
          TTextAlign.taLeading
        );

      {  if length(self.fClicked) >= 1 then
        begin
          bitmap.Canvas.FillText(RectF(15, 45, 165, 145),
            'sel=' + inttostr(self.fClicked[0]), false, 1, [],
            TTextAlign.taLeading);
        end;
        bitmap.Canvas.FillText(
          RectF(25, 65, 200, 200),
          floattostr(flX) + ' ' + floattostr(flY),
          false, 1, [],
          TTextAlign.taLeading
        );   }
        {$ENDIF}
  end;
end;

procedure tEngine2d.Init(AImage: tImage);
begin
  fImage := AImage;
  fWidth := Round(AImage.Width);
  fHeight := Round(AImage.Height);
  fImage.Bitmap.Width := Round(AImage.Width * getScreenScale);
  fImage.Bitmap.Height := ROund(AImage.Height * getScreenScale);
end;

function tEngine2d.IsHor: Boolean;
begin
  Result := fWidth > fHeight;
end;

procedure tEngine2d.LoadResources(const AFileName: String);
begin
  FResources.AddResFromLoadFileRes(AFileName);
end;

procedure tEngine2d.LoadSECSS(const AFileName: String);
begin
  fFormatters.LoadSECSS(AFileName);
end;

procedure tEngine2d.LoadSEJson(const AFileName: String);
var
  vJSON, vObj, vObjBody: TJSONObject;
  vObjects, vFigures: TJSONArray;
  vValue, vTmp: TJSONValue;
  vPos: TRect;
  vFile: TStringList;
  vImageFile, vObjName, vObjGroup: string;
  i, j: Integer;
  vS, vS1, vS2: string;
  vArr, vArr1, vArr2: TArray<string>;
begin
  vFile := TStringList.Create;
  vFile.LoadFromFile(AFileName);

  vJSON := TJSONObject.ParseJSONValue(vFile.Text) as TJsonObject;
  vImageFile := vJSON.GetValue('ImageFile').ToString;
  VObjects := vJSON.GetValue('Objects') as TJSONArray;

  for i := 0 to vObjects.Count - 1 do
  begin
    vObj := vObjects.Items[i] as TJSONObject;
    vObjName := vObj.GetValue('Name').ToString;
    vObjGroup:= vObj.GetValue('Group').ToString;
    vObjBody := vObj.GetValue('Body') as TJSONObject;
    if vObjBody <> nil then
      with vObjBody do
      begin
        vArr := (GetValue('Position').ToString).Split([';']);
        vArr1 := vArr[0].Split([',']);
        vArr2 := vArr[1].Split([',']);
        vPos := Rect(
                vArr1[0].ToInteger, vArr1[1].ToInteger,
                vArr2[0].ToInteger, vArr2[1].ToInteger);

        vFigures := GetValue('Figures') as TJSONArray;
        if vFigures <> nil then
          for j := 0 to vFigures.Count - 1 do
          begin

          end;
      end;
  end;

  vFile.Free;

end;

procedure tEngine2d.MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, y: single);
var
  i, l: integer;
begin
  FIsMouseDowned := True;

  flX := x;// * getScreenScale;
  flY := y; //* getScreenScale;
  l := fObjects.Count - 1;//length(fSprites) - 1;

  setLength(fClicked, 0);
  setLength(fMouseDowned, 0);

  for i := l downto 1 do
  begin
    if fObjects[fSpriteOrder[i]].visible then
      if fObjects[fSpriteOrder[i]].underTheMouse(flX, flY) then
      begin
        setLength(fMouseDowned, length(fMouseDowned) + 1);
        fMouseDowned[high(fMouseDowned)] := fSpriteOrder[i];

      //�������� w � h � TEngine2DObject � ������ ����������� ��������� ����� � �������

      end;
  end;
end;

procedure tEngine2d.MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, y: single);
var
  i, l: integer;
begin
  FIsMouseDowned := False;

  flX := x ;//* getScreenScale;
  flY := y ;//* getScreenScale;
  l := fObjects.Count - 1;//length(fSprites) - 1;

  SetLength(fClicked, 0);
  SetLength(fMouseUpped, 0);

  for i := l downto 1 do
  begin
    if fObjects[fSpriteOrder[i]].visible then
      if fObjects[fSpriteOrder[i]].underTheMouse(flX, flY) then
      begin
        SetLength(fMouseUpped, length(fMouseUpped) + 1);
        fMouseUpped[high(fMouseUpped)] := fSpriteOrder[i];
      end;
    end;

  fClicked := IntArrInIntArr(fMouseDowned, fMouseUpped);
end;

procedure tEngine2d.prepareFastFields;
var
  vTmp: TFastField;
begin
  fFastFields := TFastFields.Create(IsHor);
//  fFastFields.Parent := Self;
  vTmp := TFastEngineWidth.Create(Self);
  fFastFields.Add('engine.width', vTmp);
  vTmp := TFastEngineHeight.Create(Self);
  fFastFields.Add('engine.height', vTmp);
end;

procedure tEngine2d.prepareShadowObject;
begin
  FShadowObject := tSprite.Create;
  Self.AddObject(FShadowObject, 'shadow');
end;

procedure tEngine2d.setBackGround(ABmp: tBitmap);
begin
  if width > height then
  begin
    fBackGround.Assign(ABmp);
    fBackGround.rotate(90);
  end
  else
    fBackGround.Assign(ABmp);
end;

procedure tEngine2d.SetBackgroundBehavior(const Value: TProcedure);
begin
  FBackgroundBehavior := Value;
end;

procedure tEngine2d.setHeight(AHeight: integer);
begin
  fImage.Bitmap.Height := Round(AHeight * getScreenScale + 0.4);
  fHeight := AHeight;
end;

procedure tEngine2d.setObject(index: integer; newSprite: tEngine2DObject);
begin
  fCritical.Enter;
  fObjects[index] := NewSprite;
  fCritical.Leave;
end;

procedure tEngine2d.setStatus(newStatus: byte);
begin
  fStatus := newStatus;
end;

procedure tEngine2d.setWidth(AWidth: integer);
begin
  fImage.Bitmap.Width := Round(AWidth * getScreenScale + 0.4);
  fWidth := AWidth;
end;

procedure tEngine2d.showGroup(const AGroup: String);
var
  i, iG: Integer;
  vReg: TRegEx;
  vStrs: TArray<string>;
begin
  vReg := TRegEx.Create(',');
  vStrs := vReg.Split(AGroup);
  for iG := 0 to Length(vStrs) - 1 do
  begin
    vStrs[iG] := Trim(vStrs[iG]);
    for i := 0 to fObjects.Count - 1 do
      if fObjects[i].group = vStrs[iG] then
        fObjects[i].visible := True;
  end;
end;

procedure tEngine2d.spriteToBack(const n: integer);
var
  i, l, oldOrder: integer;
begin
  l := length(fSpriteOrder);

  oldOrder := fSpriteOrder[n]; // ����� ������� ��������� ������� ����� n

  for i := 1 to l - 1 do
    if fSpriteOrder[i] < oldOrder then
      fSpriteOrder[i] := fSpriteOrder[i] + 1;

  fSpriteOrder[n] := 1;
end;

procedure tEngine2d.spriteToFront(const n: integer);
var
  i, l, oldOrder: integer;
begin
  l := length(fSpriteOrder);
  oldOrder := l - 1;

  for i := 1 to l - 1 do
    if fSpriteOrder[i] = n then
    begin
      oldOrder := i;
      break;
    end;

  for i := oldOrder to l - 2 do
  begin
    fSpriteOrder[i] := fSpriteOrder[i + 1];
  end;

  fSpriteOrder[l - 1] := n;
end;

procedure tEngine2d.start;
begin
  status := CGameStarted;
end;

procedure tEngine2d.stop;
begin
  status := CGameStopped;
end;

end.

