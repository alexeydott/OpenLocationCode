unit olc;

interface

uses
  Types, SysUtils, Math;

type
  // struct  OLC_LatLon { double lat; double lon; }
  /// <summary>
  /// A pair of doubles representing latitude and longitude.
  /// </summary>
   TOLCLatLon = record
    Lat: Double;
    Lon: Double;
    class function Create(const ALat, ALon: Double):  TOLCLatLon; static; inline;
  end;

  /// <summary>
  /// geodetic calculations, including Vincenty's formulae.
  /// </summary>
  TOLCGeoCalc = class
  private
    // WGS-84 ellipsoid parameters
    const
      WGS84_A = 6378137.0;            // Semi-major axis in meters
      WGS84_A_SQ = WGS84_A * WGS84_A; // Squared semi-major in meters.
      WGS84_B = 6356752.314245;       // Semi-minor axis in meters
      WGS84_B_SQ = WGS84_B * WGS84_B; // Squared semi-minor in meters.
      WGS84_F = 1 / 298.257223563;    // Inverse flattening
      ONE_MINUS_F = 1.0 - WGS84_F;    // Pre-calculated value for (1-f) as it's used frequently.
      EPSILON = 1e-12;
  public
    /// <summary>
    /// Solves the direct geodetic problem using Vincenty's formula.
    /// Calculates the destination point given a starting point, initial bearing (azimuth), and distance.
    /// </summary>
    /// <param name="startPoint">The starting coordinates (Lat, Lon in degrees).</param>
    /// <param name="azimuth">The initial bearing in degrees (0=North, 90=East, 180=South, 270=West).</param>
    /// <param name="distance">The distance to travel in meters.</param>
    /// <returns>The coordinates of the destination point.</returns>
    class function CalculateDestination(const startPoint: TOLCLatLon; azimuth, distance: Double): TOLCLatLon; static;

    /// <summary>
    /// Solves the inverse geodetic problem using Vincenty's formula.
    /// Calculates the distance and azimuths between two points.
    /// </summary>
    /// <param name="startPoint">The starting coordinates (Lat, Lon in degrees).</param>
    /// <param name="endPoint">The destination coordinates (Lat, Lon in degrees).</param>
    /// <param name="distance">distance between the points in meters.</param>
    /// <param name="startAzimuth">initial bearing (forward azimuth) from the start point to the end point, in degrees.</param>
    /// <param name="endAzimuth">final bearing (back azimuth) from the end point to the start point, in degrees.</param>
    /// <returns>True if the calculation converged successfully, False otherwise (e.g., for antipodal points).</returns>
    class function CalculateInverse(const startPoint, endPoint: TOLCLatLon; out distance, startAzimuth, endAzimuth: Double): Boolean; static;
  end;

  // struct OLC_CodeArea {  OLC_LatLon lo; hi; size_t len; }
  /// <summary>
  /// An area defined by two corners (lo and hi) and a code length.
  /// </summary>
  TOLCCodeArea = record
  private
    function GetSouthLatitude: Double;
    procedure SetSouthLatitude(const Value: Double);
    function GetNorthLatitude: Double;
    procedure SetNorthLatitude(const Value: Double);
    function GetWestLongitude: Double;
    procedure SetWestLongitude(const Value: Double);
    function GetEastLongitude: Double;
    procedure SetEastLongitude(const Value: Double);
    function GetCenter: TOLCLatLon;
    procedure SetCenter(const Value: TOLCLatLon);
    function GetWidth: Double;
    procedure SetWidth(const Value: Double);
    function GetHeight: Double;
    procedure SetHeight(const Value: Double);
    function GetLocation: TOLCLatLon;
    procedure SetLocation(const Value: TOLCLatLon);
    function GetSize: TSizeF;
    procedure SetSize(const Value: TSizeF);
  public
    Lo:  TOLCLatLon;
    Hi:  TOLCLatLon;
    CodeLength: Integer;
    /// <summary>
    /// Creates a new CodeArea from a center point and dimensions in meters.
    /// </summary>
    /// <param name="center">The center coordinates of the area.</param>
    /// <param name="widthMeters">The width of the area in meters.</param>
    /// <param name="heightMeters">The height of the area in meters.</param>
    /// <returns>A new TOLCCodeArea instance.</returns>
    class function CreateMeters(const center: TOLCLatLon; widthMeters, heightMeters: Double): TOLCCodeArea; static;

    /// <summary>
    /// Gets or sets the width of the area in meters.
    /// When setting, the width is changed relative to the West (left) edge.
    /// </summary>
    property Width: Double read GetWidth write SetWidth;

    /// <summary>
    /// Gets or sets the height of the area in meters.
    /// When setting, the height is changed relative to the North (top) edge.
    /// </summary>
    property Height: Double read GetHeight write SetHeight;

    /// <summary>
    /// Gets or sets the location of the North-West (top-left) corner of the area.
    /// When setting, the area is moved, preserving its dimensions.
    /// </summary>
    property Location: TOLCLatLon read GetLocation write SetLocation;

    /// <summary>
    /// Gets or sets the size (width and height) of the area in meters.
    /// When setting, the size is changed relative to the North-West (top-left) corner.
    /// </summary>
    property Size: TSizeF read GetSize write SetSize;

    ///<summary>Bottom corner of the area.<summary>
    property SouthLatitude: Double read GetSouthLatitude write SetSouthLatitude;

    ///<summary>Left corner of the area.<summary>
    property WestLongitude: Double read GetWestLongitude write SetWestLongitude;

    ///<summary>Top corner of the area.<summary>
    property NorthLatitude: Double read GetNorthLatitude write SetNorthLatitude;

    ///<summary>Right corner of the area.<summary>
    property EastLongitude: Double read GetEastLongitude write SetEastLongitude;
    /// <summary>
    /// Gets or sets the center coordinates of the code area.
    /// When setting, the area is moved to the new center while preserving its size.
    /// </summary>
    property Center: TOLCLatLon read GetCenter write SetCenter;
    /// <summary>
    /// Creates a new TOLCCodeArea by shifting the current area by a given distance in meters.
    /// </summary>
    /// <param name="XMeters">The distance in meters to shift along the X-axis (East is positive).</param>
    /// <param name="YMeters">The distance in meters to shift along the Y-axis (North is positive).</param>
    /// <returns>A new, shifted TOLCCodeArea instance.</returns>
    function Offset(const XMeters, YMeters: Double): TOLCCodeArea;
  end;

  // struct OLC_LatLonIntegers { long long lat; long long lon; }
  /// <summary>
  /// A pair of clipped, normalised positive range integers representing latitude
  /// and longitude. This is used internally in the encoding methods to avoid
  /// floating-point precision issues.
  /// </summary>
  TOLCLatLonIntegers = record
    Lat: Int64;
    Lon: Int64;
  end;

  /// <summary>
  /// Specifies the direction for finding a neighboring Open Location Code.
  /// </summary>
  TOLCNeighborType = (
    ntNorth, ntSouth, ntEast, ntWest,
    ntNorthEast, ntNorthWest, ntSouthEast, ntSouthWest
  );

  TOLCNeighbors = set of TOLCNeighborType;

  /// <summary>
  /// Defines predefined levels of precision for OLC code generation.
  /// </summary>
  TOLCPrecision = (
    pcHundredsOfMeters, // ~275m
    pcTensOfMeters,     // ~14m
    pcMeters,           // ~3m
    pcCentimeters,      // ~50cm-10cm
    pcMillimeters       // ~2cm-4mm
  );

  /// <summary>
  /// Ìethods for encoding and decoding Open Location Codes (Plus Codes).
  /// </summary>
  TOLC = class
  public
    // OLC library version.//
    const
      OLC_VERSION_MAJOR = 1;
      OLC_VERSION_MINOR = 0;
      OLC_VERSION_PATCH = 0;
   {$region '  olc_private.h.'}
 private
    const
      // Basis of the numbering system used in the OLC algorithm.
      OLC_kEncodingBase  = 20;
      //  Number of columns in the additional refinement grid.ûâ
      OLC_kGridCols      = 4;
      // Maximum absolute value of latitude in degrees.
      OLC_kLatMaxDegrees = 90;
      // Maximum absolute value of longitude in degrees.
      OLC_kLonMaxDegrees = 180;
      // Maximum accuracy for codes with a length of 15 characters.
      //   How many integer "units" of latitude are contained in one degree at the maximum level of detail.
      OLC_kGridLatPrecisionInverse = 25000000; // 2.5e7; (20 * 20 * 20 * 5 * 5 * 5 * 5 * 5)
      //   How many integer "units" of longitude are contained in one degree at the maximum level of detail.
      OLC_kGridLonPrecisionInverse = 8192000;  // 8.192e6; (20^3) * (4^5) = 8000 * 1024 = 8,192,000
      OLC_kGridLatScale = OLC_kLatMaxDegrees * Int64(OLC_kGridLatPrecisionInverse);
      OLC_kGridLonScale = OLC_kLonMaxDegrees * Int64(OLC_kGridLonPrecisionInverse);
      OLC_kGridLatScaleMax = 2 * OLC_kGridLatScale;
      OLC_kGridLonScaleMax = 2 * OLC_kGridLonScale;
      // Lookup table for performance, maps 'C' through 'X' to their alphabet positions.
      OLC_kAlphabetPositionLUT: array['C'..'X'] of Integer = (8, -1, -1, 9, 10, 11, -1, 12, -1, -1, 13,-1, -1, 14, 15, 16, -1, -1, -1, 17, 18, 19);
      // equivalent to 90 degrees latitude, but on an integer scale.
      kGridLatScale: Int64 = OLC_kGridLatScale;
      // equivalent to 180 degrees longitude, but on an integer scale.
      kGridLonScale: Int64 = OLC_kGridLonScale;
      // Full latitude range (180 degrees: from -90 to +90) in integer.
      kGridLatScaleMax: Int64 = OLC_kGridLatScaleMax;
      // Full longitude range (360 degrees: from -180 to +180) in integer.
      kGridLonScaleMax: Int64 = OLC_kGridLonScaleMax;

      // Pre-calculated powers for Decode() and EncodeIntegers()
      PV_INIT = 3200000; // Power(20, 5)
      ROW_PV_INIT = 3125;   // Power(5, 5)
      COL_PV_INIT = 1024;   // Power(4, 5)
      GRID_ROWS_POW_GRID_CODE_LENGTH = 3125;
      GRID_COLS_POW_GRID_CODE_LENGTH = 1024;

      // Pre-calculated power tables for ComputeLatitudePrecision
      POWER_20_TABLE: array[0..2] of Double = (1.0, 20.0, 400.0); // 20^0, 20^1, 20^2
      INV_POWER_20_TABLE: array[0..3] of Double = (1.0, 1/20, 1/400, 1/8000); // 20^0, 20^-1, 20^-2, 20^-3
    {$endregion}
  public
   {$region '  olc.h.'}
    // Public constants for the OLC algorithm.
    const
      /// <summary>Separates the first eight digits from the rest.</summary>
      kSeparator          = '+';
      /// <summary>Used to pad codes.</summary>
      kPaddingCharacter   = '0';
      /// <summary>The character set used to encode codes.</summary>
      kAlphabet: array[0..19] of Char = ('2','3','4','5','6','7','8','9','C','F','G','H','J','M','P','Q','R','V','W','X');
      /// <summary>The minimum number of digits in a code.</summary>
      kMinimumDigitCount = 2;
      /// <summary>The maximum number of digits in a code.</summary>
      kMaximumDigitCount = 15;
      /// <summary>The number of digits for paired lat/lng.</summary>
      kPairCodeLength:NativeInt = 10;
      /// <summary>The number of digits for the grid refinement.</summary>
      kGridCodeLength:NativeInt = 5;
      /// <summary>Number of columns in the grid.</summary>
      kGridCols:NativeInt = OLC_kGridCols;
      /// <summary>Number of rows in the grid.</summary>
      kGridRows:NativeInt = OLC_kEncodingBase div OLC_kGridCols;
      /// <summary>The position of the separator in a full code.</summary>
      kSeparatorPosition = 8;
      /// <summary></summary>
      kPairPrecisionInverse = 8000;    // 1 / 0.000125 degrees
      /// <summary></summary>
      kGridLatPrecisionInverse: Int64 = OLC_kGridLatPrecisionInverse;
      /// <summary>Inverse of the precision of the pair digits.</summary>
      kGridLonPrecisionInverse: Int64 = OLC_kGridLonPrecisionInverse;
    {$endregion}
    // size_t OLC_CodeLength(const char* code, size_t size);
    /// <param name="Code">The Plus Code to check.</param>
    /// <returns>The number of significant digits, or 0 if the code is invalid.</returns>
    class function CodeLength(const Code: string): Integer; static;

    // int OLC_IsValid(const char* code, size_t size);
    /// <summary>Determines if a code is valid.</summary>
    /// <returns>True if the string is valid Open Location Code.</returns>
    /// <param name="Code">The string to check.</param>
    /// <remarks> To be valid, all characters must be from the Open Location Code character
    /// set with at most one separator. The separator can be in any even-numbered
    /// position up to the eighth digit.
    ///</remarks>
    class function IsValid(const Code: string): Boolean; static;

    //i nt OLC_IsShort(const char* code, size_t size);
    /// <summary>Determines if a code is a valid short code.</summary>
    /// <returns>True if the string can be produced by removing four or more characters
    /// from the start of a valid code.</returns>
    /// <param name="Code">The string to check.</param>
    class function IsShort(const Code: string): Boolean; static;

    //int OLC_IsFull(const char* code, size_t size);
    /// <summary>Determines if a code is a valid full Open Location Code.</summary>
    /// <returns>True if the code represents a valid latitude and longitude combination.
    /// <param name="Code">The string to check.</param>
    class function IsFull(const Code: string): Boolean; static;

    // void OLC_GetCenter(const OLC_CodeArea* area,  TOLCLatLon* center);
    /// <summary>Computes the center of a decoded code area.</summary>
    /// <param name="Area">The code area.</param>
    /// <param name="Center">The output  TOLCLatLon for the center coordinates.</param>
    class procedure GetCenter(const Area: TOLCCodeArea; out Center:  TOLCLatLon); static;

    /// <summary>
    /// Calculates the OLC code for a neighboring cell in a specified direction.
    /// </summary>
    /// <param name="FullCode">The original, valid Full Open Location Code.</param>
    /// <param name="Direction">The direction of the neighbor to find.</param>
    /// <returns>The Plus Code of the neighboring cell, or an empty string if the original code is invalid or the neighbor is out of bounds
    /// (e.g., north of the North Pole).</returns>
    class function GetNeighbor(const FullCode: string; Direction: TOLCNeighborType): string; static;

    /// <summary>
    /// Calculates the OLC codes for a neighboring cells in a specified directions.
    /// </summary>
    /// <param name="FullCode">The original, valid Full Open Location Code.</param>
    /// <param name="Neighbors">set of neighbors to find.</param>
    /// <returns> string array with the Plus Codes of the neighboring cells, if the neighbor is out of bounds its code becomes empty string.
    /// if code is invalid mettod returns nil.
    /// </returns>
    class function GetNeighbors(const FullCode: string; Neighbors: TOLCNeighbors = [ntNorth, ntSouth, ntEast, ntWest]): TStringDynArray; static;

    /// <summary>Calculates the OLC code for the cell to the north.</summary>
    class function GetNorthNeighbor(const Code: string): string; static;
    /// <summary>Calculates the OLC code for the cell to the south.</summary>
    class function GetSouthNeighbor(const Code: string): string; static;
    /// <summary>Calculates the OLC code for the cell to the east.</summary>
    class function GetEastNeighbor(const Code: string): string; static;
    /// <summary>Calculates the OLC code for the cell to the west.</summary>
    class function GetWestNeighbor(const Code: string): string; static;

    // int OLC_Encode(const  TOLCLatLon* location, size_t length, char* code, int maxlen);
    /// <summary>Encodes a location into an Open Location Code.</summary>
    /// <param name="Location">The latitude and longitude to encode.</param>
    /// <param name="CodeLength">The desired number of significant digits in the code.</param>
    /// <param name="Code">The output string for the encoded Plus Code.</param>
    /// <returns>The length of the generated code.</returns>
    class function Encode(const Location:  TOLCLatLon; CodeLength: Integer; out Code: string): Integer; overload; static;

    // int OLC_EncodeDefault(const  TOLCLatLon* location, char* code, int maxlen);
    /// <summary>Encodes a location into a default-length Open Location Code (10 digits).</summary>
    /// <param name="Location">The latitude and longitude to encode.</param>
    /// <param name="Code">The output string for the encoded Plus Code.</param>
    /// <returns>The length of the generated code.</returns>
    class function EncodeDefault(const Location:  TOLCLatLon; out Code: string): Integer; static;

    // int OLC_Decode(const char* code, size_t size, OLC_CodeArea* decoded);
    /// <summary>Decodes an Open Location Code into a code area.</summary>
    /// <param name="Code">The Plus Code to decode.</param>
    /// <param name="Area">The output OLC_CodeArea representing the decoded region.</param>
    /// <returns>The number of significant digits in the code, or 0 if invalid.</returns>
    class function Decode(const Code: string; out Area: TOLCCodeArea): Integer; static;

    /// <summary>
    /// Calculates the optimal OLC code length to achieve a desired precision at a given location.
    /// </summary>
    /// <param name="Latitude">The latitude of the location.</param>
    /// <param name="Longitude">The longitude of the location.</param>
    /// <param name="CellSizeInMeters">The desired cell size (precision) in meters.</param>
    /// <returns>The recommended code length (an even number from 2 to 15).</returns>
    class function OptimalCodeLength(const Latitude, Longitude, CellSizeInMeters: Double): Integer; overload; static;

    /// <summary>
    /// Calculates the optimal OLC code length for a predefined precision level.
    /// </summary>
    /// <param name="Latitude">The latitude of the location.</param>
    /// <param name="Longitude">The longitude of the location.</param>
    /// <param name="Precision">The predefined precision level (e.g., pcMeters).</param>
    /// <returns>The recommended code length.</returns>
    class function OptimalCodeLength(Latitude, Longitude: Double; Precision: TOLCPrecision): Integer; overload; static;

    // int OLC_Shorten(const char* code, size_t size,const  TOLCLatLon* ref, char* buf, int maxlen);
    /// <summary>Removes characters from the start of an OLC code.</summary>
    /// <param name="Code">A full, valid Plus Code.</param>
    /// <param name="Location">The reference location (latitude and longitude).</param>
    /// <param name="ShortCode">The output string for the shortened code.</param>
    /// <returns>The length of the shortened code, or 0 if it cannot be shortened.</returns>
    /// <remarks>This removes pairs of characters from the start of the code as long as
    /// the center of the code area is within a defined range of the reference location.</remarks>
    class function Shorten(const Code: string; const Location:  TOLCLatLon; out ShortCode: string): Integer; static;

    // int OLC_RecoverNearest(const char* short_code, size_t size, const  OLC_LatLon* reference, char* code, int maxlen);
    /// <summary>Recovers a full Open Location Code from a short code.</summary>
    /// <param name="ShortCode">A valid short Plus Code.</param>
    /// <param name="Reference">The reference location used to expand the short code.</param>
    /// <param name="FullCode">The output string for the recovered full code.</param>
    /// <returns>The length of the recovered code, or 0 if the short code is invalid.</returns>
    class function RecoverNearest(const ShortCode: string; const Reference:  TOLCLatLon; out FullCode: string): Integer; static;

  private
    /// <summary>
    /// Returns the position of a char in the encoding alphabet, or -1 if invalid.
    /// </summary>
    class function AlphabetIndex(C: Char): Integer; static;

    /// <summary>
    /// Adjusts 90 degree latitude to be lower so that a legal OLC code can be generated.
    /// </summary>
    class function AdjustLatitude(LatDegrees: Double; EffectiveLength: Integer): Double; static;

    /// <summary>Compute the latitude precision value for a given code length.
    /// </summary>
    class function ComputeLatitudePrecision(Length: Integer): Double; static;
    // int OLC_EncodeIntegers(const OLC_LatLonIntegers* location, size_t length, char* code, int maxlen);
    /// <summary>
    /// Encodes a location into an Open Location Code from its integer representation.
    /// Returns the length of the code. This is an internal helper function.
    /// </summary>
    /// <param name="Location">The integer location to encode.</param>
    /// <param name="CodeLength">The desired number of digits in the code.</param>
    /// <param name="Code">The output string for the encoded Plus Code.</param>
    /// <returns>The length of the generated code.</returns>
    class function EncodeIntegers(const Location: TOLCLatLonIntegers; CodeLength: Integer; out Code: string): Integer; static;

    /// <summary>Normalize a longitude into the range -180 to 180, not including 180.
    /// </summary>
    class function NormalizeLongitude(LonDegrees: Double): Double; static;

    // void OLC_LocationToIntegers(const  TOLCLatLon* degrees, OLC_LatLonIntegers* integers);
    /// <summary>
    /// Converts a location in degrees into the integer values necessary for encoding.
    /// This is an internal helper function.
    /// </summary>
    class procedure LocationToIntegers(const Degrees:  TOLCLatLon; out Integers: TOLCLatLonIntegers); static;
  end;

