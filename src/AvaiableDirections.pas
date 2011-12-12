unit AvaiableDirections;

interface

uses
  Classes, SysUtils;

type
  TAvailableDirections = class
    private
      directions: TStrings;
      nDirections: Byte;
      available: String;
      directionsPlaced: Byte;
      function assembleDirections: string;
      function StrInArray(const Value: String;
      const ArrayOfString: array of String): Boolean;
      procedure placeDirection(dir: String);
      function isLastOfMany: Boolean;
      function notFirst: boolean;
      function directionName(direction: String): String;
    public
      constructor Create;
      destructor Destroy; override;
      function toString: String;
      procedure addDirection(direction: String);      
  end;

implementation

uses
  Game;

{ TAvailableDirections }

constructor TAvailableDirections.Create;
begin
  directions := TStringList.Create;
end;

function TAvailableDirections.toString: String;
begin
  if (directions.Count = 0) then
    Result := 'There are no exits!'
  else
    Result := assembleDirections;
end;

function TAvailableDirections.assembleDirections: string;
var
  aDirections: array [1..4] of String;
  i: Integer;
begin
  nDirections := directions.Count;
  directionsPlaced := 0;

  aDirections[1] := NORTH;
  aDirections[2] := SOUTH;
  aDirections[3] := EAST;
  aDirections[4] := WEST;

  for i := 0 to directions.Count-1 do
  begin
    if (StrInArray(directions[i], aDirections)) then
      placeDirection(directions[i]);
  end;

  Result :=  'You can go ' + available + ' from here.';
end;


function TAvailableDirections.StrInArray(const Value : String;const ArrayOfString : Array of String) : Boolean;
var
 i: integer;
begin
  Result := False;

  for i := 0 to SizeOf(ArrayOfString) do
  begin
    if Value = ArrayOfString[i] then
    begin
       Result := True;
       Exit;
    end;
  end;
end;

procedure TAvailableDirections.placeDirection(dir: String);
begin
  inc(directionsPlaced);
  if (isLastOfMany) then
    available := available + ' and '
  else if (notFirst) then
    available := available + ', ';
  available := available + directionName(dir);
end;

function TAvailableDirections.notFirst: boolean;
begin
  Result := (directionsPlaced > 1);
end;

function TAvailableDirections.isLastOfMany: Boolean;
begin
  Result := (nDirections > 1) and (directionsPlaced = nDirections);
end;

procedure TAvailableDirections.addDirection(direction: String );
begin
  directions.add(direction);
end;

function TAvailableDirections.directionName(direction: String): String;
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

destructor TAvailableDirections.Destroy;
begin
  inherited;
  FreeAndNil(directions);
end;

end.
