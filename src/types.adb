with Ada.Text_IO;
with Ada.Characters.Handling; use Ada.Characters.Handling;
with Ada.Unchecked_Conversion;
with GNAT.SHA256; use GNAT.SHA256;

package body Types with SPARK_Mode is

   function Double_Hash (S : String) return Uint_256 is
      D : Binary_Message_Digest := Digest (S);
      T : String (1 .. 32);
      for T'Address use D'Address;
      D2 : constant Binary_Message_Digest := Digest (T);

      function To_Uint_256 is new Ada.Unchecked_Conversion
        (Source => Binary_Message_Digest,
         Target => Uint_256);
   begin
      return To_Uint_256 (D2);
   end Double_Hash;

   ---------------
   -- Same_Hash --
   ---------------

   function Same_Hash (S1, S2 : String) return Boolean is
   begin
      return To_Lower (S1) = To_Lower (S2);
   end Same_Hash;

   ---------------------
   -- Uint_8_from_Hex --
   ---------------------

   function Uint_8_from_Hex (S : String) return Uint_8 is
   begin
      return Uint_8'Value ("16#" & S & "#");
   end Uint_8_from_Hex;

   ----------------
   -- Uint_8_Hex --
   ----------------

   procedure Uint_8_Hex (S : out Two_Char; X : Uint_8) is
      package Unsigned_8_IO is new Ada.Text_IO.Modular_IO (Uint_8);

      Tmp : String (1 .. 6);
   begin
      Unsigned_8_IO.Put (To => Tmp, Item => X, Base => 16);
      if X < 16 then
         S := (1 => '0', 2 => Tmp (5));
      else
         S := Tmp (4 .. 5);
      end if;
   end Uint_8_Hex;

   ----------------------
   -- Uint_32_from_Hex --
   ----------------------

   function Uint_32_from_Hex (S : String) return Uint_32 is
   begin
      return Uint_32'Value
        ("16#" & S & "#");
   end Uint_32_from_Hex;

   -----------------
   -- Uint_32_Hex --
   -----------------

   function Uint_32_Hex (X : Uint_32) return String is
      package Unsigned_32_IO is new Ada.Text_IO.Modular_IO (Uint_32);

      Tmp : String (1 .. 12);
      Lead_Zeros : Natural := 0;
   begin
      Unsigned_32_IO.Put (To => Tmp, Item => X, Base => 16);
      -- count spaces at beginning of string to know how many 0 to add later
      for I in Tmp'Range loop
         exit when Tmp (I) /= ' ';
         Lead_Zeros := Lead_Zeros + 1;
      end loop;
      return String'(1 .. Lead_Zeros => '0') & Tmp (Lead_Zeros + 4 .. 11);
   end Uint_32_Hex;


   function Large_Number_From_Hex (S : String) return Large_Number is
      B : Large_Number (1 .. S'Length / 2);
   begin
      for I in B'Range loop
         B (I) := Uint_8_from_Hex (S (S'Last - 2 * (I -1) - 1 ..
                                      S'Last - 2 * (I - 1)));
      end loop;
      return B;
   end Large_Number_From_Hex;

   ----------------------
   -- Uint256_from_Hex --
   ----------------------

   function Uint256_from_Hex (S : String) return Uint_256 is
   begin
      return Large_Number_From_Hex (S);
   end Uint256_from_Hex;

   ----------------------
   -- Large_Number_Hex --
   ----------------------

   function Large_Number_Hex (U : Large_Number) return String is
      Result : String (1 ..U'Length * 2);
   begin
      for I in U'Range loop
         Uint_8_Hex (Result (U'Length * 2 - 2 * (I - 1) - 1 ..
                             U'Length * 2 - 2 * (I - 1)), U (I));
      end loop;
      return Result;
   end Large_Number_Hex;

   ------------------
   -- Uint_256_Hex --
   ------------------

   function Uint_256_Hex (U : Uint_256) return String is
   begin
      return Large_Number_Hex (U);
   end Uint_256_Hex;
end Types;