implementation

{$region '  TOLCLatLon'}

{  TOLCLatLon }

class function  TOLCLatLon.Create(const ALat, ALon: Double):  TOLCLatLon;
begin
  Result.Lat := ALat;
  Result.Lon := ALon;
end;
{$endregion}

{$region '  TOLCCodeArea'}

{ TOLCCodeArea }

class function TOLCCodeArea.CreateMeters(const center: TOLCLatLon; widthMeters, heightMeters: Double): TOLCCodeArea;
var
  halfWidth, halfHeight, cellSize: Double;
  northPoint, southPoint, eastPoint, westPoint, centerPoint: TOLCLatLon;
begin
  halfWidth := widthMeters * 0.5;
  halfHeight := heightMeters * 0.5;

  // Calculate the four extreme points by moving from the center along cardinal directions.
  // 0 degrees is North, 90 is East, 180 is South, 270 is West.
  northPoint := TOLCGeoCalc.CalculateDestination(center, 0,   halfHeight);
  southPoint := TOLCGeoCalc.CalculateDestination(center, 180, halfHeight);
  eastPoint  := TOLCGeoCalc.CalculateDestination(center, 90,  halfWidth);
  westPoint  := TOLCGeoCalc.CalculateDestination(center, 270, halfWidth);

  // The CodeArea is defined by its South-West (Lo) and North-East (Hi) corners.
  Result.Lo.Lat := southPoint.Lat;
  Result.Lo.Lon := westPoint.Lon;
  Result.Hi.Lat := northPoint.Lat;
  Result.Hi.Lon := eastPoint.Lon;

  centerPoint := Result.GetCenter;
  // Determine the required precision in meters. It should be at least as precise as the largest dimension of the area.
  cellSize := Max(widthMeters, heightMeters);
  // Calculate the optimal code length for this precision at the given center.
  Result.CodeLength := TOLC.OptimalCodeLength(centerPoint.Lat, centerPoint.Lon, cellSize);
