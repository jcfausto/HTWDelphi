unit GamePresenter;

interface

uses
  Classes, Game;

type
  TGamePresenter = class
    private
      function isShootCommand(tokens: TStrings): Boolean;
      procedure shootArrow(direction: String);
      function directionFromName(name: String): String;
      function isSingleWordShootCommand(tokens: TStrings): Boolean;
      function isGoCommand(tokens: TStrings): Boolean;
      procedure movePlayer(direction: String);
      function directionName(direction: String): String;
      function isRestCommand(tokens: TStrings): Boolean;
      function isImplicitGoCommand(tokens: TStrings): Boolean;
      procedure printEndOfTurnMessages(arrowsInQuiver: Byte);
      procedure printCauseOfTermination;
      procedure printArrowsFound(arrowsInQuiver: Byte);
      procedure printAvailableDirections;
      procedure printBatSounds;
      procedure printPitSounds;
      procedure printQuiverStatus;
      procedure printTransportMessage;
      procedure printWumpusOdor;

    public
      game: TGame;
      procedure print(msg: String);
      function execute(command: String): Boolean;
      function getAvailableDirections: string;
      constructor Create;
      destructor Destroy; override;
  end;

implementation

uses
  SysUtils, AvaiableDirections;

{ TGamePresenter }

constructor TGamePresenter.Create;
begin
  game := TGame.Create;
end;

destructor TGamePresenter.Destroy;
begin
  inherited;
  game.Free;
  game := nil;
end;

procedure TGamePresenter.print(msg: String);
begin
  write(msg);
end;

function TGamePresenter.execute(command: String): Boolean;
var
  valid: Boolean;
  arrowsInQuiver: Byte;
  tokens: TStrings;
  direction: string;
begin
    valid := True;
    arrowsInQuiver := game.getQuiver;

    tokens := TStringList.Create;

    tokens.commaText := StringReplace(command, ' ', ',', [rfReplaceAll]);

    if (isShootCommand(tokens)) then
    begin
      shootArrow(directionFromName(tokens.Strings[1]));
    end
    else if (isSingleWordShootCommand(tokens)) then
    begin
      shootArrow(Copy(tokens.Strings[0], 2, Length(tokens.Strings[0])));
    end                         
    else if (isGoCommand(tokens)) then
    begin
      movePlayer(directionFromName(tokens.Strings[1]));
    end
    else if (isRestCommand(tokens)) then
    begin
      game.rest();
    end
    else if (isImplicitGoCommand(tokens)) then
    begin
      direction := directionFromName(tokens.Strings[0]);
      if (direction <> '') then
        movePlayer(direction);
    end
    else
    begin
      if (command = '') then
        command := 'process an empty command ';

      print('I don''''t know how to ' + command + '.' +  char(10));
      valid := false;
    end;

    printEndOfTurnMessages(arrowsInQuiver);
    Result := valid;   
    FreeAndNil(tokens);
end;

function TGamePresenter.isShootCommand(tokens: TStrings): Boolean;
begin
  Result := (tokens.Count = 2) and
            ((tokens.Strings[0] = 'shoot') or (tokens.Strings[0] = 's'));
end;

procedure TGamePresenter.shootArrow(direction: String);
begin
  if (game.shoot(direction) = False) then
    print('You don''''t have any arrows.')
  else
    print('The arrow flies away in silence.');
end;

