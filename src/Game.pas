unit Game;

{---------------------------------------------------------------------------------------------------
Created by: Julio C. Fausto in November 2011
Port of WuntTheWumpus Java Implementation.

Third party components
  1. IntList.pas : http://www.explainth.at/en/delphi/intlist.shtml
---------------------------------------------------------------------------------------------------}

interface

uses
  Classes, IntList;

const
  EAST  = 'e';
  WEST  = 'w';
  NORTH = 'n';
  SOUTH = 's';

type
    TPath = class
      public
        start: ShortInt;
        pathend: ShortInt;
        direction: string;
        constructor Create(start: integer; pathend: ShortInt; direction: string);
    end;

type
    TGame = class
      private
        wumpusCavern: ShortInt;
        quiver: ShortInt;
        arrows: TIntList;
        gameTerminated: Boolean;
        killedByArrowBounce: Boolean;
        pits: TIntList;
        fellInPit: Boolean;
        wumpusHitByArrow: Boolean;
        wumpusFrozen: Boolean;
        eatenByWumpus: Boolean;
        hitByOwnArrow: Boolean;
        bats: TIntList;
        batTransport: Boolean;

        procedure addSinglePath(start: ShortInt; pathend: ShortInt; direction: String);
        function oppositeDirection(direction: String): String;
        procedure removeArrowFrom(cavern: ShortInt);
        function arrowInCavern(cavern: ShortInt): Boolean;
        function adjacentTo(direction: String; cavern: ShortInt): Byte;
        procedure checkWumpusEatsPlayer;
        procedure checkForPit;
        procedure checkForBats;
        procedure transportPlayer;
        procedure pickUpArrow;
        procedure addPossibleMove(dir: string; moves: TIntList);
        function areAdjacent(c1, c2: Byte): Boolean;
        function shootAsFarAsPossible(direction: string; cavern: Byte): Byte;

      public
        paths: TList;
        playerCavern: ShortInt;

        procedure addPath(start: ShortInt; pathend: ShortInt; direction: string);
        procedure clearMap;
        procedure putPlayerInCavern(cavern: ShortInt);
        procedure rest;
        function move(direction: String): Boolean;
        function GetPlayerCavern: Byte;
        procedure moveWumpus();
        procedure putWumpusInCavern(where: Byte);
        procedure setQuiver(arrows: Byte);
        procedure putArrowInCavern(cavern: Byte);
        function getQuiver: Byte;
        function wasKilledByArrowBounce: Boolean;
        function shoot(direction: String): Boolean;
        function IsGameTerminated: Boolean;
        function IsFellInPit: Boolean;
        procedure putPitInCavern(cavern: Byte);
        function canHearPit: Boolean;
        function canSmellWumpus: Boolean;        
        function IsWumpusHitByArrow: Boolean;
        function IsEatenByWumpus: Boolean;
        function getWumpusCavern: Byte;
        function IsHitByOwnArrow: Boolean;
        function canHearBats: Boolean;
        procedure freezeWumpus;
        function IsBatTransport: Boolean;
        procedure putBatsInCavern(cavern: Byte);
        procedure resetBatTransport;
        procedure reset;

        procedure terminate;

        constructor Create;
        destructor Destroy; override;

     end;

implementation

uses
  SysUtils;

{ TGame }

procedure TGame.addPath(start, pathend: ShortInt; direction: string);
begin
  try
    addSinglePath(start, pathend, LowerCase(direction));
    addSinglePath(pathend, start, oppositeDirection(LowerCase(direction)));
  except
    //
  end;
end;

procedure TGame.addSinglePath(start, pathend: ShortInt; direction: String);
var
  path: TPath;
begin
    path := TPath.Create(start, pathend, direction);
    paths.add(path);
end;

procedure TGame.clearMap;
begin
  paths.Clear;
end;

constructor TGame.Create;
begin
  playerCavern := -1;
  wumpusCavern := -1;
  quiver := 0;
  gameTerminated := false;
  killedByArrowBounce := false;
  fellInPit := false;
  wumpusHitByArrow := false;
  wumpusFrozen := false;
  eatenByWumpus := false;
  hitByOwnArrow := false;
  batTransport := false;
  paths := TList.Create;
  arrows := TIntList.CreateEx;
  pits := TIntList.CreateEx;
  bats := TIntList.CreateEx;