end;

function TOLCCodeArea.GetCenter: TOLCLatLon;
var
  CenterLat, CenterLon: Double;
begin
  CenterLat := Lo.Lat + (Hi.Lat - Lo.Lat) / 2.0;
  CenterLon := Lo.Lon + (Hi.Lon - Lo.Lon) / 2.0;

  // Normalize longitude to handle wrapping around the 180th meridian.
  while CenterLon < -180 do CenterLon := CenterLon + 360;
  while CenterLon >= 180 do CenterLon := CenterLon - 360;

  Result.Lat := CenterLat;
  Result.Lon := CenterLon;
end;

function TOLCCodeArea.GetEastLongitude: Double;
begin
  Result := Hi.Lon;
end;

function TOLCCodeArea.GetHeight: Double;
var
  startPoint, endPoint: TOLCLatLon;
  dist, az1, az2: Double;
begin
  // Height is the distance between North and South latitudes along a meridian.
  startPoint.Lat := Hi.Lat;
  startPoint.Lon := Lo.Lon;
  endPoint.Lat := Lo.Lat;
  endPoint.Lon := Lo.Lon;

  if TOLCGeoCalc.CalculateInverse(startPoint, endPoint, dist, az1, az2) then
    Result := dist
  else
    Result := 0;
end;