procedure TGamePresenter.movePlayer(direction: String);
begin
  if (game.move(direction) = False) then
    print('You can''''t go ' + directionName(direction) + ' from here.');
end;

function TGamePresenter.directionFromName(name: String): String;
begin
  if ((name = 'e') or (name = 'east')) then
    Result := EAST
  else if ((name = 'w') or (name = 'west')) then
    Result := WEST
  else if ((name = 'n') or (name = 'north')) then
    Result := NORTH
  else if ((name = 's') or (name = 'south')) then
    Result := SOUTH
  else
    Result := '';
end;

function TGamePresenter.isSingleWordShootCommand(tokens: TStrings): Boolean;
begin
  Result := (tokens.Count > 0) and ((Pos('s', tokens.Strings[0]) = 1) and
    (directionFromName(Copy(tokens.Strings[0], 2, Length(tokens.Strings[0]))) <> ''));
end;

function TGamePresenter.isGoCommand(tokens: TStrings): Boolean;
begin
  Result := (tokens.Count = 2) and (tokens.Strings[0] = 'go');
end;

function TGamePresenter.isRestCommand(tokens: TStrings): Boolean;
begin
  Result := (tokens.Count > 0) and ( (tokens.Strings[0] = 'r') or (tokens.Strings[0] = 'rest') );
end;

function TGamePresenter.isImplicitGoCommand(tokens: TStrings): Boolean;
begin
  Result := (tokens.Count = 1) and (directionFromName(tokens.Strings[0]) <> '');
end;

function TGamePresenter.directionName(direction: String): String;
begin
  if (direction = NORTH) then
    Result :=  'north'
  else if (direction = SOUTH) then
    Result := 'south'
  else if (direction = EAST) then
    Result := 'east'
  else if (direction = WEST) then
    Result := 'west'
  else
    Result := 'tilt';
end;

procedure TGamePresenter.printCauseOfTermination;
begin
  if (game.wasKilledByArrowBounce) then
    print('The arrow bounced off the wall and killed you.')
  else if (game.IsFellInPit) then
    print('You fall into a pit and die.')
  else if (game.IsWumpusHitByArrow) then
    print('You have killed the Wumpus.')
  else if (game.IsEatenByWumpus) then
    print('The ravenous snarling Wumpus gobbles you down.')
  else if (game.IsHitByOwnArrow) then
    print('You were hit by your own arrow.');
end;


procedure TGamePresenter.printTransportMessage;
begin
  if (game.IsBatTransport) then
  begin
    print('A swarm of angry bats has carried off.');
    game.resetBatTransport;
  end;
end;

procedure TGamePresenter.printBatSounds;
begin
  if (game.canHearBats) then
    print('You hear chirping.');
end;

procedure TGamePresenter.printPitSounds;
begin
  if (game.canHearPit) then
    print('You hear wind.');
end;

procedure TGamePresenter.printAvailableDirections;
begin
  print(getAvailableDirections);
end;

procedure TGamePresenter.printWumpusOdor;
begin
  if (game.canSmellWumpus) then
    print('You smell the Wumpus.');
end;

procedure TGamePresenter.printQuiverStatus;
begin
  if (game.getQuiver = 0) then
    print('You have no arrows.')
  else if (game.getQuiver = 1) then
    print('You have 1 arrow.')
  else
    print('You have ' + IntToStr(game.getQuiver) + ' arrows.');
end;

procedure TGamePresenter.printArrowsFound(arrowsInQuiver: Byte);
begin
  if (game.getQuiver > arrowsInQuiver) then
    print('You found an arrow.');
end;

function TGamePresenter.getAvailableDirections: string;
var
  directions: TAvailableDirections;
  p: TPath;
  i: integer;
begin
    directions := TAvailableDirections.Create;
    try
      try
        for i := 0 to game.paths.Count-1 do
        begin
          p := TPath(game.paths.Items[i]);

          if (p.start = game.playerCavern) then
            directions.addDirection(p.direction);
        end;

        Result := directions.toString;

      finally
        FreeAndNil(directions);
      end;
    except
      on e: Exception do writeln(e.message);
    end;
end;

procedure TGamePresenter.printEndOfTurnMessages(arrowsInQuiver: Byte);
begin
  if (game.IsGameTerminated) then
  begin
    printCauseOfTermination;
    print('Game over.');
  end
  else
  begin
    printTransportMessage;
    printArrowsFound(arrowsInQuiver);
    printQuiverStatus();
    printWumpusOdor();
    printPitSounds();
    printBatSounds();
    printAvailableDirections();
  end;
end;


end.