end;

destructor TGame.Destroy;
begin
  paths.Free;
  arrows.Free;
  pits.Free;
  bats.Free;

  paths := nil;
  arrows := nil;
  pits := nil;
  bats := nil;
  inherited;
end;

function TGame.oppositeDirection(direction: String): String;
begin
  Result := 'Erro: No such direction';
  if (direction = EAST) then
    result := WEST
  else if (direction = WEST) then
    result := EAST
  else if (direction = NORTH) then
    result := SOUTH
  else if (direction = SOUTH) then
    Result := NORTH;
end;

procedure TGame.putPlayerInCavern(cavern: ShortInt);
begin
  Self.playerCavern := cavern;
end;

procedure TGame.removeArrowFrom(cavern: ShortInt);
var
  i: ShortInt;
  c: ShortInt;
begin
  for i := 0 to arrows.IntCount-1 do
  begin
      c := arrows.Integers[i];
      if (c = cavern) then
        arrows.Delete(i);
  end;
end;

function TGame.arrowInCavern(cavern: ShortInt): Boolean;
begin
  result := (arrows.Find(cavern) <> -1);
end;

procedure TGame.rest;
begin
  moveWumpus;
end;

function TGame.move(direction: String): Boolean;
var
  destination: Byte;
begin
  destination := adjacentTo(direction, playerCavern);
  Result := False;
  if (destination <> 0) then
  begin
    Self.playerCavern := destination;
    checkWumpusEatsPlayer;
    checkForPit;
    checkForBats;
    pickUpArrow;
    moveWumpus;
    Result := true;
  end;
end;

procedure TGame.checkWumpusEatsPlayer;
begin
  if (playerCavern = wumpusCavern) then
  begin
    gameTerminated := True;
    eatenByWumpus := True;
  end;
end;

procedure TGame.checkForPit;
begin
  if (pits.find(playerCavern) <> -1) then
  begin
    gameTerminated := True;
    fellInPit := True;
  end;
end;

procedure TGame.checkForBats;
begin
  while (bats.find(playerCavern) <> -1) do
  begin
    transportPlayer;
    batTransport := True;
  end;
end;

procedure TGame.transportPlayer;
var
  selectedPath: TPath;
begin
  Randomize;
  selectedPath := TPath(paths.Items[Random(paths.Count-1)]);
  playerCavern := selectedPath.start;
end;

procedure TGame.pickUpArrow;
begin
  if (arrowInCavern(playerCavern)) then
  begin
    removeArrowFrom(playerCavern);
    Inc(quiver);
  end;
end;

procedure TGame.moveWumpus;
var
  moves: TIntList;
  selection: Byte;
  selectedMove: Byte;
begin
  if (wumpusFrozen) then
    exit;


  moves := TIntList.CreateEx;
  try

    try
      addPossibleMove(EAST, moves);
      addPossibleMove(WEST, moves);
      addPossibleMove(NORTH, moves);
      addPossibleMove(SOUTH, moves);
      moves.add(0); // rest;

      Randomize;
      selection := Random(moves.IntCount-1);
      selectedMove := moves.Integers[selection];
      if (selectedMove <> 0) then
      begin
        wumpusCavern := selectedMove;
        checkWumpusEatsPlayer;
      end;
    except
      on e:Exception do Writeln(e.message);
    end;

  finally
    FreeAndNil(moves);
  end;
end;

procedure TGame.addPossibleMove(dir: string; moves: TIntList);
var
  possibleMove: Byte;
begin
  possibleMove := adjacentTo(dir, wumpusCavern);
  if (possibleMove <> 0) then
  begin
    moves.add(possibleMove);
  end;
end;

function TGame.adjacentTo(direction: String; cavern: ShortInt): Byte;
var
  i: byte;
  path: TPath;
begin
   Result := 0;

   for i := 0 to paths.Count-1 do
   begin
     path := TPath(paths.Items[i]);
     if ((path.start = cavern) and (path.direction = direction)) then
      Result := path.pathend;
   end;

end;

function TGame.IsGameTerminated: Boolean;
begin
  Result := gameTerminated;
end;

procedure TGame.putPitInCavern(cavern: Byte);
begin
  pits.add(cavern);