function TOLCCodeArea.GetLocation: TOLCLatLon;
begin
  // Location is the top-left (North-West) corner.
  Result.Lat := Hi.Lat;
  Result.Lon := Lo.Lon;
end;

function TOLCCodeArea.GetNorthLatitude: Double;
begin
  Result := Hi.Lat;
end;

function TOLCCodeArea.GetSize: TSizeF;
begin
  Result.Width := GetWidth;
  Result.Height := GetHeight;
end;

function TOLCCodeArea.GetSouthLatitude: Double;
begin
  Result := Lo.Lat;
end;

function TOLCCodeArea.GetWestLongitude: Double;
begin
  Result := Lo.Lon;
end;

function TOLCCodeArea.GetWidth: Double;
var
  startPoint, endPoint: TOLCLatLon;
  dist, az1, az2: Double;
begin
  // Calculate width at the center latitude for better accuracy.
  startPoint.Lat := Lo.Lat + (Hi.Lat - Lo.Lat) / 2.0;
  startPoint.Lon := Lo.Lon;
  endPoint.Lat := startPoint.Lat;
  endPoint.Lon := Hi.Lon;

  if TOLCGeoCalc.CalculateInverse(startPoint, endPoint, dist, az1, az2) then
    Result := dist
  else
    Result := 0;
end;

function TOLCCodeArea.Offset(const XMeters, YMeters: Double): TOLCCodeArea;
var
  currentCenter, newCenter: TOLCLatLon;
  distance, azimuthRad, azimuthDeg: Double;
begin
  // Start with a copy of the current area.
  Result := Self;

  // No offset, return the copy immediately.
  if (XMeters = 0) and (YMeters = 0) then
    Exit;

  // Get the current center of the area.
  currentCenter := Self.GetCenter;

  // Calculate the total distance and bearing (azimuth) of the offset.
  // DX corresponds to East (Y-axis in cartesian plane for ArcTan2), DY to North (X-axis).
  distance := Sqrt(Sqr(XMeters) + Sqr(YMeters));
  azimuthRad := ArcTan2(XMeters, YMeters);
  azimuthDeg := RadToDeg(azimuthRad);

  // Normalize azimuth to the range [0, 360)
  if azimuthDeg < 0 then
    azimuthDeg := azimuthDeg + 360;

  // Calculate the new center point using the direct geodetic problem.
  newCenter := TOLCGeoCalc.CalculateDestination(currentCenter, azimuthDeg, distance);

  // Set the new center for the resulting area.
  // The SetCenter method preserves the area's dimensions in degrees.
  Result.Center := newCenter;
end;

procedure TOLCCodeArea.SetCenter(const Value: TOLCLatLon);
var
  Height, Width: Double;
  HalfHeight, HalfWidth: Double;
begin
  // Calculate the current dimensions of the area in degrees.
  Height := Hi.Lat - Lo.Lat;
  Width := Hi.Lon - Lo.Lon;
  HalfHeight := Height / 2.0;
  HalfWidth := Width / 2.0;

  // Calculate the new corner coordinates based on the new center.
  Lo.Lat := Value.Lat - HalfHeight;
  Hi.Lat := Value.Lat + HalfHeight;
  Lo.Lon := Value.Lon - HalfWidth;
  Hi.Lon := Value.Lon + HalfWidth;
end;

procedure TOLCCodeArea.SetEastLongitude(const Value: Double);
begin
  Hi.Lon := Value;
end;

procedure TOLCCodeArea.SetHeight(const Value: Double);
var
  topLeft: TOLCLatLon;
  newBottomLeft: TOLCLatLon;
begin
  // Anchor point is the top-left corner.
  topLeft.Lat := Hi.Lat;
  topLeft.Lon := Lo.Lon;

  // Calculate the new bottom-left corner by moving South.
  newBottomLeft := TOLCGeoCalc.CalculateDestination(topLeft, 180.0, Value);

  // Update the South latitude.
  Lo.Lat := newBottomLeft.Lat;
end;


procedure TOLCCodeArea.SetLocation(const Value: TOLCLatLon);
var
  widthDeg, heightDeg: Double;
begin
  // Calculate current dimensions in degrees.
  heightDeg := Hi.Lat - Lo.Lat;
  widthDeg := Hi.Lon - Lo.Lon;

  // Set the new top-left corner.
  Hi.Lat := Value.Lat;
  Lo.Lon := Value.Lon;

  // Recalculate other corners to preserve size.
  Lo.Lat := Hi.Lat - heightDeg;
  Hi.Lon := Lo.Lon + widthDeg;
end;

procedure TOLCCodeArea.SetNorthLatitude(const Value: Double);
begin
  Hi.Lat := Value;
end;

procedure TOLCCodeArea.SetSize(const Value: TSizeF);
begin
  // This changes the size relative to the top-left corner.
  SetHeight(Value.Height);
  SetWidth(Value.Width);
end;

procedure TOLCCodeArea.SetSouthLatitude(const Value: Double);
begin
  Lo.Lat := Value;
end;

procedure TOLCCodeArea.SetWestLongitude(const Value: Double);
begin
  Lo.Lon := Value;
end;

procedure TOLCCodeArea.SetWidth(const Value: Double);
var
  topLeft: TOLCLatLon;
  newTopRight: TOLCLatLon;
begin
  // Anchor point is the top-left corner.
  topLeft.Lat := Hi.Lat;
  topLeft.Lon := Lo.Lon;

  // Calculate the new top-right corner by moving East.
  newTopRight := TOLCGeoCalc.CalculateDestination(topLeft, 90.0, Value);

  // Update the East longitude.
  Hi.Lon := newTopRight.Lon;
end;

{$endregion}

{$region '  TOLC'}

{ TOLC }

class function TOLC.AlphabetIndex(C: Char): Integer;
begin
  C := UpCase(C);
  if (C >= 'C') and (C <= 'X') then
    Exit(OLC_kAlphabetPositionLUT[C]);
  if (C >= '2') and (C <= '9') then
    Exit(Ord(C) - Ord('2'));
  Result := -1;
end;

class function TOLC.NormalizeLongitude(LonDegrees: Double): Double;
var
  Max2: Double;
begin
  Max2 := 2 * OLC_kLonMaxDegrees;
  Result := LonDegrees;
  while Result < -OLC_kLonMaxDegrees do
    Result := Result + Max2;
  while Result >= OLC_kLonMaxDegrees do
    Result := Result - Max2;
end;

class function TOLC.OptimalCodeLength(const Latitude, Longitude, CellSizeInMeters: Double): Integer;
var
  len: Integer;
  latPrecisionDeg, lonPrecisionDeg: Double;
  cellHeightMeters, cellWidthMeters: Double;
  latRad: Double;
  dist, az1, az2: Double;
  p1, p2: TOLCLatLon;
begin
  // We are looking for the shortest code length that provides the required precision.
  len := kMinimumDigitCount;
  while len < kMaximumDigitCount do
  begin
    // Find cell dimensions in degrees for the current code length.
    latPrecisionDeg := ComputeLatitudePrecision(len);
    lonPrecisionDeg := ComputeLatitudePrecision(len);

    // Calculate cell size in meters with high accuracy ---
    latRad := DegToRad(Latitude);

    // Height calculation using Vincenty inverse formula
    p1.Lat := Latitude;
    p1.Lon := Longitude;
    p2.Lat := Latitude + latPrecisionDeg;
    p2.Lon := Longitude;
    if TOLCGeoCalc.CalculateInverse(p1, p2, dist, az1, az2) then
      cellHeightMeters := dist
    else
      cellHeightMeters := latPrecisionDeg * 111320.0; // Fallback approximation

    // Width calculation using Vincenty inverse formula
    p2.Lat := Latitude;
    p2.Lon := Longitude + lonPrecisionDeg;
    if TOLCGeoCalc.CalculateInverse(p1, p2, dist, az1, az2) then
      cellWidthMeters := dist
    else
      cellWidthMeters := lonPrecisionDeg * 111320.0 * Cos(latRad); // Fallback

    // Check if the largest dimension of the cell is within the desired precision.
    if Max(cellHeightMeters, cellWidthMeters) <= CellSizeInMeters then
    begin
      // We found the first (shortest) length that is precise enough.
      Result := len;
      Exit;
    end;

    // Move to the next level of precision.
    // For pair codes (<= 10), the length must be even, so we jump by 2.
    if len < kPairCodeLength then
      Inc(len, 2)
    else
      Inc(len); // For grid codes (> 10), length can be odd or even.
  end;

  // Default Fallback
  // If the loop completes, it means the desired precision is higher than
  // what the longest code can provide. In this case, return the maximum possible code length as a default.
  Result := kMaximumDigitCount;
