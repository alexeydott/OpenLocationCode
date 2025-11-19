unit olc.tests;

interface

uses
  DUnitX.TestFramework,
  olc;

type
  TEncodingCase = record
    Code: string;
    Lat, Lng: Double;
    LatLo, LngLo, LatHi, LngHi: Double;
  end;

  TValidityCase = record
    Code: string;
    IsValid, IsShort, IsFull: Boolean;
  end;

  TShortCodeCase = record
    FullCode, ShortCode: string;
    RefLat, RefLng: Double;
  end;

  [TestFixture]
  TOpenLocationCodeEncodingTests = class
  strict private
    const ENCODING_EPS = 1e-11;
  public
    [Test]
    procedure Encode_Matches_Reference_Codes;

    [Test]
    procedure Decode_Matches_Reference_Bounds;
  end;

  [TestFixture]
  TOpenLocationCodeValidityTests = class
  public
    [Test]
    procedure Validity_Matches_Reference_Flags;
  end;

  [TestFixture]
  TOpenLocationCodeShortCodeTests = class
  public
    [Test]
    procedure Shorten_Matches_Reference_ShortCodes;

    [Test]
    procedure RecoverNearest_Matches_Reference_FullCodes;

    [Test]
    procedure RecoverNearest_Poles;
  end;

implementation

{
  - encodingTests: code, lat, lng, latLo, lngLo, latHi, lngHi
  - validityTests: code, isValid, isShort, isFull
  - shortCodeTests: fullCode, shortCode, refLat, refLng
}

uses
  SysUtils
;