end;

function TGame.IsFellInPit: Boolean;
begin
  Result := fellInPit;
end;

function TGame.GetPlayerCavern: Byte;
begin
  Result :=  Self.playerCavern;
end;

procedure TGame.putWumpusInCavern(where: Byte);
begin
  wumpusCavern := where;
end;

function TGame.areAdjacent(c1: Byte; c2: Byte): Boolean;
var
  i: byte;
  path: TPath;
begin
   Result := False;
   for i := 0 to paths.Count-1 do
   begin
     path := TPath(paths.Items[i]);
     if ((path.start = c1) and (path.pathend = c2)) then
     begin
       Result := True;
       Exit;
     end;
   end;
end;

function TGame.IsWumpusHitByArrow: Boolean;
begin
  Result := wumpusHitByArrow;
end;

function TGame.canSmellWumpus: Boolean;
begin
  Result := areAdjacent(playerCavern, wumpusCavern);
end;

procedure TGame.setQuiver(arrows: Byte);
begin
  Self.quiver := arrows;
end;

function TGame.getQuiver: Byte;
begin
  Result := quiver;
end;

procedure TGame.putArrowInCavern(cavern: Byte);
begin
  arrows.add(cavern);
end;

function TGame.wasKilledByArrowBounce: Boolean;
begin
  Result :=  killedByArrowBounce;
end;

function TGame.shootAsFarAsPossible(direction: string; cavern: Byte): Byte;
var
  nextCavern: Byte;
begin
  nextCavern := adjacentTo(direction, cavern);
  if (nextCavern = 0) then
  begin
    Result := cavern;
  end
  else
  begin
    if (nextCavern = wumpusCavern) then
    begin
        wumpusHitByArrow := True;
        gameTerminated := True;
        Result := nextCavern;
        Exit;
    end else if (nextCavern = playerCavern) then
    begin
        gameTerminated := True;
        hitByOwnArrow := True;
        Result := nextCavern;
        Exit;
    end;
    Result := shootAsFarAsPossible(direction, nextCavern);
  end;
end;

function TGame.shoot(direction: String): Boolean;
var
  endCavern: Byte;
begin
  Result := False;
  if (quiver > 0) then
  begin
    Dec(quiver);
    if (adjacentTo(direction, playerCavern) = 0) then
    begin
      gameTerminated := True;
      killedByArrowBounce := True;
    end
    else
    begin
      endCavern := shootAsFarAsPossible(direction, playerCavern);
      putArrowInCavern(endCavern);
      moveWumpus;
    end;
    Result := True;
  end;
end;

function TGame.canHearPit: Boolean;
var
  i: byte;
begin
  Result := False;

  for i := 0 to pits.IntCount-1 do
  begin
    if (areAdjacent(playerCavern, pits.Integers[i])) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TGame.getWumpusCavern: Byte;
begin
  Result := wumpusCavern;
end;

function TGame.IsEatenByWumpus: Boolean;
begin
  Result := eatenByWumpus;
end;

function TGame.IsHitByOwnArrow: Boolean;
begin
  Result := hitByOwnArrow;
end;

procedure TGame.freezeWumpus;
begin
  wumpusFrozen := True;
end;

procedure TGame.putBatsInCavern(cavern: Byte);
begin
  bats.add(cavern);
end;

function TGame.canHearBats: Boolean;
var
  i: Byte;
begin
  Result := False;
  for i := 0 to bats.IntCount-1 do
  begin
    if (areAdjacent(bats.Integers[i], playerCavern)) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TGame.IsBatTransport: Boolean;
begin
  Result := batTransport;
end;

procedure TGame.resetBatTransport;
begin
  batTransport := False;
end;

procedure TGame.reset;
begin
  gameTerminated := False;
  wumpusHitByArrow := False;
  fellInPit := False;;
  killedByArrowBounce := False;
  eatenByWumpus := False;
  hitByOwnArrow := False;
  batTransport := False;
end;

procedure TGame.terminate;
begin
  gameTerminated := True;
end;

{ TPath }
constructor TPath.Create(start: integer; pathend: ShortInt; direction: string);
begin
  Self.start := start;
  Self.pathend := pathend;
  Self.direction := direction;
end;

end.