end;

class function TOLC.OptimalCodeLength(Latitude, Longitude: Double; Precision: TOLCPrecision): Integer;
var
  PrecisionMeters: Double;
begin
  case Precision of
    pcHundredsOfMeters: PrecisionMeters := 250.0;  // Corresponds to length 8
    pcTensOfMeters:     PrecisionMeters := 15.0;   // Corresponds to length 10
    pcMeters:           PrecisionMeters := 3.0;    // Corresponds to length 11
    pcCentimeters:      PrecisionMeters := 0.25;   // Corresponds to length 13
    pcMillimeters:      PrecisionMeters := 0.005;  // Corresponds to length 15
  else
    PrecisionMeters := 0.005; // Default to millimeters
  end;

  Result := OptimalCodeLength(Latitude, Longitude, PrecisionMeters);
end;

class function TOLC.AdjustLatitude(LatDegrees: Double; EffectiveLength: Integer): Double;
var
  Prec: Double;
begin
  if LatDegrees < -OLC_kLatMaxDegrees then
    LatDegrees := -OLC_kLatMaxDegrees;
  if LatDegrees > OLC_kLatMaxDegrees then
    LatDegrees := OLC_kLatMaxDegrees;

  if LatDegrees < OLC_kLatMaxDegrees then
    Exit(LatDegrees);

  Prec := ComputeLatitudePrecision(EffectiveLength);
  Result := LatDegrees - Prec * 0.5;
end;

class function TOLC.ComputeLatitudePrecision(Length: Integer): Double;
var Exponent: Integer;
begin
  // From olc.c: if (length <= kPairCodeLength)
  //       return pow_neg(kEncodingBase, floor((length / -2) + 2));
  //    else
  //       return pow_neg(kEncodingBase, -3) / pow(kGridRows, length - 10);
  if Length <= kPairCodeLength then
  begin
    // Replaced Power() with LUT lookups
{
    Exponent := Floor((Length / -2.0) + 2.0); // negative power
    else if Exponent > 0 then
      Result := Power(OLC_kEncodingBase, Exponent)
    else
      Result := 1.0 / Power(OLC_kEncodingBase, -Exponent);
}

    Exponent := Floor((Length / -2.0) + 2.0);
    if Exponent >= 0 then
      Result := POWER_20_TABLE[Exponent]
    else
      Result := INV_POWER_20_TABLE[-Exponent];
  end
  else
  begin
    // base^-3 / (gridRows^(len-10))
    // For grid part, using Power is acceptable as it's only called for >10 length codes.
    // but it can also be optimized if it becomes a bottleneck.
    Result := INV_POWER_20_TABLE[3] / Power(kGridRows, Length - kPairCodeLength);
{
    Result := 1.0 / Power(OLC_kEncodingBase, 3);
    Result := Result / Power(kGridRows, Length - kPairCodeLength);
}
  end;
end;

class procedure TOLC.GetCenter(const Area: TOLCCodeArea; out Center:  TOLCLatLon);
begin
  Center.Lat := Area.Lo.Lat + (Area.Hi.Lat - Area.Lo.Lat) / 2.0;
  if Center.Lat > OLC_kLatMaxDegrees then
    Center.Lat := OLC_kLatMaxDegrees;

  Center.Lon := Area.Lo.Lon + (Area.Hi.Lon - Area.Lo.Lon) / 2.0;
  if Center.Lon > OLC_kLonMaxDegrees then
    Center.Lon := OLC_kLonMaxDegrees;
end;

class function TOLC.GetEastNeighbor(const Code: string): string;
begin
  Result := GetNeighbor(Code, ntEast);
end;

class function TOLC.GetNeighbor(const FullCode: string; Direction: TOLCNeighborType): string;
var
  Area: TOLCCodeArea;
  Center, NewCenter: TOLCLatLon;
  CodeLen: Integer;
  CellHeight, CellWidth: Double;
  LatStep, LonStep: Integer;
begin
  Result := '';

  // Decode the original code to get its properties.
  // The code must be a valid full code to have neighbors.
  if not IsFull(FullCode) then
    Exit;

  if Decode(FullCode, Area) <= 0 then
    Exit;

  // 2. Get the center of the area and its dimensions.
  GetCenter(Area, Center);
  CellHeight := Area.Hi.Lat - Area.Lo.Lat;
  CellWidth := Area.Hi.Lon - Area.Lo.Lon;

  // The code length to be used for the new code is the length of the *clean* code.
  CodeLen := Area.CodeLength;

  // Determine the shift in latitude and longitude based on direction.
  LatStep := 0;
  LonStep := 0;
  case Direction of
    ntNorth:     LatStep := 1;
    ntSouth:     LatStep := -1;
    ntEast:      LonStep := 1;
    ntWest:      LonStep := -1;
    ntNorthEast: begin LatStep := 1;  LonStep := 1; end;
    ntNorthWest: begin LatStep := 1;  LonStep := -1; end;
    ntSouthEast: begin LatStep := -1; LonStep := 1; end;
    ntSouthWest: begin LatStep := -1; LonStep := -1; end;
  end;

  // Calculate the new center point.
  NewCenter.Lat := Center.Lat + LatStep * CellHeight;
  NewCenter.Lon := Center.Lon + LonStep * CellWidth;

  // Handle boundary conditions.
  // Check latitude: A neighbor cannot exist beyond the poles.
  if (NewCenter.Lat >= OLC_kLatMaxDegrees) or (NewCenter.Lat <= -OLC_kLatMaxDegrees) then
    Exit; // No neighbor beyond the poles.

  // Normalize longitude to wrap around the globe.
  NewCenter.Lon := NormalizeLongitude(NewCenter.Lon);

  // Encode the new center point with the same code length.
  Encode(NewCenter, CodeLen, Result);
end;

class function TOLC.GetNeighbors(const FullCode: string; Neighbors: TOLCNeighbors): TStringDynArray;
var t: TOLCNeighborType;
begin
  Result := nil;
  if not IsFull(FullCode) then
    Exit;

  for t := Low(TOLCNeighborType) to High(TOLCNeighborType) do
  begin
    if t in Neighbors  then
      Result := Result + [GetNeighbor(FullCode,t)];
  end;
end;

class function TOLC.GetNorthNeighbor(const Code: string): string;
begin
  Result := GetNeighbor(Code, ntNorth);
end;

class function TOLC.GetSouthNeighbor(const Code: string): string;
begin
  Result := GetNeighbor(Code, ntSouth);
end;

class function TOLC.GetWestNeighbor(const Code: string): string;
begin
  Result := GetNeighbor(Code, ntWest);
end;

class function TOLC.IsValid(const Code: string): Boolean;
var
  I, CodeLen, SepPos, PadPos, FirstChar,LastChar : Integer;
  Ch: Char;
  HasPadding: Boolean;