const
  // encoding/decoding tests
  ENCODING_CASES: array[0..14] of TEncodingCase = (
    // 0
    (Code: '7FG49Q00+';   Lat: 20.375;      Lng: 2.775;
     LatLo: 20.35;        LngLo: 2.75;      LatHi: 20.4;        LngHi: 2.8),
    // 1
    (Code: '7FG49QCJ+2V'; Lat: 20.3700625;  Lng: 2.7821875;
     LatLo: 20.37;        LngLo: 2.782125;  LatHi: 20.370125;   LngHi: 2.78225),
    // 2
    (Code: '7FG49QCJ+2VX'; Lat: 20.3701125; Lng: 2.782234375;
     LatLo: 20.3701;      LngLo: 2.78221875; LatHi: 20.370125;  LngHi: 2.78225),
    // 3
    (Code: '7FG49QCJ+2VXGJ'; Lat: 20.3701135; Lng: 2.78223535156;
     LatLo: 20.370113;     LngLo: 2.782234375; LatHi: 20.370114; LngHi: 2.78223632813),
    // 4
    (Code: '8FVC2222+22'; Lat: 47.0000625;  Lng: 8.0000625;
     LatLo: 47.0;         LngLo: 8.0;       LatHi: 47.000125;   LngHi: 8.000125),
    // 5
    (Code: '4VCPPQGP+Q9'; Lat: -41.2730625; Lng: 174.7859375;
     LatLo: -41.273125;   LngLo: 174.785875; LatHi: -41.273;    LngHi: 174.786),
    // 6
    (Code: '62G20000+';   Lat: 0.5;         Lng: -179.5;
     LatLo: 0.0;          LngLo: -180.0;    LatHi: 1.0;         LngHi: -179.0),
    // 7
    (Code: '22220000+';   Lat: -89.5;       Lng: -179.5;
     LatLo: -90.0;        LngLo: -180.0;    LatHi: -89.0;       LngHi: -179.0),
    // 8
    (Code: '7FG40000+';   Lat: 20.5;        Lng: 2.5;
     LatLo: 20.0;         LngLo: 2.0;       LatHi: 21.0;        LngHi: 3.0),
    // 9
    (Code: '22222222+22'; Lat: -89.9999375; Lng: -179.9999375;
     LatLo: -90.0;        LngLo: -180.0;    LatHi: -89.999875;  LngHi: -179.999875),
    // 10
    (Code: '6VGX0000+';   Lat: 0.5;         Lng: 179.5;
     LatLo: 0.0;          LngLo: 179.0;     LatHi: 1.0;         LngHi: 180.0),
    // 11
    (Code: 'CFX30000+';   Lat: 90.0;        Lng: 1.0;
     LatLo: 89.0;         LngLo: 1.0;       LatHi: 90.0;        LngHi: 2.0),
    // 12 (lat/lng out of range, same code, checking, clipping)
    (Code: 'CFX30000+';   Lat: 92.0;        Lng: 1.0;
     LatLo: 89.0;         LngLo: 1.0;       LatHi: 90.0;        LngHi: 2.0),
    // 13 (lng 180 / -180)
    (Code: '62H20000+';   Lat: 1.0;         Lng: 180.0;
     LatLo: 1.0;          LngLo: -180.0;    LatHi: 2.0;         LngHi: -179.0),
    // 14 (lng out of 180)
    (Code: '62H30000+';   Lat: 1.0;         Lng: 181.0;
     LatLo: 1.0;          LngLo: -179.0;    LatHi: 2.0;         LngHi: -178.0)
  );

  // validity codes
  VALIDITY_CASES: array[0..16] of TValidityCase = (
    (Code: '8fwc2345+G6';   IsValid: True;  IsShort: False; IsFull: True),
    (Code: '8FWC2345+G6G'; IsValid: True;  IsShort: False; IsFull: True),
    (Code: '8fwc2345+';    IsValid: True;  IsShort: False; IsFull: True),
    (Code: '8FWCX400+';    IsValid: True;  IsShort: False; IsFull: True),
    (Code: 'WC2345+G6g';   IsValid: True;  IsShort: True;  IsFull: False),
    (Code: '2345+G6';      IsValid: True;  IsShort: True;  IsFull: False),
    (Code: '45+G6';        IsValid: True;  IsShort: True;  IsFull: False),
    (Code: '+G6';          IsValid: True;  IsShort: True;  IsFull: False),
    (Code: 'G+';           IsValid: False; IsShort: False; IsFull: False),
    (Code: '+';            IsValid: False; IsShort: False; IsFull: False),
    (Code: '8FWC2345+G';   IsValid: False; IsShort: False; IsFull: False),
    (Code: '8FWC2_45+G6';  IsValid: False; IsShort: False; IsFull: False),
    (Code: '8FWC2η45+G6';  IsValid: False; IsShort: False; IsFull: False),
    (Code: '8FWC2345+G6+'; IsValid: False; IsShort: False; IsFull: False),
    (Code: '8FWC2300+G6';  IsValid: False; IsShort: False; IsFull: False),
    (Code: 'WC2300+G6g';   IsValid: False; IsShort: False; IsFull: False),
    (Code: 'WC2345+G';     IsValid: False; IsShort: False; IsFull: False)
  );

  // tests for shortened codes and recovery
  SHORTCODE_CASES: array[0..10] of TShortCodeCase = (
    (FullCode: '9C3W9QCJ+2VX'; ShortCode: '+2VX';     RefLat: 51.3701125; RefLng: -1.217765625),
    (FullCode: '9C3W9QCJ+2VX'; ShortCode: 'CJ+2VX';   RefLat: 51.3708675; RefLng: -1.217765625),
    (FullCode: '9C3W9QCJ+2VX'; ShortCode: 'CJ+2VX';   RefLat: 51.3693575; RefLng: -1.217765625),
    (FullCode: '9C3W9QCJ+2VX'; ShortCode: 'CJ+2VX';   RefLat: 51.3701125; RefLng: -1.218520625),
    (FullCode: '9C3W9QCJ+2VX'; ShortCode: 'CJ+2VX';   RefLat: 51.3701125; RefLng: -1.217010625),
    (FullCode: '9C3W9QCJ+2VX'; ShortCode: '9QCJ+2VX'; RefLat: 51.3852125; RefLng: -1.217765625),
    (FullCode: '9C3W9QCJ+2VX'; ShortCode: '9QCJ+2VX'; RefLat: 51.3550125; RefLng: -1.217765625),
    (FullCode: '9C3W9QCJ+2VX'; ShortCode: '9QCJ+2VX'; RefLat: 51.3701125; RefLng: -1.232865625),
    (FullCode: '9C3W9QCJ+2VX'; ShortCode: '9QCJ+2VX'; RefLat: 51.3701125; RefLng: -1.202665625),
    (FullCode: '8FJFW222+';   ShortCode: '22+';       RefLat: 42.899;     RefLng: 9.012),
    (FullCode: '796RXG22+';   ShortCode: '22+';       RefLat: 14.95125;   RefLng: -23.5001)
  );

{ TOpenLocationCodeEncodingTests }

procedure TOpenLocationCodeEncodingTests.Encode_Matches_Reference_Codes;
var
  i: Integer;
  C: TEncodingCase;
  code: string;
  codeLen: Integer;
begin
  for i := Low(ENCODING_CASES) to High(ENCODING_CASES) do
  begin
    C := ENCODING_CASES[i];

    codeLen := TOLC.CodeLength(C.Code);

    TOLC.Encode(TOLCLatLon.Create(C.Lat, C.Lng), codeLen, code);
    code := UpperCase(code);

    Assert.AreEqual(UpperCase(C.Code), code,
      Format('Encode case %d failed: expected %s, got %s, codeLen was %d',
        [i, C.Code, code, codeLen]));
  end;
end;

procedure TOpenLocationCodeEncodingTests.Decode_Matches_Reference_Bounds;
var
  i: Integer;
  C: TEncodingCase;
  area: TOLCCodeArea;