begin
  Result := False;
  CodeLen := Length(Code);

  // Find first and last non-space characters
  FirstChar := 1;
  LastChar := CodeLen;
  while (FirstChar <= LastChar) and (Code[FirstChar] = ' ') do Inc(FirstChar);
  while (LastChar >= FirstChar) and (Code[LastChar] = ' ') do Dec(LastChar);

  CodeLen := LastChar - FirstChar + 1;
  if CodeLen < 2 then Exit;

  SepPos := 0;
  PadPos := 0;
  HasPadding := False;

  for I := 0 to CodeLen - 1 do
  begin
    Ch := Code[FirstChar + I];
    if Ch = kSeparator then
    begin
      // More than one separator found
      if SepPos > 0 then Exit;
      SepPos := I + 1; // 1-based position
    end
    else if Ch = kPaddingCharacter then
    begin
      HasPadding := True;
      // Store position of first padding char
      if PadPos = 0 then PadPos := I + 1;
    end
    else if AlphabetIndex(UpCase(Ch)) = -1 then
    begin
      // Invalid character found
      Exit;
    end;
  end;

  // Check separator rules
  if (SepPos = 0) or (SepPos > (kSeparatorPosition + 1)) or Odd(SepPos-1) then
    Exit;

  // Check padding rules
  if HasPadding then
  begin
    // Padding cannot be at the start or after the separator
    if (PadPos = 1) or (PadPos > SepPos) then Exit;
    // If padding exists, separator must be the last character
    if SepPos < CodeLen then Exit;
  end;

  // Exactly one character after separator is not allowed
  if (CodeLen - SepPos) = 1 then
    Exit;

  Result := True;
end;

class function TOLC.IsShort(const Code: string): Boolean;
var
  S: string;
  SepPos: Integer;
begin
  S := Trim(Code);
  if not IsValid(S) then
    Exit(False);
  SepPos := Pos(kSeparator, S);
  Result := (SepPos > 0) and ((SepPos - 1) < kSeparatorPosition);
end;

class function TOLC.IsFull(const Code: string): Boolean;
var
  S: string;
  SepPos: Integer;
  FirstLat, FirstLng: Integer;
begin
  S := Trim(Code);
  if not IsValid(S) then
    Exit(False);
  if IsShort(S) then
    Exit(False);

  SepPos := Pos(kSeparator, S);
  if SepPos < 2 then
    Exit(False);

  FirstLat := AlphabetIndex(S[1]) * OLC_kEncodingBase;
  if FirstLat >= Trunc(OLC_kLatMaxDegrees * 2.0) then
    Exit(False);

  FirstLng := AlphabetIndex(S[2]) * OLC_kEncodingBase;
  if FirstLng >= Trunc(OLC_kLonMaxDegrees * 2.0) then
    Exit(False);

  Result := True;
end;

class function TOLC.CodeLength(const Code: string): Integer;
var
  S: string;
  SepPos, I, FirstPad: Integer;
begin
  if not IsValid(Code) then
    Exit(0);
  S := Trim(Code);
  SepPos := Pos(kSeparator, S);
  FirstPad := 0;
  for I := 1 to SepPos - 1 do
    if S[I] = kPaddingCharacter then
    begin
      FirstPad := I;
      Break;
    end;

  if FirstPad > 0 then
    Result := FirstPad - 1
  else
    Result := SepPos - 1;

   // Add the number of characters after the separator.
  Result := Result + (Length(S) - SepPos);
end;

class procedure TOLC.LocationToIntegers(
  const Degrees:  TOLCLatLon; out Integers: TOLCLatLonIntegers);
var
  Lat, Lon: Int64;
begin
  // See OLC_LocationToIntegers in olc.c
  Lat := Trunc(Degrees.Lat * kGridLatPrecisionInverse);
  Lon := Trunc(Degrees.Lon * kGridLonPrecisionInverse);

  Lat := Lat + kGridLatScale;
  if Lat < 0 then
    Lat := 0
  else
  if Lat >= kGridLatScaleMax then
    Lat := kGridLatScaleMax -1;

  Lon := Lon + kGridLonScale;
  if Lon < 0 then
    Lon := (Lon mod kGridLonScaleMax) + kGridLonScaleMax
  else if Lon >= kGridLonScaleMax then
    Lon := Lon mod kGridLonScaleMax;

  Integers.Lat := Lat;
  Integers.Lon := Lon;
end;

class function TOLC.EncodeIntegers(const Location: TOLCLatLonIntegers; CodeLength: Integer; out Code: string): Integer;

var
  LengthClamped: Integer;
  Lat, Lon: Int64;
  FullCode: array[0..kMaximumDigitCount + 1] of Char; // + '+', + #0
  I, LatDigit, LngDigit, DCount: Integer;
begin
  // See int OLC_EncodeIntegers(...) in olc.c

  LengthClamped := CodeLength;
  if LengthClamped > kMaximumDigitCount then
    LengthClamped := kMaximumDigitCount;
  if LengthClamped < kMinimumDigitCount then
    LengthClamped := kMinimumDigitCount;
  if (LengthClamped < kPairCodeLength) and Odd(LengthClamped) then
    Inc(LengthClamped);

  Lat := Location.Lat;
  Lon := Location.Lon;

  // Initialize the temporary buffer.
  for I := 0 to High(FullCode) do
    FullCode[I] := ' ';

  // Place the separator.
  FullCode[kSeparatorPosition] := kSeparator;

  // Encode the grid part if necessary.
  if LengthClamped > kPairCodeLength then
  begin
    for I := kMaximumDigitCount - kPairCodeLength downto 1 do
    begin
      LatDigit := Lat mod kGridRows;
      LngDigit := Lon mod kGridCols;
      FullCode[kSeparatorPosition + 2 + I] :=
        kAlphabet[LatDigit * kGridCols + LngDigit];
      Lat := Lat div kGridRows;
      Lon := Lon div kGridCols;
    end;
  end
  else
  begin
    Lat := Lat div GRID_ROWS_POW_GRID_CODE_LENGTH;
    Lon := Lon div GRID_COLS_POW_GRID_CODE_LENGTH;
  end;

  // Encode the pair after the separator.
  FullCode[kSeparatorPosition + 1] := kAlphabet[Lat mod OLC_kEncodingBase];
  FullCode[kSeparatorPosition + 2] := kAlphabet[Lon mod OLC_kEncodingBase];
  Lat := Lat div OLC_kEncodingBase;
  Lon := Lon div OLC_kEncodingBase;

  // Encode the pair part before the separator in reverse order.
  I := kSeparatorPosition - 2;
  while I >= 0 do
  begin
    FullCode[I + 1] := kAlphabet[Lon mod OLC_kEncodingBase];
    FullCode[I] := kAlphabet[Lat mod OLC_kEncodingBase];
    Lon := Lon div OLC_kEncodingBase;
    Lat := Lat div OLC_kEncodingBase;
    Dec(I, 2);
  end;

  // Add padding with zeros if the code is less than 8 characters.
  if LengthClamped < kSeparatorPosition then
  begin
    for I := LengthClamped to kSeparatorPosition - 1 do
      FullCode[I] := kPaddingCharacter;
    LengthClamped := kSeparatorPosition;
  end;

  // Copy to the output string.
  SetLength(Code, LengthClamped + 1);  // including separator
  DCount := LengthClamped + 1;
  for I := 0 to DCount - 1 do
    Code[I + 1] := FullCode[I];

  Result := LengthClamped;
end;

class function TOLC.Encode(const Location:  TOLCLatLon; CodeLength: Integer; out Code: string): Integer;
var Ints: TOLCLatLonIntegers;
begin
  LocationToIntegers(Location, Ints);
  Result := EncodeIntegers(Ints, CodeLength, Code);
end;

class function TOLC.EncodeDefault(
  const Location:  TOLCLatLon; out Code: string): Integer;
begin
  Result := Encode(Location, kPairCodeLength, Code);
end;

class function TOLC.Decode(
  const Code: string; out Area: TOLCCodeArea): Integer;
var
  Clean: string;
  I, CleanLen, CleanIdx: Integer;
  NormalLat, NormalLng, ExtraLat, ExtraLng: Int64;
  Digits: Integer;
  PV, RowPV, ColPV: Int64;
  DVal, Row, Col: Integer;
  LatPrec, LngPrec: Double;
  Lat, Lng: Double;

    // Pre-calculated powers for performance.
  const PV_INIT = 3200000; // Power(20, 5)
  const ROW_PV_INIT = 3125;   // Power(5, 5)
  const COL_PV_INIT = 1024;   // Power(4, 5)
begin
  Result := 0;
  if not IsFull(Code) then
    Exit;

  // Efficiently create a "clean" version of the code without padding and separator.
  CleanLen := 0;
  Digits := Length(Code);
  for I := 1 to Digits do
  begin
    if (Code[I] <> kPaddingCharacter) and (Code[I] <> kSeparator) then
      Inc(CleanLen);
  end;

  SetLength(Clean, CleanLen);

  CleanIdx := 1;
  for I := 1 to Digits do
  begin
    if (Code[I] <> kPaddingCharacter) and (Code[I] <> kSeparator) then
    begin
      Clean[CleanIdx] := Code[I];
      Inc(CleanIdx);
    end;
  end;

  // See decode(...) in olc.c
  NormalLat := -OLC_kLatMaxDegrees * kPairPrecisionInverse;
  NormalLng := -OLC_kLonMaxDegrees * kPairPrecisionInverse;
  ExtraLat  := 0;
  ExtraLng  := 0;

  Digits := Min(Length(Clean), kPairCodeLength);

  // Place value for the most significant pair.
  PV := PV_INIT;
  I := 1;
  while I < Digits do
  begin
    PV := PV div OLC_kEncodingBase;
    DVal := AlphabetIndex(Clean[I]);
    NormalLat := NormalLat + DVal * PV;
    DVal := AlphabetIndex(Clean[I + 1]);
    NormalLng := NormalLng + DVal * PV;
    Inc(I, 2);
  end;

  LatPrec := PV / kPairPrecisionInverse;
  LngPrec := PV / kPairPrecisionInverse;

  if Length(Clean) > kPairCodeLength then
  begin
    Digits := Min(Length(Clean), kMaximumDigitCount);

    RowPV := ROW_PV_INIT;
    ColPV := COL_PV_INIT;

    for I := kPairCodeLength to Digits - 1 do
    begin
      RowPV := RowPV div kGridRows;
      ColPV := ColPV div kGridCols;
      DVal := AlphabetIndex(Clean[I + 1]);
      Row := DVal div kGridCols;
      Col := DVal mod kGridCols;
      ExtraLat := ExtraLat + Row * RowPV;
      ExtraLng := ExtraLng + Col * ColPV;
    end;

    LatPrec := RowPV / OLC_kGridLatPrecisionInverse;
    LngPrec := ColPV / OLC_kGridLonPrecisionInverse;
  end;

  Lat := NormalLat / kPairPrecisionInverse +
         ExtraLat / OLC_kGridLatPrecisionInverse;
  Lng := NormalLng / kPairPrecisionInverse +
         ExtraLng / OLC_kGridLonPrecisionInverse;

  Area.Lo.Lat := Lat;
  Area.Lo.Lon := Lng;
  Area.Hi.Lat := Lat + LatPrec;
  Area.Hi.Lon := Lng + LngPrec;
  Area.CodeLength := Length(Clean);

  Result := Area.CodeLength;
end;

class function TOLC.Shorten(const Code: string; const Location:  TOLCLatLon; out ShortCode: string): Integer;
var
  Center:  TOLCLatLon;
  Area: TOLCCodeArea;
  Lat, Lon, Range, AreaEdge: Double;
  RemovalLengths: array[0..2] of Integer;
  J, Start, I: Integer;
  S: string;
  SepPos: Integer;
begin
  Result := 0;
  ShortCode := '';

  S := Trim(Code);
  if not IsFull(S) then
    Exit;

   // If the code has padding, it cannot be shortened.
  SepPos := Pos(kSeparator, S);
  for I := 1 to SepPos - 1 do
    if S[I] = kPaddingCharacter then
      Exit;

  if Decode(S, Area) <= 0 then
    Exit;

  GetCenter(Area, Center);

  Lat := AdjustLatitude(Location.Lat, Area.CodeLength);
  Lon := NormalizeLongitude(Location.Lon);

  Range := Max(Abs(Center.Lat - Lat), Abs(Center.Lon - Lon));

  RemovalLengths[0] := 8;
  RemovalLengths[1] := 6;
  RemovalLengths[2] := 4;

  Start := 0;
  for J := Low(RemovalLengths) to High(RemovalLengths) do
  begin
    AreaEdge := ComputeLatitudePrecision(RemovalLengths[J]) * 0.3; // Safety factor
    if Range < AreaEdge then
    begin
      Start := RemovalLengths[J];
      Break;
    end;
  end;

  // If there's nothing to shorten, return the original code.
  if Start <= 0 then
  begin
    ShortCode := S;
    Result := Length(ShortCode);
    Exit;
  end;

  ShortCode := Copy(S, Start + 1, MaxInt);
  Result := Length(ShortCode);
end;

class function TOLC.RecoverNearest(const ShortCode: string; const Reference:  TOLCLatLon; out FullCode: string): Integer;
var
  S: string;
  SepPos, PaddingLength, Exponent: Integer;
  Resolution, HalfRes: Double;
  RefLat, RefLon: Double;
  NewCode: string;
  Area: TOLCCodeArea;
  Center:  TOLCLatLon;
begin
  Result := 0;
  FullCode := '';
  S := Trim(ShortCode);

  if S = '' then
    Exit;

  // If the code is not short, but a full code, just normalize it and return.
  if not IsShort(S) then
  begin
    if IsFull(S) then
    begin
      FullCode := UpperCase(S);
      Result := Length(FullCode);
    end;
    Exit;
  end;

  // Clip latitude to the valid range [-90; 90]
  RefLat := Reference.Lat;
  if RefLat < -OLC_kLatMaxDegrees then
    RefLat := -OLC_kLatMaxDegrees
  else if RefLat > OLC_kLatMaxDegrees then
    RefLat := OLC_kLatMaxDegrees;

  // Normalize longitude to the valid range [-180; 180].
  RefLon := NormalizeLongitude(Reference.Lon);

  // The reference implementation always converts the short code to uppercase.
  S := UpperCase(S);

  // Position of '+' (1-based) and the number of characters to recover from the left.
  SepPos := Pos(kSeparator, S);
  if SepPos <= 0 then
    Exit; // // Should not happen after IsShort check, but as a safeguard.

  // paddingLength = SEPARATOR_POSITION - indexOf('+') (indexOf – 0-based).
  PaddingLength := kSeparatorPosition - (SepPos - 1);

  // The resolution of the cell: 20^(2 - paddingLength/2)
  Exponent := 2 - (PaddingLength div 2);
  if Exponent >= 0 then
    Resolution := POWER_20_TABLE[Exponent]
  else
    Resolution := INV_POWER_20_TABLE[-Exponent];

  HalfRes := Resolution * 0.5;

  // Take the prefix from the full code of the reference location and append the short code.
  NewCode := '';
  EncodeDefault( TOLCLatLon.Create(RefLat, RefLon), NewCode);
  NewCode := Copy(NewCode, 1, PaddingLength) + S;

  // Decode the generated full code.
  if Decode(NewCode, Area) <= 0 then
    Exit;

  GetCenter(Area, Center);

  // Adjust latitude:
  // if (refLat + halfRes < centerLat && centerLat - res >= -LAT_MAX) centerLat -= res;
  // else if (refLat - halfRes > centerLat && centerLat + res <= LAT_MAX) centerLat += res;
  if (RefLat + HalfRes < Center.Lat) and
     (Center.Lat - Resolution >= -OLC_kLatMaxDegrees) then
    Center.Lat := Center.Lat - Resolution
  else if (RefLat - HalfRes > Center.Lat) and
          (Center.Lat + Resolution <= OLC_kLatMaxDegrees) then
    Center.Lat := Center.Lat + Resolution;

  // Adjust longitude:
  // if (refLon + halfRes < centerLon) centerLon -= res;
  // else if (refLon - halfRes > centerLon) centerLon += res;
  if RefLon + HalfRes < Center.Lon then
    Center.Lon := Center.Lon - Resolution
  else if RefLon - HalfRes > Center.Lon then
    Center.Lon := Center.Lon + Resolution;

  // Re-encode the adjusted center with the same code length.
  Result := Encode(Center, Area.CodeLength, FullCode);
end;
{$endregion}

{$region '  TOLCGeoCalc'}

{ TOLCGeoCalc }