begin
  for i := Low(ENCODING_CASES) to High(ENCODING_CASES) do
  begin
    C := ENCODING_CASES[i];

    TOLC.Decode(C.Code,area);

    Assert.IsTrue(Abs(area.SouthLatitude - C.LatLo) <= ENCODING_EPS,
      Format('Decode case %d SouthLatitude: expected %.15f, got %.15f',
        [i, C.LatLo, area.SouthLatitude]));
    Assert.IsTrue(Abs(area.WestLongitude - C.LngLo) <= ENCODING_EPS,
      Format('Decode case %d WestLongitude: expected %.15f, got %.15f',
        [i, C.LngLo, area.WestLongitude]));
    Assert.IsTrue(Abs(area.NorthLatitude - C.LatHi) <= ENCODING_EPS,
      Format('Decode case %d NorthLatitude: expected %.15f, got %.15f',
        [i, C.LatHi, area.NorthLatitude]));
    Assert.IsTrue(Abs(area.EastLongitude - C.LngHi) <= ENCODING_EPS,
      Format('Decode case %d EastLongitude: expected %.15f, got %.15f',
        [i, C.LngHi, area.EastLongitude]));
  end;
end;

{ TOpenLocationCodeValidityTests }

procedure TOpenLocationCodeValidityTests.Validity_Matches_Reference_Flags;
var
  i: Integer;
  C: TValidityCase;
  v, s, f: Boolean;
begin
  for i := Low(VALIDITY_CASES) to High(VALIDITY_CASES) do
  begin
    C := VALIDITY_CASES[i];

    v := TOLC.IsValid(C.Code);
    s := TOLC.IsShort(C.Code);
    f := TOLC.IsFull(C.Code);

    Assert.AreEqual(C.IsValid, v,
      Format('Validity case %d IsValid for "%s": expected %s, got %s',
        [i, C.Code, BoolToStr(C.IsValid, True), BoolToStr(v, True)]));
    Assert.AreEqual(C.IsShort, s,
      Format('Validity case %d IsShort for "%s": expected %s, got %s',
        [i, C.Code, BoolToStr(C.IsShort, True), BoolToStr(s, True)]));
    Assert.AreEqual(C.IsFull, f,
      Format('Validity case %d IsFull for "%s": expected %s, got %s',
        [i, C.Code, BoolToStr(C.IsFull, True), BoolToStr(f, True)]));
  end;
end;

{ TOpenLocationCodeShortCodeTests }

procedure TOpenLocationCodeShortCodeTests.Shorten_Matches_Reference_ShortCodes;
var
  i: Integer;
  C: TShortCodeCase;
  shortCode: string;
begin
  for i := Low(SHORTCODE_CASES) to High(SHORTCODE_CASES) do
  begin
    C := SHORTCODE_CASES[i];

    TOLC.Shorten(C.FullCode, TOLCLatLon.Create(C.RefLat, C.RefLng), shortCode);

    Assert.AreEqual(UpperCase(C.ShortCode), UpperCase(shortCode),
      Format('Shorten case %d: expected "%s", got "%s"',
        [i, C.ShortCode, shortCode]));
  end;
end;

procedure TOpenLocationCodeShortCodeTests.RecoverNearest_Matches_Reference_FullCodes;
var
  i: Integer;
  C: TShortCodeCase;
  fullCode: string;
begin
  for i := Low(SHORTCODE_CASES) to High(SHORTCODE_CASES) do
  begin
    C := SHORTCODE_CASES[i];

    TOLC.RecoverNearest(C.ShortCode, TOLCLatLon.Create(C.RefLat, C.RefLng),fullCode);

    Assert.AreEqual(UpperCase(C.FullCode), UpperCase(fullCode),
      Format('Recover case %d: expected "%s", got "%s"',
        [i, C.FullCode, fullCode]));
  end;
end;

procedure TOpenLocationCodeShortCodeTests.RecoverNearest_Poles;
var
  fullCode: string;
begin
  // North pole recovery: "2222+22" @ 89.6, 0.0 -> "CFX22222+22"
  TOLC.RecoverNearest('2222+22',TOLCLatLon.Create(89.6, 0.0),fullCode);
  Assert.AreEqual('CFX22222+22', UpperCase(fullCode),
    Format('North pole recovery: expected "%s", got "%s"',
      ['CFX22222+22', fullCode]));

  // South pole recovery: "XXXXXX+XX" @ -81.0, 0.0 -> "2CXXXXXX+XX"
  TOLC.RecoverNearest('XXXXXX+XX', TOLCLatLon.Create(-81.0, 0.0),fullCode);
  Assert.AreEqual('2CXXXXXX+XX', UpperCase(fullCode),
    Format('South pole recovery: expected "%s", got "%s"',
      ['2CXXXXXX+XX', fullCode]));
end;

initialization
  TDUnitX.RegisterTestFixture(TOpenLocationCodeEncodingTests);
  TDUnitX.RegisterTestFixture(TOpenLocationCodeValidityTests);
  TDUnitX.RegisterTestFixture(TOpenLocationCodeShortCodeTests);

end.