class function TOLCGeoCalc.CalculateDestination(const startPoint: TOLCLatLon; azimuth, distance: Double): TOLCLatLon;
var
  phi1, L1, alpha1: Double;
  sinAlpha1, cosAlpha1: Double;
  tanU1, cosU1, sinU1: Double;
  sigma1, sinAlpha, cosSqAlpha, uSq: Double;
  A, B, sigma, sigmaP, cos2SigmaM, deltaSigma: Double;
  C, L, phi2, lambda: Double;
  iterLimit: Integer;

  cosSigma, sinSigma, B_div_4, B_div_6, sqSinSigma, sqCos2SigmaM: Double;
begin
  // Implementation of Vincenty's direct formula
  phi1 := DegToRad(startPoint.Lat);
  L1 := DegToRad(startPoint.Lon);
  alpha1 := DegToRad(azimuth);

  SinCos(alpha1, sinAlpha1, cosAlpha1);

  tanU1 := ONE_MINUS_F * Tan(phi1);
  cosU1 := 1 / Sqrt(1 + Sqr(tanU1));
  sinU1 := tanU1 * cosU1;

  sigma1 := ArcTan2(tanU1, cosAlpha1);
  sinAlpha := cosU1 * sinAlpha1;
  cosSqAlpha := 1 - Sqr(sinAlpha);
  // Use pre-calculated squared axes
  uSq := cosSqAlpha * (WGS84_A_SQ - WGS84_B_SQ) / WGS84_B_SQ;

  // Optimization: Pre-calculate coefficients for A and B polynomials
  // A = 1 + uSq/16384 * (4096 + uSq*(-768 + uSq*(320 - 175*uSq)))
  // B = uSq/1024 * (256 + uSq*(-128 + uSq*(74 - 47*uSq)))
  // No significant optimization here without changing the structure, but we ensure constants are used.
  A := 1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)));
  B := uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)));

  sigma := distance / (WGS84_B * A);
  iterLimit := 100;
  repeat
    sigmaP := sigma; // Store previous sigma

    // Optimization: Reduce redundant calculations...
    cos2SigmaM := Cos(2 * sigma1 + sigma);
    SinCos(sigma, sinSigma, cosSigma);
    sqCos2SigmaM := Sqr(cos2SigmaM);
    sqSinSigma := Sqr(sinSigma);
    B_div_4 := B / 4;
    B_div_6 := B / 6;

    deltaSigma := B * sinSigma * (cos2SigmaM + B_div_4 * (cosSigma * (-1 + 2 * sqCos2SigmaM) -
      B_div_6 * cos2SigmaM * (-3 + 4 * sqSinSigma) * (-3 + 4 * sqCos2SigmaM)));

    sigma := distance / (WGS84_B * A) + deltaSigma;
    Dec(iterLimit);
    if iterLimit = 0 then
    begin
      Result.Lat := NaN; // Return invalid point on failure to converge
      Result.Lon := NaN;
      Exit;
    end;
  until (Abs(sigma - sigmaP) < EPSILON);

  // Optimization: Reuse sinSigma and cosSigma from the loop ---
  phi2 := ArcTan2(sinU1 * cosSigma + cosU1 * sinSigma * cosAlpha1,
    ONE_MINUS_F * Sqrt(Sqr(sinAlpha) + Sqr(sinU1 * sinSigma - cosU1 * cosSigma * cosAlpha1)));

  lambda := ArcTan2(sinSigma * sinAlpha1,
    cosU1 * cosSigma - sinU1 * sinSigma * cosAlpha1);

  C := WGS84_F / 16 * cosSqAlpha * (4 + WGS84_F * (4 - 3 * cosSqAlpha));
  L := lambda - (1 - C) * WGS84_F * sinAlpha * (sigma + C * sinSigma *
    (cos2SigmaM + C * cosSigma * (-1 + 2 * Sqr(cos2SigmaM))));

  Result.Lat := RadToDeg(phi2);
  Result.Lon := RadToDeg(L1 + L);
end;


class function TOLCGeoCalc.CalculateInverse(const startPoint, endPoint: TOLCLatLon; out distance, startAzimuth,endAzimuth: Double): Boolean;
var
  phi1, L1, phi2, L2, L: Double;
  cosU1, sinU1, cosU2, sinU2: Double;
  lambda, lambdaP, sinLambda, cosLambda, sinSigma, cosSigma, sigma, sinAlpha, cosSqAlpha, cos2SigmaM, C: Double;
  iterLimit: Integer;
  uSq, A, B, deltaSigma, s: Double;
  alpha1, alpha2: Double;

  tan_phi1, tan_phi2, sq_term1, sq_term2: Double;
begin
  Result := False;
  distance := 0;
  startAzimuth := 0;
  endAzimuth := 0;

  if ( CompareValue(startPoint.Lat,endPoint.Lat, EPSILON) = EqualsValue ) and
     ( CompareValue(startPoint.Lon,endPoint.Lon, EPSILON) = EqualsValue ) then
  begin
    Result := True;
    Exit;
  end;

  phi1 := DegToRad(startPoint.Lat);
  L1 := DegToRad(startPoint.Lon);
  phi2 := DegToRad(endPoint.Lat);
  L2 := DegToRad(endPoint.Lon);

  L := L2 - L1;

  tan_phi1 := Tan(phi1);
  sinU1 := ONE_MINUS_F * tan_phi1;
  cosU1 := 1 / Sqrt(1 + Sqr(sinU1));
  sinU1 := sinU1 * cosU1;

  tan_phi2 := Tan(phi2);
  sinU2 := ONE_MINUS_F * tan_phi2;
  cosU2 := 1 / Sqrt(1 + Sqr(sinU2));
  sinU2 := sinU2 * cosU2;

  lambda := L;
  iterLimit := 100;

  repeat
    lambdaP := lambda; // Store previous lambda
    SinCos(lambda, sinLambda, cosLambda);

    sq_term1 := Sqr(cosU2 * sinLambda);
    sq_term2 := Sqr(cosU1 * sinU2 - sinU1 * cosU2 * cosLambda);

    sinSigma := Sqrt(sq_term1 + sq_term2);
    if sinSigma = 0 then
    begin
      Result := True; // Co-incident points
      Exit;
    end;
    cosSigma := sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
    sigma := ArcTan2(sinSigma, cosSigma);
    sinAlpha := cosU1 * cosU2 * sinLambda / sinSigma;
    cosSqAlpha := 1 - Sqr(sinAlpha);

    if cosSqAlpha <> 0 then
      cos2SigmaM := cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha
    else
      cos2SigmaM := 0; // On the equator

    C := WGS84_F / 16 * cosSqAlpha * (4 + WGS84_F * (4 - 3 * cosSqAlpha));
    lambda := L + (1 - C) * WGS84_F * sinAlpha * (sigma + C * sinSigma * (cos2SigmaM + C * cosSigma * (-1 + 2 * Sqr(cos2SigmaM))));

    Dec(iterLimit);
    if iterLimit = 0 then
      Exit; // Failed to converge
  until Abs(lambda - lambdaP) <= EPSILON;

  uSq := cosSqAlpha * (WGS84_A_SQ - WGS84_B_SQ) / WGS84_B_SQ;
  A := 1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)));
  B := uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)));
  deltaSigma := B * sinSigma * (cos2SigmaM + B / 4 * (cosSigma * (-1 + 2 * Sqr(cos2SigmaM)) -
    B / 6 * cos2SigmaM * (-3 + 4 * Sqr(sinSigma)) * (-3 + 4 * Sqr(cos2SigmaM))));

  s := WGS84_B * A * (sigma - deltaSigma);
  distance := s;

  alpha1 := ArcTan2(cosU2 * sinLambda, cosU1 * sinU2 - sinU1 * cosU2 * cosLambda);
  alpha2 := ArcTan2(cosU1 * sinLambda, -sinU1 * cosU2 + cosU1 * sinU2 * cosLambda);

  startAzimuth := RadToDeg(alpha1);
  if startAzimuth < 0 then
    startAzimuth := startAzimuth + 360;

  endAzimuth := RadToDeg(alpha2) + 180;
  if endAzimuth >= 360 then
    endAzimuth := endAzimuth - 360;

  Result := True;
end;
{$endregion}

end.
